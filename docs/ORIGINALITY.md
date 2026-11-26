# Originality & open source

- Every Solidity contract, test, script and UI file in this repository was **written from scratch for Aevum Builder Challenge #1**. No template, sample project, or another team's code was copied.
- The only third-party dependency is **forge-std** (Foundry's standard test utility library, MIT licensed), installed as a git submodule via `make install`, plus **viem** (MIT) for the live runner.
- The ERC-8004 and ERC-20 "interfaces" here are minimal declarations written for this project, not copied source code. On-chain adapters are original implementations.
- The entire repository is **MIT licensed** (see `LICENSE`). Anyone may use, modify and redistribute it with attribution.
- No private keys, API keys, or `.env` files are included. `.env.example` contains placeholder values only, and `.env` is git-ignored.
