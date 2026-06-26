---
description: Run a rapid 15-minute triage of a Solana program. Covers Critical and High severity patterns only. Use before a full audit to identify show-stoppers, or for quick reviews of small programs.
---

# /audit-quick

Perform a rapid security triage of a Solana program. Covers the top Critical and High severity issues only.

## What This Command Does

1. Reviews account struct definitions for missing owner/signer constraints
2. Scans instruction handlers for arithmetic without `checked_*`
3. Identifies CPI calls without program ID validation
4. Checks `Cargo.toml` for `overflow-checks = true`
5. Lists all uses of `UncheckedAccount` / `AccountInfo` with manual safety review required
6. Reports findings as a triage table

## Usage

```
/audit-quick [program path or paste code here]
```

## Output Format

```
TRIAGE REPORT — [Program Name]
Reviewed: [N] instructions, [N] account structs, [N] CPI calls
Time: ~15 minutes

┌─────────────────────────────────────────────────────────────┐
│ CRITICAL                                                      │
├─────────────────────────────────────────────────────────────┤
│ • withdraw.rs:42 — authority not validated as Signer         │
│   Fix: Change AccountInfo → Signer<'info>                    │
├─────────────────────────────────────────────────────────────┤
│ HIGH                                                          │
├─────────────────────────────────────────────────────────────┤
│ • swap.rs:88 — token_program not validated as spl_token::ID  │
│   Fix: Use Program<'info, Token>                             │
├─────────────────────────────────────────────────────────────┤
│ NEEDS FULL AUDIT                                              │
├─────────────────────────────────────────────────────────────┤
│ • 3 UncheckedAccount usages require manual review            │
│ • Oracle price used without staleness check                  │
└─────────────────────────────────────────────────────────────┘

Recommendation: [Go / Hold / Launch blocker]
```

## Quick Triage Checklist

Run through this in order — stop at any Critical finding:

**A. Signer checks (2 min)**
- [ ] Every `withdraw`, `close`, `update`, `admin` instruction uses `Signer<'info>` for authority
- [ ] No `AccountInfo` used as authority without explicit `require!(account.is_signer, ...)`

**B. Owner checks (2 min)**
- [ ] No `AccountInfo` or `UncheckedAccount` used for token accounts
- [ ] All token accounts use `Account<'info, TokenAccount>` (Anchor checks owner automatically)

**C. CPI program validation (2 min)**
- [ ] All token CPIs use `Program<'info, Token>` or `Interface<'info, TokenInterface>`
- [ ] No `AccountInfo` used as `token_program` / `system_program`

**D. Arithmetic (3 min)**
- [ ] `Cargo.toml [profile.release]` contains `overflow-checks = true`
- [ ] Grep for unchecked math: `grep -n "[^_]amount\s*[+\-\*]\s*" programs/`
- [ ] Fee calculations use `u128` intermediate

**E. PDA seeds (2 min)**
- [ ] Seeds include enough uniqueness (user + asset, not just asset)
- [ ] Bump stored in account, not re-derived

**F. Audit flag**
- [ ] All `UncheckedAccount` usages have `// SAFETY:` comment explaining why safe
- [ ] All `unsafe {}` blocks reviewed

Total time: ~15 minutes for programs up to 1,000 nSLOC.
