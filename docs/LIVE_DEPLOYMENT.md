# Live deployment — QDay Aevum Testnet (chain 44005)

All transactions below are confirmed on the official Aevum testnet using the official tUSD8 contract. Explorer: `https://explorer-test.qday.info`.

## Deployed contracts

| Contract | Address |
|---|---|
| tUSD8 (official) | `0x456569838f1d43009A91ebA4263147Afd7233483` |
| MockIdentityRegistry (ERC-8004 adapter) | `0xF84C2Ce6cB1cb4cE918Af894746F4be89b907aF0` |
| MockReputationRegistry (ERC-8004 adapter) | `0xD51742271A2612b4420D7b5f5618a08623941Ed6` |
| PaymentRouter | `0x66746dA1d7C23392C2CBBA102796a0AacBfBbF16` |
| AegisFactory | `0xf7C082C6e9cdF2ff0be93F56ddDCe73953dd12D2` |
| AegisAccount (principal) | `0xF2FB7fd948e34197509bbfc2B137D317e2c77622` |

Deploy script broadcast: `forge script script/Deploy.s.sol --rpc-url https://rpc-test.qday.info --broadcast` (chain 44005, successful).

## Roles

| Role | Address |
|---|---|
| Principal | `0x4F078d339eAa5C446C8dDE7e349D548e1eAbbaB7` |
| Agent (ERC-8004 identity #1) | `0xf4B70a55F076E5CCABDe6ccD38C6731a56adFaf5` |
| Merchant (ERC-8004 identity #2) | `0xeBaD55F7BF918767E7970eA369856131D7D488EB` |

## End-to-end transaction trail

| Step | Transaction |
|---|---|
| Create account | [`0x111e0b17…2913`](https://explorer-test.qday.info/tx/0x111e0b1745081f677f1970da23c2052872564398d408a629a8e614f8a6fb2913) |
| Register agent identity | [`0xe22e35d1…c2c4`](https://explorer-test.qday.info/tx/0xe22e35d1e8e74c4fdda7e78f85f56d451257054f8fac0bfa0cd0ba587e76c2c4) |
| Bind agent runtime key | [`0x377a29ac…ef9b`](https://explorer-test.qday.info/tx/0x377a29acf3a69e82f64ce362b6280549b2f4b7c6af66bdfd4f4827925193ef9b) |
| Register merchant identity | [`0x29076be2…b513`](https://explorer-test.qday.info/tx/0x29076be28d892fbeb6abd0744266a51286a8db161a01dee7c47c0c5b83e3b513) |
| Bind merchant runtime key | [`0x73332dd0…19a18`](https://explorer-test.qday.info/tx/0x73332dd0fb2befcf152333da582dc33589bae92eb84cf839ebae35e2149a18ec) |
| Confirmation of Payee registration | [`0xc7dae6d8…1b`](https://explorer-test.qday.info/tx/0xc7dae6d8e1014ec6bf85146b02aff520e0d271639a20f853269f307928fe511b) |
| Approve + deposit 5 tUSD8 | [`0x81c000c5…5e`](https://explorer-test.qday.info/tx/0x81c000c59f72c40d8d2b5bd68e554891aec1a95fb123da23577c12e21de6c25e) |
| Issue scoped session (5 cap / 3 per-tx / 1h / approval >2) | [`0xd0563fad…df0`](https://explorer-test.qday.info/tx/0xd0563fadaa6268d257e3f5c9909106c7876d8080afcfa60da45051e8284b7df0) |
| Agent pays 1 tUSD8 autonomously | [`0x7685d8cd…0f4`](https://explorer-test.qday.info/tx/0x7685d8cda27e70eadb9fa3edc18f8407809cd7192e49e0bf9c490bca186120f4) |
| Human single-use approval for 3 tUSD8 | [`0xe23ebe1a…9ca`](https://explorer-test.qday.info/tx/0xe23ebe1a97b869e2bc647659913fed49fbd93c82912b88aa44ccb1d63436e9ca) |
| Agent pays approved 3 tUSD8 | [`0xd6fda851…0a9`](https://explorer-test.qday.info/tx/0xd6fda851a9576252de21bd2f681da3db729b7e127e48b03a06f42cbf80106a9a) |
| Revoke session (kill switch) | [`0x1fc3dda8…fcc`](https://explorer-test.qday.info/tx/0x1fc3dda8e8ee60fbec9a116ded77dcea2e4253250e0316ab0df970902162bfcc) |

## Verified result

- `4 tUSD8` settled to the verified merchant from the smart account
- `2` reputation feedback entries on the agent identity, average score `100`
- Session revoked — agent can no longer spend

Reproduce the reads:

```bash
cast call 0x66746dA1d7C23392C2CBBA102796a0AacBfBbF16 'totalSettled()(uint256)' --rpc-url https://rpc-test.qday.info
cast call 0xD51742271A2612b4420D7b5f5618a08623941Ed6 'getSummary(uint256)(uint256,uint256)' 1 --rpc-url https://rpc-test.qday.info
cast call 0x456569838f1d43009A91ebA4263147Afd7233483 'balanceOf(address)(uint256)' 0xeBaD55F7BF918767E7970eA369856131D7D488EB --rpc-url https://rpc-test.qday.info
```

> Contract verification is not yet available on the Aevum explorer. Source code is this public repository; deployment is proven by the broadcast files and the transaction links above.
