/**
 * Offline walkthrough of the AegisPay flow. No wallet, no RPC, no keys.
 * Useful for judges who cannot connect to the testnet.
 * Run: node demo/simulate.mjs
 */
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const steps = [
  ["01", "Register ERC-8004 agent identity", "principal -> IdentityRegistry.register('ipfs://agent-card') => agentId #1"],
  ["02", "Bind runtime key to identity", "principal -> setAgentAddress(1, agent) => agent is authorized"],
  ["03", "Create + fund smart account", "factory.createAccount() => 0xAeg1... ; deposit 50 tUSD8"],
  ["04", "Issue scoped session key", "cap 20 / per-tx 10 / 1h / threshold 5 / verified payees only"],
  ["05", "Agent pays small invoice", "payWithService(merchant, 4, 0xinv1) => settled, 0x9f2a...c1"],
  ["06", "Human approval for large invoice", "approvePayment(agent, router, 8, nonce=2) => single-use receipt"],
  ["07", "Agent pays approved invoice", "payWithService(merchant, 8, 0xinv2) => settled, 0x71bd...e4"],
  ["08", "Reputation + audit trail", "getSummary(1) => 2 entries, avg 100; ServiceSettled x2"],
  ["09", "Kill switch", "revokeSession(agent) => agent can no longer spend"],
];

console.log("AegisPay — offline end-to-end simulation (Aevum testnet, 44005)\n");
for (const [id, title, detail] of steps) {
  console.log(`${id} | ${title}`);
  console.log(`   | ${detail}`);
  await sleep(220);
}
console.log("\nFor the live on-chain version with transaction hashes: cp .env.example .env && node --env-file=.env demo/agent-runner.mjs");
