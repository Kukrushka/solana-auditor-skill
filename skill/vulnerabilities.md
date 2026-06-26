# Solana Vulnerability Patterns

> Canonical patterns with vulnerable code, safe code, and real-world examples.
> Each pattern maps to a checklist item in [checklist.md](checklist.md).

---

## 1. Missing Signer Check

**Severity**: Critical  
**Real exploit**: Wormhole ($320M, Feb 2022) — `verify_signatures` instruction accepted a `guardian_set` account without verifying the caller signed the transaction. An attacker created a fake guardian set and minted 120,000 wETH.

### Vulnerable

```rust
pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
    // BUG: authority account is not checked as signer
    // Anyone can pass any pubkey as authority
    let vault = &mut ctx.accounts.vault;
    require!(vault.authority == ctx.accounts.authority.key(), VaultError::Unauthorized);

    transfer_lamports(vault, ctx.accounts.recipient.to_account_info(), amount)?;
    Ok(())
}

#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(mut)]
    pub vault: Account<'info, Vault>,
    /// CHECK: manually checked below -- BUG: only key checked, not is_signer
    pub authority: AccountInfo<'info>,
    #[account(mut)]
    pub recipient: SystemAccount<'info>,
}
```

### Safe

```rust
#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(mut, has_one = authority)]
    pub vault: Account<'info, Vault>,
    pub authority: Signer<'info>,           // Anchor enforces is_signer = true
    #[account(mut)]
    pub recipient: SystemAccount<'info>,
}
```

---

## 2. Missing Owner Check

**Severity**: High  
**Real exploit**: Cashio ($52M, Mar 2022) — An attacker passed an attacker-controlled account where the protocol expected a USDC account owned by the SPL Token program. The protocol trusted the account layout without checking ownership.

### Vulnerable

```rust
pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
    let token_account: TokenAccount = TokenAccount::try_deserialize(
        &mut &ctx.accounts.user_token.data.borrow()[..],
    )?;
    // BUG: deserialized successfully but owner not checked
    // Attacker can craft an account with the same layout
    require!(token_account.mint == ctx.accounts.vault.mint, ErrorCode::WrongMint);
    // ... proceed with deposit
    Ok(())
}
```

### Safe (Anchor)

```rust
#[derive(Accounts)]
pub struct Deposit<'info> {
    // Anchor checks: owner == spl_token::ID, discriminator matches TokenAccount
    #[account(
        mut,
        constraint = user_token.mint == vault.mint @ ErrorCode::WrongMint,
        constraint = user_token.owner == user.key() @ ErrorCode::WrongOwner,
    )]
    pub user_token: Account<'info, TokenAccount>,
    pub vault: Account<'info, Vault>,
    pub user: Signer<'info>,
    pub token_program: Program<'info, Token>,
}
```

---

## 3. Arbitrary CPI

**Severity**: Critical

An attacker passes a malicious program as the "token_program" or any other program account. The victim program invokes it, executing attacker-controlled code with the victim's PDA signing authority.

### Vulnerable

```rust
pub fn swap(ctx: Context<Swap>, amount_in: u64) -> Result<()> {
    // BUG: token_program is not validated — attacker passes their own program
    token::transfer(
        CpiContext::new(
            ctx.accounts.token_program.to_account_info(),  // untrusted
            token::Transfer { ... },
        ),
        amount_in,
    )?;
    Ok(())
}

#[derive(Accounts)]
pub struct Swap<'info> {
    /// CHECK: not checked!
    pub token_program: AccountInfo<'info>,   // BUG
}
```

### Safe

```rust
#[derive(Accounts)]
pub struct Swap<'info> {
    // Anchor verifies the account key == spl_token::ID
    pub token_program: Program<'info, Token>,
}
```

For Token-2022 programs that accept both token programs:

```rust
pub token_program: Interface<'info, TokenInterface>,
```

---

## 4. Missing Account Reload After CPI

**Severity**: High

After a CPI modifies an account's lamports or data, the in-memory `Account<'info, T>` struct holds **stale data**. Reading it without reloading leads to logic errors.

### Vulnerable

```rust
pub fn harvest_and_compound(ctx: Context<HarvestAndCompound>) -> Result<()> {
    let balance_before = ctx.accounts.vault.total_deposited;

    // CPI: harvest rewards — modifies vault.total_deposited on-chain
    harvest_rewards(CpiContext::new(...), &ctx.accounts)?;

    // BUG: balance_before and ctx.accounts.vault are stale
    // The calculation below uses pre-CPI values
    let rewards = ctx.accounts.vault.total_deposited - balance_before;  // always 0!
    Ok(())
}
```

### Safe

```rust
pub fn harvest_and_compound(ctx: Context<HarvestAndCompound>) -> Result<()> {
    let balance_before = ctx.accounts.vault.total_deposited;

    harvest_rewards(CpiContext::new(...), &ctx.accounts)?;

    // Reload account data from on-chain state
    ctx.accounts.vault.reload()?;

    let rewards = ctx.accounts.vault.total_deposited - balance_before;
    Ok(())
}
```

---

## 5. PDA Seed Collision / Substitution

**Severity**: High

If PDA seeds are not sufficiently unique, an attacker may derive a valid PDA for a different context.

### Vulnerable

```rust
// BUG: seeds only use user pubkey — the same PDA is valid for ANY mint
let (pda, bump) = Pubkey::find_program_address(
    &[b"user-vault", user.key().as_ref()],
    program_id,
);
```

### Safe

```rust
// Seeds include user AND mint — unique per (user, mint) pair
let (pda, bump) = Pubkey::find_program_address(
    &[b"user-vault", user.key().as_ref(), mint.key().as_ref()],
    program_id,
);
```

**Canonical bump pattern** — always store the bump and use it instead of calling `find_program_address` repeatedly:

```rust
#[account]
pub struct UserVault {
    pub user: Pubkey,
    pub mint: Pubkey,
    pub bump: u8,       // stored at init time
    pub balance: u64,
}

// At init:
vault.bump = ctx.bumps.vault;

// In subsequent instructions:
#[derive(Accounts)]
pub struct Withdraw<'info> {
    #[account(
        mut,
        seeds = [b"user-vault", user.key().as_ref(), mint.key().as_ref()],
        bump = vault.bump,   // uses stored canonical bump
    )]
    pub vault: Account<'info, UserVault>,
}
```

---

## 6. Integer Overflow on Token Amounts

**Severity**: Critical  
**Pattern**: Multiplying user-supplied amounts before bounds checking.

### Vulnerable

```rust
pub fn calculate_fee(amount: u64, fee_bps: u64) -> u64 {
    amount * fee_bps / 10_000   // BUG: overflows if amount is large
}
```

### Safe

```rust
pub fn calculate_fee(amount: u64, fee_bps: u64) -> Result<u64> {
    let fee = (amount as u128)
        .checked_mul(fee_bps as u128)
        .ok_or(ErrorCode::MathOverflow)?
        .checked_div(10_000)
        .ok_or(ErrorCode::MathOverflow)? as u64;
    Ok(fee)
}
```

**`Cargo.toml` for release builds:**

```toml
[profile.release]
overflow-checks = true    # panics on overflow in release; pair with checked math
```

---

## 7. Rounding Direction Favoring Attacker

**Severity**: Medium  
**Pattern**: Incorrect rounding lets an attacker extract value dust repeatedly.

### Vulnerable

```rust
// BUG: rounds DOWN for withdrawal — attacker receives more than deposited
pub fn calculate_withdrawal(shares: u64, total_assets: u64, total_shares: u64) -> u64 {
    shares * total_assets / total_shares   // truncates toward zero = rounds down
}
```

### Safe — round in protocol's favor

```rust
// Deposits: round UP the number of shares required (user gets fewer shares)
// Withdrawals: round DOWN the assets returned (user gets slightly less)
pub fn assets_to_shares_ceil(assets: u64, total_shares: u64, total_assets: u64) -> u64 {
    // ceil division: (a + b - 1) / b
    let numerator = (assets as u128) * (total_shares as u128) + (total_assets as u128) - 1;
    (numerator / (total_assets as u128)) as u64
}
```

---

## 8. Oracle Price Manipulation

**Severity**: Critical / High  
**Real exploit**: Mango Markets ($116M, Oct 2022) — Attacker self-reported a manipulated MNGO oracle price to borrow against inflated collateral.

### Vulnerable

```rust
pub fn get_price(oracle: &AccountInfo) -> Result<u64> {
    let price_data = PriceAccount::try_from_slice(&oracle.data.borrow())?;
    Ok(price_data.price as u64)   // BUG: no staleness, no confidence check
}
```

### Safe (Pyth)

```rust
use pyth_solana_receiver_sdk::price_update::{PriceUpdateV2, get_feed_id_from_hex};

pub fn get_validated_price(price_update: &Account<PriceUpdateV2>, max_age_seconds: u64) -> Result<i64> {
    let clock = Clock::get()?;
    let price = price_update.get_price_no_older_than(
        &clock,
        max_age_seconds,           // e.g. 60 seconds
        &get_feed_id_from_hex("0xef0d8b6fda...")?,
    )?;

    // Check confidence interval — reject if confidence > 1% of price
    let confidence_threshold = price.price.unsigned_abs() / 100;
    require!(price.conf <= confidence_threshold, ErrorCode::PriceUnstable);

    Ok(price.price)
}
```

---

## 9. Initialization Front-Running

**Severity**: High  
**Pattern**: An attacker sees the `init` transaction in the mempool and initializes the account with their own data first.

### Vulnerable

```rust
// BUG: seeds do not include the user's pubkey
// Attacker can create this PDA before the victim
#[account(
    init,
    seeds = [b"global-config"],
    bump,
    payer = admin,
    space = 8 + Config::INIT_SPACE,
)]
pub config: Account<'info, Config>,
```

### Safe

```rust
// Seeds include the admin's key — only they can create this PDA
#[account(
    init,
    seeds = [b"config", admin.key().as_ref()],
    bump,
    payer = admin,
    space = 8 + Config::INIT_SPACE,
)]
pub config: Account<'info, Config>,
```

---

## 10. Close Account Lamport Drain

**Severity**: High  
**Pattern**: Closing an account by zeroing its data but leaving its lamports. A subsequent instruction in the same transaction can still reference the "closed" account.

### Vulnerable

```rust
pub fn close_position(ctx: Context<ClosePosition>) -> Result<()> {
    let position = &mut ctx.accounts.position;
    position.is_closed = true;    // BUG: data zeroed but lamports not transferred
    // ...
    Ok(())
}
```

### Safe (Anchor)

```rust
#[derive(Accounts)]
pub struct ClosePosition<'info> {
    #[account(
        mut,
        close = user,   // transfers lamports to `user`, sets discriminator to CLOSED
    )]
    pub position: Account<'info, Position>,
    #[account(mut)]
    pub user: Signer<'info>,
}
```

---

## 11. Token 2022 Extension Bypass

**Severity**: High  
**Pattern**: Program assumes standard SPL Token behavior but the mint uses Token 2022 with transfer hooks or transfer fees.

### Vulnerable

```rust
// BUG: assumes transfer amount == amount_in; ignores transfer fee extension
token::transfer(cpi_ctx, amount_in)?;
let received = amount_in;   // wrong if transfer fee extension is active
```

### Safe

```rust
use spl_token_2022::extension::transfer_fee::TransferFeeConfig;

pub fn get_post_fee_amount(mint: &InterfaceAccount<Mint>, amount: u64) -> Result<u64> {
    let mint_data = mint.to_account_info();
    if let Ok(transfer_fee_config) = TransferFeeConfig::get_extension(&mint_data) {
        let fee = transfer_fee_config
            .newer_transfer_fee
            .calculate_fee(amount)
            .ok_or(ErrorCode::MathOverflow)?;
        Ok(amount - fee)
    } else {
        Ok(amount)
    }
}
```

---

## 12. Reentrancy via CPI

**Severity**: Critical  
**Pattern**: A CPI target calls back into the victim program before its state update is committed.

**Solana note**: The VM serializes account data **once** at the start of a transaction; CPIs see the same in-memory data. True reentrancy requires the CPI target to also be an Anchor/native program that modifies shared accounts. While less common than in EVM, it is possible in cross-program composable protocols.

### Pattern to Avoid

```rust
pub fn swap(ctx: Context<Swap>, amount: u64) -> Result<()> {
    // BUG: transfer funds BEFORE updating internal state
    token::transfer(cpi_ctx, amount)?;   // CPI can call back into this program
    ctx.accounts.pool.reserve -= amount; // state update arrives too late
    Ok(())
}
```

### Safe (Checks-Effects-Interactions)

```rust
pub fn swap(ctx: Context<Swap>, amount: u64) -> Result<()> {
    // 1. Checks: validate all inputs (done by Anchor constraints)
    // 2. Effects: update state FIRST
    ctx.accounts.pool.reserve -= amount;
    // 3. Interactions: external CPI last
    token::transfer(cpi_ctx, amount)?;
    Ok(())
}
```

---

## Historical Hacks Reference

| Protocol | Date | Loss | Root Cause | Pattern |
|---|---|---|---|---|
| Wormhole | Feb 2022 | $320M | Missing signer check on `verify_signatures` | #1 Missing Signer |
| Cashio | Mar 2022 | $52M | Arbitrary account passed as USDC collateral | #2 Missing Owner |
| Crema Finance | Jul 2022 | $8.8M | Tick account not validated as program-owned | #2 Missing Owner |
| Mango Markets | Oct 2022 | $116M | Oracle price manipulation via self-trading | #8 Oracle |
| Drift Protocol | Jun 2023 | $3M | Missing staleness check on oracle | #8 Oracle |
| Loopscale | Apr 2025 | $5.8M | Oracle price manipulation (yield vault) | #8 Oracle |

> Always search [Rekt.news](https://rekt.news) and [Sec3 Blog](https://www.sec3.dev/blog) for latest incidents before finalizing a report.
