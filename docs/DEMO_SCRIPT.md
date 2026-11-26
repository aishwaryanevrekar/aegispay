# Demo video script (2–3 minutes)

Record while running `make demo` locally or `node --env-file=.env demo/agent-runner.mjs` on Aevum. Keep the explorer open in a second tab for verifiable tx hashes.

## 0:00–0:20 — Hook

> "AI agents are about to start paying for things. But today an agent either controls a whole wallet — or nothing. AegisPay gives an agent just enough money to do its job, and a kill switch for everything else."

On screen: the UI at `demo/index.html`, then the account dashboard.

## 0:20–0:45 — Problem + idea

> "We built a tUSD8 smart account on QDay Aevum. A human principal funds it and registers an ERC-8004 identity for the agent. The key the agent uses is a scoped session key: capped, time-boxed, and tied to that identity."

On screen: identity + account contracts, `Session` struct.

## 0:45–1:35 — Core flow (live)

Run in order, narrating tx hashes:

1. `factory.createAccount()` — "one account per principal."
2. `identity.register()` + `setAgentAddress()` — "the agent's identity is bound to its runtime key."
3. `token.approve()` + `account.deposit(50)` — "funded with faucet tUSD8."
4. `account.issueSession(...)` — "20 total, 10 per transaction, 1 hour, human approval above 5."
5. `agent: account.payWithService(merchant, 4, ref)` — "small invoice settles fully autonomously."
6. `principal: account.approvePayment(agent, router, 8, 2)` — "large invoice: a single-use human approval."
7. `agent: account.payWithService(merchant, 8, ref)` — "and the agent settles it."

> "The router confirms the payee is ERC-8004 registered before it forwards tUSD8, and writes a reputation receipt for both sides."

## 1:35–2:05 — Failure paths (fast)

Use tests or call the buttons in the UI:

- 11 tUSD8 payment → "rejected by the per-tx cap."
- `vm.warp` past expiry → "expired keys stop working on their own."
- `revokeSession()` → "instant kill switch."
- Unregistered payee → "Confirmation of Payee rejects it."

## 2:05–2:35 — Results + close

> "Twelve tUSD8 settled, two verifiable receipts, identity-bound on both ends, and the key revoked. Everything is original, MIT-licensed, and reproducible from the repo. The same contracts can ship on mainnet with the official registries and ERC-4337 paymasters."

## Finalist version (3–5 min)

Add after 2:35: architecture diagram walkthrough, gas numbers from `forge test --gas-report`, and roadmap (subgraph indexing, recurrent allowances, multi-agent policies).
