# Solana Security Toolchain (2026)

> Setup guides, commands, and CI configuration for all major Solana security tools.

---

## 1. Trident — Fuzz Testing

[GitHub](https://github.com/Ackee-Blockchain/trident) | Maintained by Ackee Blockchain

Trident generates and runs random instruction sequences against your Anchor program to find panics, constraint violations, and unexpected state.

### Install

```bash
cargo install trident-cli
```

### Initialize in an existing Anchor project

```bash
cd my-anchor-project
trident init
```

This creates:
```
trident-tests/
  fuzz_tests/
    fuzz_0/
      accounts_snapshots.rs   # account state snapshots
      fuzz_instructions.rs    # instruction fuzzing logic
      test_fuzz.rs            # entry point
```

### Write a fuzz test

```rust
// trident-tests/fuzz_tests/fuzz_0/fuzz_instructions.rs
use trident_client::fuzzing::*;

#[derive(Arbitrary, TridentInstruction)]
pub enum FuzzInstruction {
    Deposit(Deposit),
    Withdraw(Withdraw),
    Swap(Swap),
}

impl FuzzTestExecutor<FuzzAccounts> for FuzzInstruction {
    fn run_fuzzer(
        &self,
        program_id: &Pubkey,
        accounts: &RefCell<FuzzAccounts>,
        client: &mut impl FuzzClient,
        sent_txs: &mut HashMap<u64, ()>,
    ) -> core::result::Result<(), FuzzClientErrorWithOrigin> {
        match self {
            FuzzInstruction::Deposit(ix) => ix.run(program_id, accounts, client, sent_txs),
            FuzzInstruction::Withdraw(ix) => ix.run(program_id, accounts, client, sent_txs),
            FuzzInstruction::Swap(ix) => ix.run(program_id, accounts, client, sent_txs),
        }
    }
}
```

### Run fuzzer

```bash
# Run for 60 seconds
trident fuzz run-hfuzz fuzz_0 -- -max_total_time=60

# Run with corpus saving
trident fuzz run-hfuzz fuzz_0 -- -max_total_time=300 -artifact_prefix=./corpus/

# Debug a crash
trident fuzz debug fuzz_0 ./corpus/crash-abc123
```

### Custom invariant checks

```rust
// Add invariant: vault balance never goes negative
impl FuzzClient for TestClient {
    fn check_invariants(&self) -> Result<()> {
        let vault = self.get_account::<Vault>(&vault_pda)?;
        assert!(vault.balance >= 0, "INVARIANT VIOLATED: vault balance negative");
        Ok(())
    }
}
```

---

## 2. Soteria / Sec3 — Static Analysis

[Sec3 Pro](https://www.sec3.dev) | Commercial tool with free tier

Soteria performs static analysis on compiled BPF bytecode to detect common Solana vulnerabilities without requiring source code.

### Free CLI scan

```bash
# Install
cargo install soteria-cli

# Scan your program (from workspace root)
soteria -analyzeAll .

# Output findings to JSON
soteria -analyzeAll . -json > findings.json
```

### What Soteria detects

| Detector | Finding Type |
|---|---|
| `sol-signer` | Missing signer check |
| `sol-owner` | Missing owner check |
| `sol-arithmetic` | Integer overflow |
| `sol-divide-by-zero` | Division by zero |
| `sol-invalid-account` | Account not validated |
| `sol-uninit` | Uninitialized account read |
| `sol-type-cosplay` | Account type confusion |
| `sol-arbitrary-cpi` | Unchecked CPI target |

### Sec3 Pro (recommended for production audits)

```bash
# Authenticate
sec3 login

# Run full analysis (includes data flow, taint tracking)
sec3 analyze --workspace . --output report.json

# View findings in dashboard
sec3 dashboard open
```

---

## 3. LiteSVM — Fast Security Tests

[GitHub](https://github.com/LiteSVM/litesvm) | Preferred for unit-level security testing

LiteSVM runs your program without a full validator, making it 10-100x faster than `solana-test-validator`.

### Install

```toml
# Cargo.toml [dev-dependencies]
litesvm = "0.4"
```

### Security test example

```rust
#[cfg(test)]
mod security_tests {
    use litesvm::LiteSVM;
    use solana_sdk::{
        pubkey::Pubkey,
        signature::{Keypair, Signer},
        transaction::Transaction,
    };

    #[test]
    fn test_unauthorized_withdraw_rejected() {
        let mut svm = LiteSVM::new();
        let payer = Keypair::new();
        let attacker = Keypair::new();

        svm.airdrop(&payer.pubkey(), 10_000_000_000).unwrap();
        svm.airdrop(&attacker.pubkey(), 10_000_000_000).unwrap();

        // Initialize vault with payer as authority
        let vault = setup_vault(&mut svm, &payer);

        // Attempt: attacker tries to withdraw as a non-signer
        let ix = withdraw_instruction(vault, attacker.pubkey(), 1_000_000);
        let tx = Transaction::new_signed_with_payer(
            &[ix],
            Some(&attacker.pubkey()),
            &[&attacker],
            svm.latest_blockhash(),
        );

        // Should fail with Unauthorized error
        let result = svm.send_transaction(tx);
        assert!(result.is_err(), "Expected withdrawal to fail for unauthorized caller");

        let err = result.unwrap_err();
        assert!(
            err.to_string().contains("Unauthorized"),
            "Expected Unauthorized error, got: {err}"
        );
    }

    #[test]
    fn test_overflow_protected() {
        let mut svm = LiteSVM::new();
        // Test with u64::MAX amount
        let result = deposit_with_amount(&mut svm, u64::MAX);
        assert!(result.is_err(), "Expected overflow to be caught");
    }
}
```

---

## 4. Mollusk — Unit Testing Framework

[GitHub](https://github.com/buffalojoec/mollusk) | Lightweight instruction-level testing

Mollusk tests a single instruction in isolation — no full SVM, extremely fast.

### Install

```toml
[dev-dependencies]
mollusk-svm = "0.4"
```

### Example

```rust
#[test]
fn test_initialize_pda_seeds() {
    let program_id = Pubkey::new_unique();
    let mollusk = Mollusk::new(&program_id, "target/deploy/my_program");

    let (pda, bump) = Pubkey::find_program_address(
        &[b"vault", authority.as_ref()],
        &program_id,
    );

    let result = mollusk.process_instruction(
        &initialize_ix(pda, bump),
        &[(pda, AccountSharedData::default())],
    );

    assert!(result.program_result.is_ok());
}
```

---

## 5. cargo-audit and cargo-deny

Supply chain security — check for known CVEs in dependencies.

### cargo-audit

```bash
cargo install cargo-audit
cargo audit

# Fail CI if any critical vulns found
cargo audit --deny warnings
```

### cargo-deny

```bash
cargo install cargo-deny
cargo deny init     # creates deny.toml
cargo deny check    # checks licenses, advisories, bans
```

Recommended `deny.toml` for Solana programs:

```toml
[advisories]
unmaintained = "deny"
yanked = "deny"
notice = "warn"

[licenses]
allow = ["MIT", "Apache-2.0", "ISC", "BSD-2-Clause", "BSD-3-Clause"]
deny = ["GPL-3.0", "AGPL-3.0"]

[bans]
multiple-versions = "warn"
wildcards = "deny"
```

---

## 6. Surfpool — Simulation Environment

[GitHub](https://github.com/trytrench/surfpool) | Full mainnet-fork simulation

Surfpool forks mainnet state for integration testing with real program state.

```bash
cargo install surfpool-cli

# Fork mainnet at current slot
surfpool fork --rpc https://api.mainnet-beta.solana.com

# Run tests against fork
SURFPOOL_URL=http://localhost:8899 cargo test
```

---

## 7. CI Security Pipeline

Add to `.github/workflows/security.yml`:

```yaml
name: Security

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  audit:
    name: Cargo Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rustsec/audit-check@v2
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  deny:
    name: Cargo Deny
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v2

  soteria:
    name: Soteria Static Analysis
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Install Soteria
        run: cargo install soteria-cli
      - name: Run analysis
        run: soteria -analyzeAll . && echo "No critical findings"

  security-tests:
    name: Security Unit Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - name: Run security tests
        run: cargo test security -- --nocapture

  fuzz:
    name: Fuzz (short run)
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    steps:
      - uses: actions/checkout@v4
      - name: Install Trident
        run: cargo install trident-cli
      - name: Fuzz for 60 seconds
        run: trident fuzz run-hfuzz fuzz_0 -- -max_total_time=60
```

---

## 8. Manual Review Tools

### Anchor IDL diff

Check that the IDL matches the deployed bytecode:

```bash
# Build and compare
anchor build
anchor idl fetch <program_id> --provider.cluster mainnet > deployed.json
diff target/idl/my_program.json deployed.json
```

### Account size check

Ensure accounts don't exceed compute limits:

```bash
# Check account sizes defined in program
grep -r "INIT_SPACE\|space = " programs/ | sort
```

### Unused code

```bash
cargo clippy -- -D warnings -D unused
```

### Check for unsafe blocks

```bash
grep -rn "unsafe {" programs/
```
