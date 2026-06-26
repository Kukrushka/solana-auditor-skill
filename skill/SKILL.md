---
name: solana-auditor
description: Full-lifecycle Solana security auditor. Covers manual account validation review, on-chain vulnerability patterns, automated static analysis, fuzzing, formal verification, and professional report generation. Use for pre-launch security reviews, incident triage, and continuous security hardening of Solana programs.
user-invocable: true
---

# Solana Auditor Skill

> **Complements**: [solana-dev-skill](../solana-dev/SKILL.md) — Core Solana development (programs, frontend, testing)

## What This Skill Is For

Use this skill when the user needs:

### Pre-Launch Audit
- Full security review of an Anchor or native Solana program before mainnet deployment
- Account validation checklist — signer, owner, PDA, mint, token checks
- CPI security review — arbitrary invoke, reentrancy, sysvar spoofing
- Math and arithmetic safety — overflow, precision, rounding direction
- Access control and authority patterns

### Vulnerability Research
- Identifying specific CVE-class bugs in Solana programs
- Understanding historical hacks (Wormhole, Cashio, Crema, Mango, Slope)
- Reproducing and writing proof-of-concept exploits for known patterns
- Formal specification of invariants

### Automated Tooling
- Setting up Trident fuzzer for program-level fuzz testing
- Running Soteria / Sec3 static analysis
- Configuring LiteSVM or Mollusk for property-based testing
- CI pipeline for continuous security checks

### Formal Verification
- Writing formal specifications for critical invariants
- Using symbolic execution to verify account constraint completeness
- Differential testing between program versions

### Report Generation
- Creating professional audit reports (Trail of Bits / OtterSec / Halborn style)
- Risk classification (Critical / High / Medium / Low / Informational)
- Writing clear PoC reproduction steps
- Remediation guidance with before/after code diffs

---

## Default Stack (2026)

| Layer | Tool |
|-------|------|
| Framework | Anchor 0.31.x |
| Solana CLI | 2.x (Agave client) |
| Fuzzer | Trident 0.8.x |
| Static analysis | Soteria / Sec3 Pro |
| Test framework | LiteSVM 0.4.x, Mollusk 0.4.x |
| Simulation | Surfpool |
| Supply chain | cargo-audit, cargo-deny |
| Formal | Certora Prover (where applicable) |

---

## Operating Procedure

### 1. Classify the Request

| User asks for... | Skill file |
|------------------|-----------|
| "Audit my program", full review | [checklist.md](checklist.md) → [vulnerabilities.md](vulnerabilities.md) |
| Specific bug category | [vulnerabilities.md](vulnerabilities.md) |
| Set up fuzzer | [tools.md](tools.md) |
| Write an audit report | [report.md](report.md) |
| Formal verification | [formal-verification.md](formal-verification.md) |
| Learn how auditors work | [audit-process.md](audit-process.md) |
| Historical Solana hacks | [vulnerabilities.md](vulnerabilities.md) |
| Tools setup, CI pipeline | [tools.md](tools.md) |

### 2. Pick the Right Agent

| Task | Agent | Model |
|------|-------|-------|
| Deep code review, full audit | audit-lead | opus |
| Vulnerability research | vuln-researcher | opus |
| Quick report draft | audit-lead | sonnet |
| Tool setup, CI | audit-lead | sonnet |

### 3. Audit Execution Order

```
1. Scope definition       → What programs, what trust boundaries
2. Architecture review    → On-chain state, CPIs, PDAs, token flow
3. Account validation     → checklist.md — run every item
4. Logic review           → State machine, math, access control
5. Automated scanning     → tools.md — Soteria + Trident
6. Finding classification → report.md risk matrix
7. Report generation      → report.md template
8. Remediation review     → Verify fixes don't introduce new bugs
```

### 4. Two-Strike Rule

If a vulnerability cannot be confirmed after two independent analysis passes, classify as **Informational** and note uncertainty. Never escalate severity without on-chain PoC or clear reasoning.

### 5. Deliverables

- Severity-ranked findings table
- PoC code or reproduction steps for each finding ≥ Medium
- Diff showing remediation for each finding
- Final report using [report.md](report.md) template

---

## Progressive Disclosure

### Core Audit Skills

- [audit-process.md](audit-process.md) — Methodology, scoping, trust model analysis
- [checklist.md](checklist.md) — 60+ item vulnerability checklist, category by category
- [vulnerabilities.md](vulnerabilities.md) — Patterns with vulnerable/safe code examples, real hacks
- [tools.md](tools.md) — Toolchain setup: Trident, Soteria, LiteSVM, CI pipeline
- [formal-verification.md](formal-verification.md) — Invariant specification, symbolic execution
- [report.md](report.md) — Professional report template, risk matrix, finding format
- [resources.md](resources.md) — Reference links, past audit reports, research papers

### Core Solana Dev Skills (delegate when needed)

> Provided by [solana-dev-skill](../solana-dev/SKILL.md)

- [programs-anchor.md](../solana-dev/programs-anchor.md) — Anchor patterns (read to understand what auditor is reviewing)
- [testing.md](../solana-dev/testing.md) — LiteSVM, Mollusk, Surfpool
- [security.md](../solana-dev/security.md) — Dev-side security baseline

---

## Task Routing Guide

| User asks about... | Primary skill file |
|--------------------|--------------------|
| Full program audit | checklist.md + vulnerabilities.md |
| Missing signer check | vulnerabilities.md |
| Missing owner check | vulnerabilities.md |
| PDA validation | vulnerabilities.md |
| Arbitrary CPI | vulnerabilities.md |
| Integer overflow | vulnerabilities.md |
| Token account checks | vulnerabilities.md |
| Account discriminator | vulnerabilities.md |
| Reentrancy | vulnerabilities.md |
| Wormhole hack | vulnerabilities.md |
| Cashio hack | vulnerabilities.md |
| Setting up Trident | tools.md |
| Soteria / Sec3 | tools.md |
| LiteSVM security tests | tools.md |
| CI security pipeline | tools.md |
| Formal invariants | formal-verification.md |
| Certora Prover | formal-verification.md |
| Audit report format | report.md |
| Risk classification | report.md |
| Writing findings | report.md |
| Audit methodology | audit-process.md |
| Scoping an audit | audit-process.md |
| Threat modeling | audit-process.md |

---

## Commands

| Command | Description |
|---------|-------------|
| /audit-quick | Run a rapid triage of a program (15-min pass) |
| /audit-full | Full structured audit using the complete checklist |
| /gen-report | Generate a professional audit report from findings |

## Agents

| Agent | Purpose |
|-------|---------|
| **audit-lead** | Senior auditor: full review, finding classification, report generation |
| **vuln-researcher** | Deep vulnerability research, PoC development, historical analysis |
