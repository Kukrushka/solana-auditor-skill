---
name: solana-auditor
description: Full-lifecycle Solana security auditor for Claude Code. Covers manual account validation review, on-chain vulnerability patterns (missing signer, owner, PDA, CPI, overflow, oracle manipulation), automated tooling (Trident fuzzer, Soteria, LiteSVM), formal verification, and professional audit report generation. Use for pre-launch security reviews, vulnerability research, and continuous security hardening.
user-invocable: true
---

<!-- Entry point — see skill/SKILL.md for full routing table -->

# Solana Auditor Skill

This is the entry point for the `solana-auditor` skill.

**Routing**: See [skill/SKILL.md](skill/SKILL.md) for the full skill definition, operating procedure, and task routing guide.

## Quick Reference

| I want to... | Use |
|---|---|
| Quick triage | `/audit-quick` |
| Full audit | `/audit-full` |
| Write audit report | `/gen-report` |
| Look up a vulnerability | [skill/vulnerabilities.md](skill/vulnerabilities.md) |
| Run the full checklist | [skill/checklist.md](skill/checklist.md) |
| Set up fuzzing | [skill/tools.md](skill/tools.md) |
| Generate a report | [skill/report.md](skill/report.md) |
