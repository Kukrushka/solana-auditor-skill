# Formal Verification for Solana Programs

> Techniques for mathematically proving correctness of critical invariants.

---

## When to Use Formal Verification

Formal verification is expensive — apply it to:
- Programs holding > $1M TVL
- Core arithmetic in AMMs, lending, and derivatives
- Authority / signer logic in multisig and governance
- Custom cryptographic operations

For most programs, **fuzzing + property tests + manual review** is sufficient.

---

## 1. Property-Based Testing with LiteSVM

Before reaching for formal tools, write property-based tests. These catch 80% of invariant violations at 10% of the cost.

### Invariant Example: Vault Solvency

```rust
// programs/my_program/tests/properties.rs
use litesvm::LiteSVM;
use proptest::prelude::*;

proptest! {
    #[test]
    fn vault_always_solvent(deposit_amounts in prop::collection::vec(1u64..1_000_000_000u64, 1..20)) {
        let mut svm = LiteSVM::new();
        // ... setup

        let mut total_deposited: u128 = 0;

        for amount in &deposit_amounts {
            deposit(&mut svm, *amount).unwrap();
            total_deposited += *amount as u128;
        }

        // INVARIANT: vault token balance >= sum of all deposits
        let vault_balance = get_vault_token_balance(&svm);
        assert!(
            vault_balance as u128 >= total_deposited,
            "SOLVENCY VIOLATED: balance={vault_balance} < deposited={total_deposited}"
        );
    }
}
```

### Invariant Example: No Free Tokens

```rust
proptest! {
    #[test]
    fn no_tokens_created_from_thin_air(
        deposit in 1u64..u64::MAX / 2,
        withdraw in 1u64..u64::MAX / 2,
    ) {
        let mut svm = LiteSVM::new();
        let user_initial = get_user_balance(&svm);

        deposit_tokens(&mut svm, deposit).unwrap();
        let _ = withdraw_tokens(&mut svm, withdraw);   // may fail

        let user_final = get_user_balance(&svm);
        let vault_final = get_vault_balance(&svm);

        // INVARIANT: tokens are conserved
        assert_eq!(
            user_final + vault_final,
            user_initial,
            "Tokens created or destroyed"
        );
    }
}
```

---

## 2. Invariant Specification

Before using any formal tool, write down invariants as comments or specifications:

```rust
//! # Protocol Invariants
//!
//! I1 (Solvency):   vault.token_balance >= sum(position.shares for all positions)
//! I2 (No-Drain):   vault.token_balance never decreases except via authorized withdrawals
//! I3 (Authority):  only vault.authority can call withdraw()
//! I4 (Overflow):   all arithmetic results fit in u64; intermediates use u128
//! I5 (PDA-Unique): no two user positions share the same PDA address
```

These invariants become your test targets — each one gets a property test or formal spec.

---

## 3. Soteria Invariant Annotations

Soteria supports inline invariant annotations that are checked during static analysis:

```rust
#[program]
pub mod my_protocol {
    use super::*;

    // @soteria-invariant: amount > 0 => ctx.accounts.vault.balance increases
    pub fn deposit(ctx: Context<Deposit>, amount: u64) -> Result<()> {
        let vault = &mut ctx.accounts.vault;
        vault.balance = vault.balance.checked_add(amount)
            .ok_or(ErrorCode::Overflow)?;
        Ok(())
    }

    // @soteria-invariant: ctx.accounts.authority.is_signer == true
    pub fn withdraw(ctx: Context<Withdraw>, amount: u64) -> Result<()> {
        // ...
    }
}
```

---

## 4. Symbolic Execution with Kani

[Kani](https://github.com/model-checking/kani) is a Rust model checker that can verify bounded properties.

### Install

```bash
cargo install --locked kani-verifier
cargo kani setup
```

### Write a Kani proof

```rust
#[cfg(kani)]
mod verification {
    use super::*;

    #[kani::proof]
    #[kani::unwind(10)]
    fn verify_fee_calculation_no_overflow() {
        let amount: u64 = kani::any();
        let fee_bps: u64 = kani::any();

        // Bound inputs to realistic values
        kani::assume(amount <= 1_000_000_000_000u64);  // 1M tokens max
        kani::assume(fee_bps <= 10_000u64);             // 0-100%

        // This should never overflow (uses u128 intermediate)
        let fee = calculate_fee(amount, fee_bps);

        // Verify fee is bounded
        assert!(fee <= amount);
    }

    #[kani::proof]
    fn verify_pda_uniqueness() {
        let user1: [u8; 32] = kani::any();
        let user2: [u8; 32] = kani::any();
        let mint: [u8; 32] = kani::any();

        // If users differ, their PDAs must differ
        kani::assume(user1 != user2);

        let pda1 = derive_user_vault_pda(&user1, &mint);
        let pda2 = derive_user_vault_pda(&user2, &mint);

        assert_ne!(pda1, pda2);
    }
}
```

### Run Kani

```bash
cargo kani --harness verify_fee_calculation_no_overflow
cargo kani --harness verify_pda_uniqueness
```

---

## 5. Differential Testing

Test that two implementations of the same logic always agree — useful when rewriting or optimizing.

```rust
#[test]
fn differential_fee_calculation() {
    // Old implementation (simple but may overflow)
    fn fee_v1(amount: u64, bps: u64) -> u64 {
        amount * bps / 10_000  // vulnerable to overflow
    }

    // New implementation (safe)
    fn fee_v2(amount: u64, bps: u64) -> u64 {
        ((amount as u128) * (bps as u128) / 10_000) as u64
    }

    // They must agree on all non-overflowing inputs
    for amount in [0u64, 1, 1000, 1_000_000, u64::MAX / 10_001] {
        for bps in [0u64, 1, 100, 300, 1000, 10_000] {
            let v1 = fee_v1(amount, bps);
            let v2 = fee_v2(amount, bps);
            assert_eq!(v1, v2, "Divergence at amount={amount}, bps={bps}");
        }
    }
}
```

---

## 6. Certora Prover (Advanced)

[Certora](https://www.certora.com) provides formal verification for smart contracts. Solana support is experimental (2026).

For protocols where Certora is applicable, write `.spec` files:

```
// vault.spec
methods {
    function deposit(uint64 amount) external;
    function withdraw(uint64 amount) external;
    function getBalance() external returns (uint64);
}

// Invariant: total balance is non-decreasing except via withdraw
invariant noFreeMint(uint64 amount)
    getBalance() >= 0
    {
        preserved deposit(uint64 a) with (env e) {
            require a > 0;
        }
    }
```

---

## Formal Verification Checklist

- [ ] Invariants documented as comments before any tooling applied
- [ ] Property-based tests written for all critical invariants
- [ ] Kani proofs for arithmetic-heavy functions
- [ ] Differential tests for any rewritten logic
- [ ] Soteria invariant annotations added for key functions
- [ ] Results included in audit report Appendix
