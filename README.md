# AegisPay — Policy-Guarded Agentic Stablecoin Payments

**Aevum Builder Challenge #1 (QDay) — original, MIT-licensed, open-source build.**

AegisPay lets a human principal delegate **limited, revocable payment authority** to an autonomous AI agent on the QDay Aevum testnet. The agent pays verified merchants in **tUSD8** through a smart account whose session keys enforce spend caps, expiry, payee allowlists, ERC-8004 identity binding, single-use human approval for large payments, and an instant kill switch. Every settlement writes an on-chain reputation receipt.

> Work in progress — docs, UI and deployment transcript are being added in later commits.

## Stack

- Solidity 0.8.24 / Foundry (`evm_version = shanghai`, required on Aevum)
- viem for the live testnet agent runner
- ERC-8004-compatible identity + reputation adapters, ERC-4337-style smart account

## Quick start

```bash
make install   # install forge-std submodule
make test      # 21 tests covering caps, expiry, revocation, payee checks, approvals
make demo      # local Anvil end-to-end demo
```

## Network

| Item | Value |
|---|---|
| Network | QDay Aevum Testnet |
| Chain ID | 44005 |
| RPC | `https://rpc-test.qday.info` |
| Explorer | `https://explorer-test.qday.info` |
| tUSD8 | `0x456569838f1d43009A91ebA4263147Afd7233483` (6 decimals) |
| Faucet | `https://faucet.qday.info/en` |

## License

MIT — see [LICENSE](LICENSE). All code is written from scratch for this hackathon.
