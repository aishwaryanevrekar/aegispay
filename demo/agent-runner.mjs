/**
 * AegisPay — end-to-end agent payment runner for the QDay Aevum testnet.
 * Original code, MIT licensed. TESTNET ONLY.
 *
 * Usage:
 *   cp .env.example .env   (fill addresses + testnet keys)
 *   node --env-file=.env demo/agent-runner.mjs
 */
import {
  createPublicClient, createWalletClient, http, parseUnits, keccak256, toHex, formatUnits,
} from "viem";
import { privateKeyToAccount } from "viem/accounts";

const RPC = process.env.AEVUM_RPC_URL ?? "https://rpc-test.qday.info";
const EXPLORER = process.env.EXPLORER_URL ?? "https://explorer-test.qday.info";
const CHAIN_ID = 44005;

const TUSD8 = process.env.TUSD8_ADDRESS ?? "0x456569838f1d43009A91ebA4263147Afd7233483";
const IDENTITY = process.env.IDENTITY_REGISTRY_ADDRESS;
const REPUTATION = process.env.REPUTATION_REGISTRY_ADDRESS;
const ROUTER = process.env.PAYMENT_ROUTER_ADDRESS;
const FACTORY = process.env.AEGIS_FACTORY_ADDRESS;

for (const [name, value] of Object.entries({ IDENTITY, REPUTATION, ROUTER, FACTORY })) {
  if (!value) throw new Error(`Missing ${name} in .env — deploy with forge script first.`);
}
if (!process.env.PRIVATE_KEY || !process.env.AGENT_PRIVATE_KEY || !process.env.MERCHANT_PRIVATE_KEY) {
  throw new Error("Missing testnet private keys in .env (never commit them).");
}

const abi = {
  token: [
    { type: "function", name: "approve", inputs: [{ name: "spender", type: "address" }, { name: "amount", type: "uint256" }], outputs: [{ type: "bool" }], stateMutability: "nonpayable" },
    { type: "function", name: "balanceOf", inputs: [{ name: "account", type: "address" }], outputs: [{ type: "uint256" }], stateMutability: "view" },
  ],
  factory: [
    { type: "function", name: "createAccount", inputs: [], outputs: [{ name: "account", type: "address" }], stateMutability: "nonpayable" },
    { type: "function", name: "accountOf", inputs: [{ name: "owner", type: "address" }], outputs: [{ type: "address" }], stateMutability: "view" },
  ],
  identity: [
    { type: "function", name: "register", inputs: [{ name: "uri", type: "string" }], outputs: [{ name: "agentId", type: "uint256" }], stateMutability: "nonpayable" },
    { type: "function", name: "setAgentAddress", inputs: [{ name: "agentId", type: "uint256" }, { name: "agent", type: "address" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "latestIdOf", inputs: [{ name: "owner", type: "address" }], outputs: [{ type: "uint256" }], stateMutability: "view" },
  ],
  router: [
    { type: "function", name: "registerMerchant", inputs: [{ name: "name", type: "string" }, { name: "identityId", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "totalSettled", inputs: [], outputs: [{ type: "uint256" }], stateMutability: "view" },
  ],
  account: [
    { type: "function", name: "deposit", inputs: [{ name: "amount", type: "uint256" }], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "issueSession", inputs: [
      { name: "agent", type: "address" }, { name: "agentId", type: "uint256" }, { name: "totalCap", type: "uint256" },
      { name: "perTxCap", type: "uint256" }, { name: "expiry", type: "uint256" }, { name: "recipient", type: "address" },
      { name: "approvalThreshold", type: "uint256" },
    ], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "payWithService", inputs: [
      { name: "merchant", type: "address" }, { name: "amount", type: "uint256" }, { name: "serviceRef", type: "bytes32" },
    ], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "approvePayment", inputs: [
      { name: "agent", type: "address" }, { name: "recipient", type: "address" }, { name: "amount", type: "uint256" }, { name: "nonce", type: "uint256" },
    ], outputs: [], stateMutability: "nonpayable" },
    { type: "function", name: "revokeSession", inputs: [{ name: "agent", type: "address" }], outputs: [], stateMutability: "nonpayable" },
  ],
  reputation: [
    { type: "function", name: "getSummary", inputs: [{ name: "agentId", type: "uint256" }], outputs: [
      { name: "count", type: "uint256" }, { name: "totalScore", type: "uint256" },
    ], stateMutability: "view" },
  ],
};

const chain = { id: CHAIN_ID, name: "Aevum Testnet", nativeCurrency: { name: "tQDAY", symbol: "tQDAY", decimals: 18 }, rpcUrls: { default: { http: [RPC] } } };
const publicClient = createPublicClient({ chain, transport: http(RPC, { retryCount: 4, retryDelay: 800 }) });
const wallet = (key) => createWalletClient({ account: privateKeyToAccount(key), chain, transport: http(RPC, { retryCount: 4, retryDelay: 800 }) });

const principalWallet = wallet(process.env.PRIVATE_KEY);
const agentWallet = wallet(process.env.AGENT_PRIVATE_KEY);
const merchantWallet = wallet(process.env.MERCHANT_PRIVATE_KEY);
const principal = principalWallet.account.address;
const agent = agentWallet.account.address;
const merchant = merchantWallet.account.address;

const logs = [];
function log(step, message, hash) {
  const line = `${step.padEnd(2)} | ${message}${hash ? ` | ${EXPLORER}/tx/${hash}` : ""}`;
  console.log(line);
  logs.push(line);
}

/** Retry wrapper: handles RPC hiccups and transient nonce errors. */
async function withRetry(label, fn, attempts = 3) {
  for (let i = 1; i <= attempts; i++) {
    try { return await fn(); }
    catch (error) {
      if (i === attempts) throw error;
      console.warn(`   ! ${label} failed (${i}/${attempts}): ${error.shortMessage ?? error.message}`);
      await new Promise((r) => setTimeout(r, 800 * i));
    }
  }
}

async function send(label, client, address, functionName, abi_, args) {
  const hash = await withRetry(label, () => client.writeContract({
    address, abi: abi_, functionName, args, account: client.account, chain,
  }));
  const receipt = await withRetry(`${label} receipt`, () => publicClient.waitForTransactionReceipt({ hash, timeout: 120_000 }));
  if (receipt.status !== "success") throw new Error(`${label} reverted: ${hash}`);
  log(label, `${functionName} confirmed in block ${receipt.blockNumber}`, hash);
  return { hash, receipt };
}

const sleep = (seconds) => Math.floor(Date.now() / 1000) + seconds;
const units = (n) => parseUnits(n, 6); // tUSD8 has 6 decimals on Aevum

async function main() {
  console.log(`AegisPay demo on ${chain.name} (${CHAIN_ID}) — principal ${principal}\n`);

  // 1. One account per principal, created through the factory.
  let account = await publicClient.readContract({ address: FACTORY, abi: abi.factory, functionName: "accountOf", args: [principal] });
  if (account === "0x0000000000000000000000000000000000000000") {
    await send("01", principalWallet, FACTORY, "createAccount", abi.factory, []);
    account = await publicClient.readContract({ address: FACTORY, abi: abi.factory, functionName: "accountOf", args: [principal] });
  }
  log("01", `AegisAccount ready: ${account}`);

  // 2. ERC-8004 agent identity, owned by principal, bound to agent runtime key.
  await send("02", principalWallet, IDENTITY, "register", abi.identity, ["ipfs://aegis-agent-card.json"]);
  const agentId = await publicClient.readContract({ address: IDENTITY, abi: abi.identity, functionName: "latestIdOf", args: [principal] });
  await send("02", principalWallet, IDENTITY, "setAgentAddress", abi.identity, [agentId, agent]);
  log("02", `Agent identity #${agentId} authorized for runtime key`);

  // 3. Merchant Confirmation-of-Payee registration (merchant signs).
  await send("03", merchantWallet, IDENTITY, "register", abi.identity, ["ipfs://acme-merchant-card.json"]);
  const merchantId = await publicClient.readContract({ address: IDENTITY, abi: abi.identity, functionName: "latestIdOf", args: [merchant] });
  await send("03", merchantWallet, IDENTITY, "setAgentAddress", abi.identity, [merchantId, merchant]);
  await send("03", merchantWallet, ROUTER, "registerMerchant", abi.router, ["Acme API", merchantId]);

  // 4. Fund the smart account with faucet tUSD8.
  await send("04", principalWallet, TUSD8, "approve", abi.token, [account, units("50")]);
  await send("04", principalWallet, account, "deposit", abi.account, [units("50")]);
  log("04", `Deposited 50 tUSD8 (balance ${formatUnits(await publicClient.readContract({ address: TUSD8, abi: abi.token, functionName: "balanceOf", args: [account] }), 6)})`);

  // 5. Issue a scoped key: 20 total, 10/tx, 1h expiry, 5-unit human-approval threshold.
  await send("05", principalWallet, account, "issueSession", abi.account,
    [agent, agentId, units("20"), units("10"), BigInt(sleep(3600)), "0x0000000000000000000000000000000000000000", units("5")]);
  log("05", "Session scoped: 20 cap / 10 per-tx / 1h / approval >5");

  // 6. Small payment runs fully autonomously.
  await send("06", agentWallet, account, "payWithService", abi.account, [merchant, units("4"), keccak256(toHex("invoice-2001"))]);

  // 7. High-value payment: human pre-approval (single use) then agent settles.
  //    Authorized recipient inside payWithService is the router.
  await send("07", principalWallet, account, "approvePayment", abi.account, [agent, ROUTER, units("8"), 2n]);
  await send("07", agentWallet, account, "payWithService", abi.account, [merchant, units("8"), keccak256(toHex("invoice-2002"))]);

  // 8. Verifiable receipts and reputation.
  const summary = await publicClient.readContract({ address: REPUTATION, abi: abi.reputation, functionName: "getSummary", args: [agentId] });
  const count = Array.isArray(summary) ? summary[0] : summary.count;
  const total = Array.isArray(summary) ? summary[1] : summary.totalScore;
  const settled = await publicClient.readContract({ address: ROUTER, abi: abi.router, functionName: "totalSettled" });
  log("08", `On-chain receipts: ${settled / 10n ** 6n} tUSD8 settled, ${count} feedback entries, avg ${Number(total) / Number(count || 1n)}`);

  // 9. Kill switch.
  await send("09", principalWallet, account, "revokeSession", abi.account, [agent]);
  log("09", "Session revoked — agent can no longer spend");

  console.log("\nDone. Paste this transcript + explorer links into your DoraHacks submission.");
}

main().catch((error) => { console.error("Demo failed:", error); process.exit(1); });
