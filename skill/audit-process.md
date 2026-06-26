# Audit Methodology and Process

> How professional Solana audits are structured — from scoping to final report.

---

## Phase 1: Scoping

Before writing a single line of audit notes, define the boundary of the engagement.

### Scope Definition Checklist

- [ ] List every program to be audited (program ID + source path)
- [ ] List excluded programs and why
- [ ] Identify the exact git commit hash to audit (not a branch that can change)
- [ ] Agree on out-of-scope items: off-chain infrastructure, frontend, key management, economics
- [ ] Define the trust model: who are the trusted actors?

### Trust Model Template

```
Trusted:   Protocol admin (multisig), Anchor framework, Solana runtime
Untrusted: Any wallet / EOA, RPC responses, oracle feeds (verify independently), CPI callees
Partially: DAO governance (trusted for votes, not for instant action without timelock)
```

### Estimating Scope Size

| Lines of Rust (nSLOC) | Typical effort |
|---|---|
| < 500 | 1-2 days |
| 500 – 2,000 | 3-5 days |
| 2,000 – 5,000 | 1-2 weeks |
| > 5,000 | 2-4 weeks |

---

## Phase 2: Architecture Review

Before reading instructions line by line, build a mental model of the whole system.

### Questions to Answer

1. **What does the protocol do?** One sentence.
2. **Where is value stored?** List all PDAs and token accounts that hold SOL or SPL tokens.
3. **Who can move value?** List all instructions that transfer funds.
4. **What are the trust boundaries?** Which actors are trusted, which are not?
5. **What external programs are called?** Token program, oracle, DeFi protocols.
6. **Is the program upgradeable?** Who holds upgrade authority?

### Account Relationship Diagram

Draw (or describe) how accounts relate:

```
User Wallet
    │
    ├── [deposit]──► UserPosition PDA (seeds: ["pos", user, mint])
    │                    │ has_one: vault
    │                    ▼
    └── [withdraw]◄── Vault PDA (seeds: ["vault", mint])
                          │ has_one: vault_token_account
                          ▼
                     TokenAccount (owned by vault PDA)
```

---

## Phase 3: Instruction-by-Instruction Review

Work through each instruction in `programs/*/src/instructions/`.

### Review Template (per instruction)

```
Instruction: withdraw()
Location: programs/lending/src/instructions/withdraw.rs

Accounts:
  [mut] vault          — Vault PDA, seeds verified? ✅
  [signer] authority   — Signer<'info>? ✅
  [mut] user_token     — mint check? ✅  owner check? ✅
  token_program        — Program<'info, Token>? ✅

Logic:
  1. Checks vault.authority == authority.key() ✅
  2. Checks vault.balance >= amount ✅
  3. Updates vault.balance (overflow-safe?) ⚠️ need to verify
  4. Transfers tokens via CPI ✅

Findings:
  - Line 42: amount subtraction not checked — POTENTIAL OVERFLOW
```

---

## Phase 4: Automated Scanning

After manual review, run automated tools to catch what eyes miss.

See [tools.md](tools.md) for full setup.

**Minimum automated checks:**

```bash
# 1. Supply chain
cargo audit
cargo deny check

# 2. Static analysis
soteria -analyzeAll .

# 3. Overflow check
grep -r "overflow-checks" Cargo.toml
# Must see: overflow-checks = true in [profile.release]

# 4. Unsafe blocks
grep -rn "unsafe {" programs/
# Review each unsafe block manually

# 5. Fuzz (at minimum 60 minutes per instruction set)
trident fuzz run-hfuzz fuzz_0 -- -max_total_time=3600
```

---

## Phase 5: Finding Classification

For each potential finding:

1. **Confirm exploitability** — Can you write a PoC that actually triggers the bug?
2. **Assess impact** — What is the worst-case outcome?
3. **Assess likelihood** — How easy is it for an attacker to trigger this?
4. **Classify severity** — Use the risk matrix in [report.md](report.md)

### Severity Escalation Rules

- **Upgrade to Critical**: if the bug requires no special access and leads to fund loss
- **Downgrade to Medium**: if the bug requires admin cooperation to exploit
- **Downgrade to Informational**: if PoC cannot be constructed after two attempts

---

## Phase 6: Remediation Review

After the team fixes findings:

1. Review the diff — does the fix address the root cause or just the symptom?
2. Check if the fix introduces new bugs (regression)
3. Re-run automated tools on the patched code
4. Update finding status in the report

### Common Fix Anti-Patterns

| Bad Fix | Problem |
|---|---|
| Add `require!(amount < MAX)` | Doesn't fix overflow, just caps it — root cause is unchecked math |
| Comment out the vulnerable line | Disables functionality |
| Add access control without fixing the bug | Bug still exploitable by the admin |
| Change error message | Zero security impact |

---

## Phase 7: Report Generation

Use the template in [report.md](report.md) and the `/gen-report` command.

**Final checklist before delivering report:**

- [ ] Every finding ≥ Medium has a working PoC
- [ ] Every finding has a concrete remediation recommendation with code
- [ ] Severities have been reviewed against the risk matrix
- [ ] Executive summary is understandable by a non-technical founder
- [ ] All findings have a status (Open / Resolved / Acknowledged)
- [ ] Report is spell-checked and grammar-reviewed

---

## Continuous Security

Audits are point-in-time. For ongoing security:

1. **Re-audit after major changes** — Any new instruction or changed account layout
2. **CI security pipeline** — Run `cargo audit`, `soteria`, and security tests on every PR
3. **Bug bounty** — Immunefi or similar for community disclosure
4. **On-chain monitoring** — Alert on unusual transaction patterns via Helius webhooks

```
Helius webhook example — alert on unexpected withdraw amounts:
POST /api/webhooks/helius
{
  "webhookType": "enhanced",
  "accountAddresses": ["<vault_pda>"],
  "transactionTypes": ["TRANSFER"],
  "webhookURL": "https://your-alert-endpoint.com"
}
```
