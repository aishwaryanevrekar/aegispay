# DoraHacks submission (ready to paste)

**Project name:** AegisPay — Policy-Guarded Agentic Stablecoin Payments

**One-liner:** A tUSD8 smart account with identity-bound, scoped session keys so AI agents can pay verified merchants — with caps, expiry, human approval and an instant kill switch.

**Repository:** `https://github.com/aishwaryanevrekar/aegispay` (public, MIT)

**Demo:** [`demo/AegisPay-Demo.mp4`](../demo/AegisPay-Demo.mp4) (2:19 narrated video, Indian English female voice) + [`demo/AegisPay-Highlights.mp4`](../demo/AegisPay-Highlights.mp4) (1:01 safety/results highlights) + `demo/index.html` (interactive UI) + `docs/DEMO_SCRIPT.md` (script) + `demo/agent-runner.mjs` (live testnet runner printing tx hashes). Video credit: Aishwarya Nevrekar.

**Live deployment:** [`docs/LIVE_DEPLOYMENT.md`](LIVE_DEPLOYMENT.md) — deployed contracts, roles and 12 confirmed Aevum transactions with explorer links.

## Problem

Autonomous agents need to pay for APIs and services, but handing one a regular private key means handing over the entire balance. Prompt injection, runaway loops, or a leaked key can drain funds. Merchants also have no way to confirm that the payer is a legitimate, identity-bound agent.

## Solution

- An **AegisAccount** holds tUSD8 for a human principal.
- The principal registers an **ERC-8004 identity** for the agent and binds its runtime key.
- A **scoped session key** grants limited authority: total cap, per-tx cap, expiry, payee lock, identity binding.
- Payments above a threshold require a **single-use human approval**.
- The **PaymentRouter** enforces Confirmation of Payee and settles tUSD8 to registered merchants, writing reputation receipts for agent and merchant.
- The principal can **revoke** the key instantly.

## Aevum integration evidence

- Contracts deployed/broadcast against **QDay Aevum Testnet**, chain ID **44005**, using official **tUSD8** `0x456569838f1d43009A91ebA4263147Afd7233483`.
- Compiled with `evm_version = "shanghai"` per the starter kit's Aevum gotcha.
- ERC-8004-compatible identity + reputation adapters; swap in official registries by config.
- **Live run complete:** 4 tUSD8 settled across two invoices, 2 reputation receipts, session revoked. Transaction links in [`docs/LIVE_DEPLOYMENT.md`](LIVE_DEPLOYMENT.md).

## Submission checklist

- [x] Public repo, opens logged out
- [x] No secrets, `.env` ignored, example values only
- [x] README with setup, architecture, env spec, addresses, reproduction
- [x] Contracts target Aevum testnet only, test tokens only
- [x] 21 Foundry tests including failure paths
- [x] Demo video script + interactive UI
- [x] Live deployment tx hashes and addresses published in `docs/LIVE_DEPLOYMENT.md`

## YouTube

Use [`docs/YOUTUBE_UPLOAD.md`](YOUTUBE_UPLOAD.md) for the ready-to-paste title, full description, tags and thumbnail instructions. After publishing, paste the YouTube URL here and into the DoraHacks submission.
