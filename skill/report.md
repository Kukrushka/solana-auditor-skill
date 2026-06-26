# Audit Report Template

> Professional audit report structure following OtterSec / Trail of Bits / Halborn conventions.
> Use `/gen-report` command to auto-populate this template from findings.

---

## Report Template

```markdown
# [Protocol Name] Security Audit

**Audited by**: [Auditor / Team]
**Audit period**: [Start Date] – [End Date]
**Report version**: 1.0
**Status**: Final

---

## Executive Summary

[2-3 paragraph summary of what was audited, overall security posture, and key recommendations.]

[Protocol Name] is a [brief description]. The audit reviewed [N] programs across [N] instruction handlers, totaling approximately [N] lines of Rust code.

**Overall risk**: [Critical / High / Medium / Low]

| Severity | Count | Resolved | Outstanding |
|---|---|---|---|
| Critical | N | N | N |
| High | N | N | N |
| Medium | N | N | N |
| Low | N | N | N |
| Informational | N | N | N |
| **Total** | **N** | **N** | **N** |

---

## Scope

| Item | Version / Commit |
|---|---|
| Repository | `github.com/org/repo` |
| Commit | `abc1234` |
| Programs audited | `programs/my_program` |
| Programs excluded | `programs/migrations` |
| Test suite | Reviewed but not in scope |

**Out of scope**: Off-chain infrastructure, frontend, key management.

---

## Methodology

1. **Architecture review** — High-level design, trust model, data flow
2. **Manual code review** — Line-by-line review using [checklist.md](checklist.md)
3. **Automated analysis** — Soteria static analysis, cargo-audit
4. **Dynamic testing** — Trident fuzzing, LiteSVM security tests
5. **Finding verification** — PoC reproduction for all ≥ Medium findings

---

## Findings

### [PROTOCOL-01] — [Finding Title]

| Attribute | Value |
|---|---|
| **Severity** | Critical / High / Medium / Low / Informational |
| **Category** | Missing Signer Check / Integer Overflow / ... |
| **Location** | `programs/my_program/src/instructions/deposit.rs:42` |
| **Status** | Open / Resolved in commit `abc1234` / Acknowledged |

**Description**

[Clear explanation of the vulnerability. What is the code doing wrong, and why is it a security issue?]

**Impact**

[What can an attacker do? What assets are at risk? What is the maximum loss?]

**Proof of Concept**

```rust
// Minimal reproduction demonstrating the vulnerability
#[test]
fn test_exploit() {
    let mut svm = LiteSVM::new();
    let attacker = Keypair::new();
    // ... setup
    // ... execute attack
    // ... verify exploit succeeded
    println!("Attacker gained: {} lamports", gained);
}
```

**Recommendation**

[Concrete fix with before/after code diff.]

```rust
// Before (vulnerable)
pub fn withdraw(ctx: Context<Withdraw>) -> Result<()> {
    // missing signer check
}

// After (safe)
pub fn withdraw(ctx: Context<Withdraw>) -> Result<()> {
    require!(ctx.accounts.authority.is_signer, ErrorCode::Unauthorized);
}
```

**References**
- [Solana Cookbook: Signer Checks](https://solanacookbook.com/references/programs.html#how-to-check-if-a-signer-is-a-signer)
- Similar finding: [Wormhole Post-Mortem](https://extropy-io.medium.com/solana-wormhole-hack-post-mortem-analysis-3b68b9e88e13)

---

### [PROTOCOL-02] — [Next Finding]

[Repeat structure for each finding]

---

## Risk Matrix

```
           │  LOW  │  MED  │  HIGH │
───────────┼───────┼───────┼───────┤
CRITICAL   │ High  │  Crit │  Crit │
───────────┼───────┼───────┼───────┤
HIGH       │  Med  │  High │  Crit │
───────────┼───────┼───────┼───────┤
MEDIUM     │  Low  │  Med  │  High │
───────────┼───────┼───────┼───────┤
LOW        │  Info │  Low  │  Med  │
───────────┴───────┴───────┴───────┘
           Impact →

Likelihood ↑
```

---

## Recommendations Summary

| Priority | Recommendation |
|---|---|
| Immediate | [Action for Critical findings] |
| Before launch | [Action for High findings] |
| 30 days | [Action for Medium findings] |
| Ongoing | [Security monitoring, re-audit after major changes] |

---

## Appendix A: Program Architecture

[Diagram or description of account relationships, instruction flow, and trust boundaries.]

```
User ──────► [Deposit ix] ──────► Vault PDA
                │                    │
                ▼                    ▼
         UserPosition PDA       Token Account
```

---

## Appendix B: Test Coverage

| Instruction | Unit Tests | Fuzz Tested | Security Tests |
|---|---|---|---|
| initialize | ✅ | ✅ | ✅ |
| deposit | ✅ | ✅ | ✅ |
| withdraw | ✅ | ✅ | ✅ |
| close | ✅ | ❌ | ✅ |

---

## Appendix C: Automated Tool Output

### Soteria

```
Found 0 critical issues
Found 2 warnings (see findings PROTOCOL-03, PROTOCOL-04)
```

### cargo-audit

```
Crates.io advisories: 0
```

### Trident (60 min run)

```
Unique crashes: 1 (see PROTOCOL-01 PoC)
Total execs: 1,247,832
Execs/s: 20,797
```
```

---

## Severity Definitions

| Severity | Description |
|---|---|
| **Critical** | Directly exploitable for fund loss or protocol takeover; must fix before launch |
| **High** | Likely exploitable under realistic conditions; fix before launch |
| **Medium** | Exploitable under specific conditions; fix before launch or document mitigations |
| **Low** | Unlikely to cause harm alone; fix post-launch |
| **Informational** | Best practice deviation; no direct risk |

## Finding Status Definitions

| Status | Meaning |
|---|---|
| **Open** | Not yet addressed |
| **Resolved** | Fixed and verified by auditor |
| **Acknowledged** | Team accepts the risk and will not fix |
| **Partially Resolved** | Partially mitigated; residual risk documented |
