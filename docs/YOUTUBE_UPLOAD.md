# YouTube upload kit

The videos are hosted **inside this repository** (no external hosting) and can be downloaded from:

**Full video (2:19):** https://raw.githubusercontent.com/aishwaryanevrekar/aegispay/main/demo/AegisPay-Demo.mp4
**Highlights / Short (1:01):** https://raw.githubusercontent.com/aishwaryanevrekar/aegispay/main/demo/AegisPay-Highlights.mp4
**Custom thumbnail (1280×720):** https://raw.githubusercontent.com/aishwaryanevrekar/aegispay/main/demo/thumbnail.png

## Steps

1. Open https://studio.youtube.com → **Create → Upload videos**
2. Upload `demo/AegisPay-Demo.mp4` (download from the raw link above if needed)
3. Paste the **title**, **full description** and **tags** below
4. Set **Thumbnail → Custom thumbnail** and upload `demo/thumbnail.png`
5. Category: **Science & technology** · Language: **English** · Visibility: **Public**
6. Click **Next** through the remaining steps and **Publish**
7. Paste the final YouTube URL into the DoraHacks submission and `docs/SUBMISSION.md`

## Title

```
AegisPay — Agentic Stablecoin Payments on QDay Aevum | Aevum Builder Challenge #1
```

## Full description (copy everything between the lines)

```
AegisPay lets an AI agent pay tUSD8 invoices on the QDay Aevum testnet — but only inside a budget, a time window and a payee allowlist. Large payments need a human's single-use approval, and one transaction revokes everything. Built from scratch for Aevum Builder Challenge #1 by Aishwarya Nevrekar. 100% original, MIT licensed, open source.

WHAT IT DOES
1. The principal registers an ERC-8004 identity for the agent and binds its runtime key.
2. A factory creates one tUSD8 smart account per principal, funded from the faucet.
3. The principal issues a scoped session key: total cap, per-transaction cap, expiry, optional payee lock, and an approval threshold.
4. The agent calls payWithService(merchant, amount, invoiceId) to settle a tUSD8 invoice.
5. The router enforces Confirmation of Payee — the merchant must control an ERC-8004 identity — then forwards tUSD8 and writes reputation receipts for both agent and merchant.
6. Payments above the threshold require a single-use human approval.
7. revokeSession is an instant kill switch.

LIVE ON-CHAIN RESULTS (QDay Aevum testnet, chain 44005)
✅ 4 tUSD8 settled to a verified merchant
✅ 2 settlement receipts, agent reputation score 100
✅ 12 confirmed transactions with public explorer links
✅ Session revoked after the demo
✅ 21/21 Foundry tests passing, including all failure paths

TECH STACK
Solidity 0.8.24 · Foundry (evm_version = shanghai, required on Aevum) · viem · ERC-8004-compatible identity and reputation adapters · ERC-4337-style smart account · official tUSD8 (0x456569838f1d43009A91ebA4263147Afd7233483, 6 decimals).

SAFETY
Least-privilege scoped sessions, strict spend caps, session expiry, payee allowlists, identity binding, single-use human approvals, instant revocation, replay protection, checks-effects-interactions, and a PaymentExecuted nonce for a gap-free on-chain audit trail. The agent never holds the funds and cannot call arbitrary contracts.

TRACKS & JUDGING
Combines Native AI Assistants, Confirmation of Payee and Decentralized Payments. Built around innovation, technical integration, real-world utility and safety — the heaviest-weighted judging criteria.

CHAPTERS
00:00 Intro — let agents pay, keep the keys
00:14 The problem with agent wallets
00:40 The idea: identity-bound scoped session keys
01:05 Live on QDay Aevum (chain 44005)
01:40 The nine-step on-chain flow and safety
01:58 Verified results and kill switch
02:08 Open source, repo and next steps

LINKS
💻 Source code: https://github.com/aishwaryanevrekar/aegispay
📄 README: https://github.com/aishwaryanevrekar/aegispay#readme
🏗️ Architecture + threat model: https://github.com/aishwaryanevrekar/aegispay/blob/main/docs/ARCHITECTURE.md
⛓️ Live deployment + all tx hashes: https://github.com/aishwaryanevrekar/aegispay/blob/main/docs/LIVE_DEPLOYMENT.md
🎬 Script + demo guide: https://github.com/aishwaryanevrekar/aegispay/blob/main/docs/DEMO_SCRIPT.md
📝 Paste-ready submission text: https://github.com/aishwaryanevrekar/aegispay/blob/main/docs/SUBMISSION.md
🏆 Hackathon: https://dorahacks.io/hackathon/qday/detail
🔍 Explorer: https://explorer-test.qday.info

Presented by Aishwarya Nevrekar. Narrated with an Indian English female voice; the contracts, on-chain results, visuals and code are all from the public repository.

#Aevum #QDay #tUSD8 #AevumBuilderChallenge #DoraHacks #Hackathon #Solidity #Foundry #EVM #SmartAccount #AccountAbstraction #ERC8004 #SessionKeys #AgenticPayments #AIAgents #Stablecoin #ConfirmationOfPayee #DecentralizedPayments #Web3 #DeFi #Payments #SmartContracts #OpenSource #MIT #Blockchain
```

## Tags

```
Aevum, QDay, tUSD8, Aevum Builder Challenge, DoraHacks, hackathon, Solidity, Foundry, EVM, smart account, account abstraction, ERC-8004, session keys, agentic payments, AI agents, stablecoin, confirmation of payee, decentralized payments, Web3, DeFi, payments, smart contracts, open source, MIT, blockchain hackathon, agentic commerce, programmable payments, post quantum, QDay testnet
```

## Shorts version

Upload `demo/AegisPay-Highlights.mp4` as a Short with title:

```
AI agents can pay — but only with guardrails 🤖💸 #Aevum #QDay #Web3
```

Use the same tags and the custom thumbnail. Pin a comment with the source code link: https://github.com/aishwaryanevrekar/aegispay
