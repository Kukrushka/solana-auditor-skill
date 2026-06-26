---
description: Generate a professional security audit report from a list of findings. Produces a complete report following Trail of Bits / OtterSec conventions, ready to deliver to a client.
---

# /gen-report

Generate a professional audit report from your findings.

## Usage

```
/gen-report
[Paste your findings summary here, or describe what was audited]
```

## What This Command Does

1. Takes your findings (from `/audit-full` or manual notes)
2. Fills in the [report.md](../skill/report.md) template
3. Generates executive summary, risk matrix, and recommendations
4. Produces markdown output ready to share or publish

## Input Format

Provide findings in any of these formats:

**Format A — Structured findings:**
```
Program: my_lending_protocol
Commit: abc1234

Findings:
- CRIT: withdraw.rs:42 — missing signer check on authority
- HIGH: deposit.rs:88 — missing owner check on token account
- MED: swap.rs:120 — oracle price used without staleness check
- INFO: config.rs:15 — missing event emission on config update
```

**Format B — Natural language:**
```
I found 3 issues in the lending program:
1. Critical: anyone can call withdraw without being the vault authority
2. High: token account owner not validated in deposit
3. Medium: oracle staleness not checked
```

**Format C — Paste code + describe the issue:**
```
Here's the vulnerable code: [paste]
The bug is: [describe]
```

## Output Structure

The generated report follows this structure:

```markdown
# [Protocol] Security Audit
**Audited by**: [name]  **Commit**: [hash]

## Executive Summary
[auto-generated from findings]

## Findings Summary
| ID | Severity | Title | Status |
[all findings]

## [PROTOCOL-01] Missing Signer Check
**Severity**: Critical
**Location**: withdraw.rs:42
[description, impact, PoC, fix]

...

## Recommendations
[prioritized action items]

## Appendix: Tools Used
[what was run]
```

## Report Quality Standards

The generated report will:
- **Not overstate severity** — only Critical if truly exploitable with no preconditions
- **Include working PoC** for all ≥ Medium (or explicitly note if PoC not possible)
- **Use precise locations** — file, line number, function name
- **Write for two audiences** — technical detail for devs, executive summary for founders
- **Follow responsible disclosure** — if unpublished, remind user to coordinate with team before publishing
