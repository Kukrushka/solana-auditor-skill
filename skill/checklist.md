# Solana Security Audit Checklist

> Run this checklist on every program before mainnet deployment.
> Each item links to [vulnerabilities.md](vulnerabilities.md) for patterns and examples.

---

## 1. Account Validation

### 1.1 Signer Checks

- [ ] Every privileged instruction checks that the authority account **is a signer** (`is_signer`)
- [ ] Instructions that transfer funds or update critical state require at least one signer
- [ ] No instruction accepts an unsigned account as an authority
- [ ] Anchor: `#[account(signer)]` or `Signer<'info>` used where required
- [ ] PDA signers use `invoke_signed` with correct seeds; seeds are verified before use

### 1.2 Owner / Program Checks

- [ ] Every account passed to the program is **owned by the expected program** (`account.owner == expected_program_id`)
- [ ] Anchor: `#[account]` constraint automatically checks discriminator + owner; verify it is not bypassed with `UncheckedAccount` / `AccountInfo`
- [ ] System accounts (rent, clock, token_program) are checked against hard-coded pubkeys
- [ ] Token accounts are owned by `spl_token::ID` or `spl_token_2022::ID` as appropriate
- [ ] If `UncheckedAccount` is used, a manual `//SAFETY:` comment explains why it is safe

### 1.3 PDA Validation

- [ ] PDA derivation seeds are **verified on-chain**, not just passed in by the client
- [ ] Canonical bump is stored in PDA account data and used on every re-derivation (`find_program_address` → store bump → `create_program_address` with stored bump)
- [ ] No two different PDAs can be derived with the same seed set in the same program
- [ ] PDAs that hold funds are not shareable across users/namespaces without explicit isolation
- [ ] Seeds do not include mutable user-controlled data without additional uniqueness constraints

### 1.4 Account Discriminator

- [ ] Anchor programs: discriminators are checked automatically; confirm no manual `unsafe` deserialization bypasses this
- [ ] Native programs: first 8 bytes of account data used to distinguish account types
- [ ] No two account types share an identical layout that would allow substitution
- [ ] `AccountLoader` used for zero-copy accounts; verify alignment requirements

### 1.5 Initialization

- [ ] `init` constraint (Anchor) or manual `is_initialized` flag prevents re-initialization
- [ ] No instruction can overwrite an already-initialized account's data silently
- [ ] Initialization is **not front-runnable**: the account's address is derived from user-specific seeds, not predictable before the transaction
- [ ] Initial state is fully set — no zero-value defaults that create exploitable states

### 1.6 Account Reloading After CPI

- [ ] After any CPI call, accounts that may have been modified are **reloaded** (`account.reload()?`)
- [ ] Cached balances / amounts are re-read after CPI, not reused from before the call

---

## 2. Cross-Program Invocation (CPI) Security

### 2.1 Arbitrary CPI

- [ ] The program ID of the callee is **checked against a known constant or stored trusted address** before invoking
- [ ] `invoke` / `invoke_signed` never called with a program ID derived purely from user input without validation
- [ ] Token program invocations check that the token program account is `spl_token::ID` or `spl_token_2022::ID`

### 2.2 Sysvar Spoofing

- [ ] Sysvars (Clock, Rent, SlotHashes, etc.) obtained via `Sysvar::get()` or from `sysvar::*` address constants — not accepted as arbitrary `AccountInfo`
- [ ] Anchor `Sysvar<'info, Clock>` used instead of manual deserialization

### 2.3 Reentrancy

- [ ] State updates that change balances or critical flags occur **before** any CPI call that transfers funds
- [ ] Checks-Effects-Interactions pattern followed (update state, then call external)
- [ ] If a CPI call can invoke back into this program, the re-entrant path is analyzed for safety

### 2.4 Privilege Escalation via CPI

- [ ] PDA signing seeds used in `invoke_signed` are **constructed on-chain**, never accepted from the client
- [ ] The set of accounts forwarded to a CPI does not include accounts with higher privilege than necessary

---

## 3. Math and Arithmetic

### 3.1 Overflow / Underflow

- [ ] All arithmetic on `u64`, `u128`, `i64` uses `checked_*` methods (`checked_add`, `checked_sub`, `checked_mul`, `checked_div`) or `saturating_*` where appropriate
- [ ] No unchecked `+`, `-`, `*` on token amounts, prices, or balances (use `overflow-checks = true` in `Cargo.toml` for release builds)
- [ ] `overflow-checks = true` set in `[profile.release]` of `Cargo.toml`

### 3.2 Division and Precision

- [ ] Division operations check for zero divisor before dividing
- [ ] Rounding direction is intentional: fees rounded **up** for protocol, amounts distributed rounded **down** for users (never in favor of an attacker)
- [ ] Fixed-point math uses consistent precision (e.g. 6 decimals for USDC, 9 for SOL); precision is never silently truncated
- [ ] Intermediate multiplication happens **before** division to avoid precision loss (`a * b / c`, not `a / c * b`)

### 3.3 Signed vs Unsigned Confusion

- [ ] No implicit cast between `i64` and `u64` that could wrap or produce unexpected negative values
- [ ] Time-based calculations use `i64` (Unix timestamps can be negative in tests); comparisons account for this

### 3.4 Price Oracle Manipulation

- [ ] Price feeds from Pyth / Switchboard are validated: confidence interval checked, publish time checked against staleness threshold
- [ ] No single-block price manipulation possible (TWAP used for critical decisions)
- [ ] Slippage and price impact limits enforced in AMM swap instructions

---

## 4. Access Control

### 4.1 Authority Patterns

- [ ] Each instruction documents its required authority (user, admin, protocol, DAO)
- [ ] Admin authority stored in a program-owned config account, not hard-coded (allows governance upgrade)
- [ ] Authority update instructions require both old and new authority to sign (two-party handoff)
- [ ] No instruction bypasses authority checks based on a simple boolean flag

### 4.2 Multisig and Governance

- [ ] Critical admin operations (upgrade, pause, drain treasury) require multisig or timelock
- [ ] On-chain timelock enforced in program logic, not just off-chain tooling
- [ ] Squads or SPL Governance used for protocol admin; program verifies the multisig account owner

### 4.3 Upgradability

- [ ] Program upgrade authority is either burned (immutable) or held by a multisig
- [ ] If upgradeable, all users are informed of upgrade authority via docs
- [ ] State migration logic in upgrade is separately audited

---

## 5. Token and SPL Integration

### 5.1 Token Account Validation

- [ ] Token account mint matches the expected mint stored in program state
- [ ] Token account owner matches the expected owner (user PDA, protocol vault, etc.)
- [ ] Token account is not frozen (check `account.state != Frozen` for Token 2022)
- [ ] Token 2022 extensions (transfer fees, permanent delegate, non-transferable) are handled if the mint uses them

### 5.2 Vault and Escrow

- [ ] Vault accounts are PDAs owned by the program — no external account can drain them unilaterally
- [ ] Vault withdrawals verify caller authority before transferring
- [ ] Deposit and withdrawal amounts are logged as events for off-chain monitoring

### 5.3 Native SOL Handling

- [ ] Lamport arithmetic uses `checked_add` / `checked_sub`
- [ ] System program `transfer` CPI used for SOL transfers — never `**ctx.accounts.user.try_borrow_mut_lamports()? -= amount` without careful ordering

---

## 6. State Machine and Logic

### 6.1 State Transitions

- [ ] Every instruction documents its valid pre-state and post-state
- [ ] Invalid state transitions return a custom error, not silently no-op
- [ ] State can only move forward (no regression to an earlier state without explicit admin reset)

### 6.2 Deadline and Time Checks

- [ ] Time-based deadlines use on-chain `Clock::get()?.unix_timestamp`, not client-supplied timestamps
- [ ] Auctions, vesting schedules, and lockups enforce deadlines in program logic
- [ ] Clock manipulation in tests does not indicate the production code is wrong

### 6.3 Denial of Service

- [ ] No instruction can be blocked by an attacker creating a conflicting account
- [ ] Instruction compute budget is bounded — no unbounded loops over user-supplied arrays
- [ ] Large account lists do not cause stack overflow (use `Box<>` for large structs)

### 6.4 Front-Running

- [ ] Commit-reveal scheme used for auctions or randomness-dependent outcomes
- [ ] Slippage protection (`minimum_amount_out`) enforced in swap instructions
- [ ] MEV analysis performed for high-value instructions

---

## 7. Anchor-Specific

- [ ] All `#[account(...)]` constraints are reviewed — especially `has_one`, `constraint =`, `seeds`, `bump`
- [ ] `close = target` used when closing accounts; `to` receives rent; discriminator zeroed
- [ ] `realloc` instructions check new size bounds and zero-initialize new bytes when `realloc::zero = true`
- [ ] `remaining_accounts` usage is explicitly validated — no blind iteration
- [ ] `emit!` event fields do not leak sensitive data
- [ ] IDL is re-generated after any instruction change and committed to repo

---

## 8. Rust and Cargo

- [ ] `cargo audit` passes with no known vulnerabilities in dependencies
- [ ] `cargo deny` configured to block licenses incompatible with project license
- [ ] No `unsafe` blocks outside of explicitly reviewed zero-copy patterns
- [ ] `#[allow(unused_*)]` attributes removed before audit
- [ ] `unwrap()` / `expect()` replaced with `?` propagation or explicit error handling in all instruction handlers

---

## 9. Off-Chain and Client Security

- [ ] RPC endpoints use authenticated connections (no public RPC for production signing)
- [ ] Private keys never logged, never sent to external services
- [ ] Transaction simulation used before signing on client side
- [ ] Retry logic handles `BlockhashNotFound` without replaying stale transactions

---

## Severity Quick-Reference

| Finding Type | Default Severity |
|---|---|
| Missing signer check on fund transfer | Critical |
| Arbitrary CPI to user-supplied program | Critical |
| Integer overflow on token amount | Critical |
| Missing owner check | High |
| PDA substitution possible | High |
| Missing account reload after CPI | High |
| Division by zero | High |
| Rounding direction favors attacker | Medium |
| Missing staleness check on oracle | Medium |
| No multisig on admin | Medium |
| Missing `overflow-checks` in Cargo.toml | Low |
| Unbounded vector iteration | Low |
| Missing event emission | Informational |
| Unused code / dead branches | Informational |
