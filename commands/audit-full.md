---
description: Run a full structured security audit using the complete 60-item checklist. Covers all severity levels and produces findings ready for report generation. Use for pre-launch reviews of production programs.
---

# /audit-full

Conduct a complete security audit of a Solana program following the full methodology in [audit-process.md](../skill/audit-process.md).

## Usage

```
/audit-full [program path]
/audit-full programs/lending/
/audit-full [paste instruction code]
```

## What This Command Does

1. Architecture review — accounts, trust model, CPI graph
2. Full [checklist.md](../skill/checklist.md) pass (60+ items)
3. Finding documentation with severity and location
4. PoC code for all ≥ Medium findings
5. Automated tool output interpretation
6. Findings summary ready for `/gen-report`

## Process

### Step 1: Architecture (5 min)

Answer these questions before reviewing any instruction:

```
Program name:
What it does (one sentence):
Programs it calls (CPIs):
Accounts holding value:
Who can withdraw (authority):
Is it upgradeable (upgrade authority):
```

### Step 2: Run Full Checklist

Work through [checklist.md](../skill/checklist.md) systematically:
- Category 1: Account Validation (items 1.1 – 1.6)
- Category 2: CPI Security (items 2.1 – 2.4)
- Category 3: Math (items 3.1 – 3.4)
- Category 4: Access Control (items 4.1 – 4.3)
- Category 5: Token / SPL (items 5.1 – 5.3)
- Category 6: State Machine (items 6.1 – 6.4)
- Category 7: Anchor-Specific
- Category 8: Rust / Cargo
- Category 9: Off-Chain

### Step 3: Document Findings

For each checklist item that fails:

```
[FINDING] #N
Severity: Critical / High / Medium / Low / Informational
Category: [checklist category]
Location: [file:line]
Summary: [one sentence]
Detail: [why this is exploitable]
PoC: [LiteSVM test or reproduction steps]
Fix: [before/after code diff]
```

### Step 4: Automated Tools

```bash
# Run after manual review
cargo audit
soteria -analyzeAll .
trident fuzz run-hfuzz fuzz_0 -- -max_total_time=3600
```

Paste output to interpret findings.

### Step 5: Summary Table

After all findings documented:

| ID | Severity | Category | Location | Status |
|---|---|---|---|---|
| PROG-01 | Critical | Signer Check | withdraw.rs:42 | Open |
| PROG-02 | High | Owner Check | deposit.rs:18 | Open |

### Step 6: Generate Report

Use `/gen-report` with the findings summary.
