# Ideation → selection → combination

This document records how the final concept was chosen (judging weight in brackets).

## Candidate ideas

| # | Idea | Summary | Strong | Weak | Weighted score |
|---|---|---|---|---|---|
| 1 | **AegisPay** — policy-guarded agentic payments | Smart account + scoped session keys + ERC-8004 identity; agent pays verified merchants with tUSD8; budget/expiry/allowlist/approval/revocation | Innovation (20), platform (15), safety (15), utility (15) | Needs careful UX to explain | **93** |
| 2 | StreamPay | tUSD8 salary/subscription streaming | Utility, familiar | Generic (Sablier-style), low innovation | 61 |
| 3 | RepuPay | ERC-8004 reputation-gated escrow for agent services | Identity depth, trust | No real-time agentic payments, weak demo | 70 |
| 4 | MicroPay | Pay-per-call API gateway for agents | Utility, demo | No identity/session-key guardrails, safety-light | 68 |

## Why #1 won

Innovation is the single heaviest criterion (20) and AegisPay is the only idea that makes the **agent itself** the subject of the safety story: it is not just a wallet that pays, it is an identity-bound, least-privilege economic actor. It also stacks cleanly with the other ideas.

## The combination

We merged the strongest mechanics from all four:

```
#1 AegisPay   -> smart account, scoped session keys, spend caps, expiry, revocation
   + #3 RepuPay -> ERC-8004 identity binding for agent and merchant, feedback receipts
   + #4 MicroPay -> per-call settlement through a router with service references (invoice ids)
   + #2 StreamPay idea -> cumulative budget that behaves like a funding allowance
```

The result is **one end-to-end flow**: *principal registers agent identity → funds account → issues scoped key → agent pays a verified merchant per invoice → router settles + writes reputation → principal revokes.*

## Track alignment

The starter guide lists explicit tracks. AegisPay deliberately spans three:

- **Native AI Assistants** — autonomous agent executes payments under policy.
- **Confirmation of Payee** — merchants must be ERC-8004-bound before receiving funds.
- **Decentralized Payments** — tUSD8 settlement through a smart account.

## Scorecard vs. judging criteria

| Criterion | Weight | How this build addresses it |
|---|---|---|
| UX & presentation | 15 | Single-page responsive demo UI with step-by-step state, plain-language errors, and a 2–3 min scripted pitch |
| Demo clear & structured | 10 | `make demo` local run + `demo/agent-runner.mjs` live run printing tx hashes and explorer links; failure cases covered by tests |
| Documentation | 10 | README + architecture + API examples + env spec + testnet addresses + roadmap |
| Innovation | 20 | Identity-bound session keys with per-call settlement and single-use human approval for high-value agent payments |
| Technical quality | 15 | Foundry, 21 tests, custom errors, immutable config, checks-effects-interactions, shanghai EVM, retrying viem runner |
| Utility | 15 | Merchant/API businesses and agent operators get programmable payments with auditable receipts |
| Safety | 15 | Caps, expiry, payee lock, identity checks, instant revocation, single-use approvals, on-chain audit trail |
