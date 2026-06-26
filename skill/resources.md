# Solana Security Resources

> Curated references for Solana auditors. Updated for 2026 stack.

---

## Official Documentation

- [Solana Security Best Practices](https://solana.com/developers/guides/program-security/secure-transfer) — Official guide
- [Anchor Security](https://www.anchor-lang.com/docs/security) — Anchor-specific patterns
- [SPL Token Program](https://spl.solana.com/token) — Token account validation reference
- [Token 2022 Extensions](https://spl.solana.com/token-2022/extensions) — Transfer fees, hooks, etc.

---

## Public Audit Reports

Read these to understand real-world findings:

| Protocol | Auditor | Year | Link |
|---|---|---|---|
| Marinade Finance | OtterSec | 2023 | [PDF](https://github.com/marinade-finance/audits) |
| Drift Protocol | OtterSec + ABDK | 2023 | [GitHub](https://github.com/drift-labs/audits) |
| Jupiter Aggregator | OtterSec | 2024 | [GitHub](https://github.com/jup-ag/audits) |
| Raydium | Trail of Bits | 2022 | [GitHub](https://github.com/raydium-io/audits) |
| Solend | Halborn | 2022 | [PDF](https://github.com/solendprotocol/public) |
| Jito StakePool | Neodyme | 2023 | [GitHub](https://github.com/jito-foundation/audits) |
| Squads v4 | OtterSec + Neodyme | 2024 | [GitHub](https://github.com/Squads-Protocol/audits) |

---

## Security Research and Post-Mortems

- [Wormhole Post-Mortem](https://extropy-io.medium.com/solana-wormhole-hack-post-mortem-analysis-3b68b9e88e13) — $320M, missing signer check
- [Cashio Post-Mortem](https://blog.sec3.dev/cashio-hack-analysis-52m-lost/) — $52M, missing owner check
- [Crema Finance Analysis](https://medium.com/@1400820520/crema-finance-exploit-analysis-8-78m-lost-55a093bda39) — $8.8M, tick account bypass
- [Neodyme Solana Blog](https://blog.neodyme.io) — Deep vulnerability research
- [Sec3 Blog](https://www.sec3.dev/blog) — Soteria team, frequent Solana security posts
- [Rekt.news Solana](https://rekt.news/leaderboard/) — Comprehensive hack leaderboard
- [OtterSec Blog](https://osec.io/blog) — Solana audit findings and techniques

---

## Tools

| Tool | Purpose | Link |
|---|---|---|
| Trident | Fuzz testing | [GitHub](https://github.com/Ackee-Blockchain/trident) |
| Soteria / Sec3 | Static analysis | [sec3.dev](https://www.sec3.dev) |
| LiteSVM | Fast test SVM | [GitHub](https://github.com/LiteSVM/litesvm) |
| Mollusk | Unit testing | [GitHub](https://github.com/buffalojoec/mollusk) |
| Surfpool | Mainnet fork | [GitHub](https://github.com/trytrench/surfpool) |
| Kani | Rust model checker | [GitHub](https://github.com/model-checking/kani) |
| cargo-audit | CVE scanning | [crates.io](https://crates.io/crates/cargo-audit) |
| cargo-deny | License + ban check | [crates.io](https://crates.io/crates/cargo-deny) |
| Anchor CLI | IDL diff, build | [anchor-lang.com](https://www.anchor-lang.com) |

---

## Known Vulnerability Databases

- [SWC Registry (EVM reference)](https://swcregistry.io) — Many patterns translate to Solana
- [DASP Top 10](https://dasp.co) — DeFi attack surface patterns
- [Sec3 Vulnerability DB](https://www.sec3.dev/vulnerabilities) — Solana-specific CVE catalog
- [Immunefi Bug Bounty](https://immunefi.com/explore/?filter=solana) — Active Solana bounties

---

## Learning

- [Neodyme Solana Security Workshop](https://github.com/neodyme-labs/solana-security-txt) — Hands-on exploit exercises
- [Ackee Solana School](https://ackee.xyz/solana-programs-security) — Free security course
- [Solana Cookbook Security](https://solanacookbook.com/references/programs.html#security) — Code examples
- [Anchor Book](https://book.anchor-lang.com) — Understanding constraints before auditing them

---

## Bug Bounty Programs

| Protocol | Platform | Max Payout |
|---|---|---|
| Solana Labs | Immunefi | $2M |
| Drift Protocol | Immunefi | $1M |
| Jupiter | Immunefi | $1M |
| Marinade Finance | Immunefi | $500K |
| Orca | Immunefi | $500K |

> Always check [Immunefi Solana page](https://immunefi.com/explore/?filter=solana) for current programs.

---

## Auditing Firms (Solana-Specialized)

| Firm | Notable Audits |
|---|---|
| OtterSec | Drift, Jupiter, Marinade, Orca |
| Neodyme | Jito, Solend, Mango (pre-hack advisory) |
| Trail of Bits | Raydium, Pyth, Wormhole (post-hack) |
| Halborn | Solend, Star Atlas |
| Sec3 | Multiple DeFi protocols |
| Zellic | Serum, Mango |
| Kudelski Security | Solana Labs core |
