# solana-auditor-skill

A production-grade security auditing skill for Claude Code. Turns any Claude Code session into an expert Solana security auditor — covering the full lifecycle from pre-audit scoping to professional report delivery.

## What It Does

This skill gives Claude Code deep expertise in:

- **Manual vulnerability review** — 60-item checklist covering all known Solana attack classes
- **Vulnerability patterns** — 12 canonical patterns with vulnerable/safe code examples and historical exploit references (Wormhole, Cashio, Crema, Mango)
- **Automated tooling** — Setup and interpretation of Trident fuzzer, Soteria static analysis, LiteSVM property tests, and Kani formal verification
- **Report generation** — Professional audit reports following Trail of Bits / OtterSec conventions
- **Continuous security** — CI pipeline configuration for ongoing security checks

## Problem It Solves

Solana security audits are expensive ($20K–$200K), slow (4–8 weeks), and in short supply. Most protocols launch without a full audit. Meanwhile, common vulnerability classes — missing signer checks, arbitrary CPI, integer overflow — keep appearing in exploited protocols and costing billions.

This skill gives every Solana developer access to audit-grade security review at the speed of Claude Code.

## Install

```bash
git clone https://github.com/solanabr/solana-auditor-skill
cd solana-auditor-skill
chmod +x install.sh
./install.sh
```

This installs the skill to `~/.claude/skills/solana-auditor/`.

## Quick Start

After installation, use any of these in Claude Code:

```
/audit-quick programs/my_program/     # 15-minute triage
/audit-full programs/my_program/      # Full structured audit
/gen-report                           # Generate audit report from findings
```

Or just ask Claude naturally:

- "Audit this Anchor instruction for security issues"
- "Show me if this has a missing signer check"
- "Set up Trident fuzzing for my vault program"
- "Write a PoC for this potential overflow"
- "Generate an audit report from these findings"

## Skill Structure

```
solana-auditor-skill/
├── skill/
│   ├── SKILL.md                 ← Entry point, routing table
│   ├── checklist.md             ← 60-item vulnerability checklist
│   ├── vulnerabilities.md       ← 12 patterns with PoC code + historical hacks
│   ├── tools.md                 ← Trident, Soteria, LiteSVM, cargo-audit, CI
│   ├── report.md                ← Professional report template
│   ├── audit-process.md         ← Full methodology (scope → report)
│   ├── formal-verification.md   ← Proptest, Kani, invariant specification
│   └── resources.md             ← Links to audits, research, tools, bounties
├── agents/
│   ├── audit-lead.md            ← Senior auditor agent (opus)
│   └── vuln-researcher.md       ← PoC and fuzzing specialist (opus)
└── commands/
    ├── audit-quick.md           ← /audit-quick — 15-min triage
    ├── audit-full.md            ← /audit-full — complete review
    └── gen-report.md            ← /gen-report — report generation
```

## Vulnerability Coverage

| Class | Severity | Real Exploit |
|---|---|---|
| Missing signer check | Critical | Wormhole ($320M) |
| Missing owner check | High | Cashio ($52M) |
| Arbitrary CPI | Critical | — |
| Account reload after CPI | High | — |
| PDA seed collision | High | — |
| Integer overflow | Critical | — |
| Rounding direction | Medium | — |
| Oracle manipulation | Critical | Mango ($116M), Loopscale ($5.8M) |
| Init front-running | High | — |
| Close account lamport drain | High | — |
| Token 2022 extension bypass | High | — |
| CPI reentrancy | Critical | — |

## Tools Covered

| Tool | Purpose |
|---|---|
| Trident | Fuzz testing — finds crashes via random instruction sequences |
| Soteria / Sec3 | Static analysis — detects 8 vulnerability classes automatically |
| LiteSVM | Fast security unit tests — 100x faster than test-validator |
| Mollusk | Instruction-level unit testing |
| Surfpool | Mainnet-fork simulation |
| Kani | Rust model checker for formal bounds verification |
| cargo-audit | CVE scanning for dependencies |
| cargo-deny | License and ban enforcement |

## Requirements

- Claude Code (any version)
- Anchor 0.30+ (for Anchor-specific guidance)
- Solana CLI 2.x (for program building)

## License

MIT — free to use, fork, and extend.

## Contributing

PRs welcome. If you find a vulnerability pattern not covered in [skill/vulnerabilities.md](skill/vulnerabilities.md), please add it with:
- Vulnerable code example
- Safe code example
- Real-world exploit reference (if available)

---

Built for the [Solana AI Kit](https://github.com/solanabr/solana-ai-kit) by Superteam Brasil.
