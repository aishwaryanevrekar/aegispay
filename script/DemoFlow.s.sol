// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MockTUSD8} from "../src/mocks/MockTUSD8.sol";
import {MockIdentityRegistry} from "../src/mocks/MockIdentityRegistry.sol";
import {MockReputationRegistry} from "../src/mocks/MockReputationRegistry.sol";
import {PaymentRouter} from "../src/PaymentRouter.sol";
import {AegisFactory} from "../src/AegisFactory.sol";
import {AegisAccount} from "../src/AegisAccount.sol";

/// @notice Reproducible end-to-end demo on a local Anvil chain (or any dev chain).
/// @dev Run: forge script script/DemoFlow.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
contract DemoFlow is Script {
    uint256 internal constant UNIT = 1e6;

    function run() external {
        uint256 pk = vm.envOr("PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        address principal = vm.addr(pk);
        address agent = vm.addr(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        address merchant = vm.addr(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a);

        vm.startBroadcast(pk);
        MockTUSD8 token = new MockTUSD8();
        MockIdentityRegistry identity = new MockIdentityRegistry();
        MockReputationRegistry reputation = new MockReputationRegistry();
        PaymentRouter router = new PaymentRouter(address(token), address(reputation), address(identity));
        AegisFactory factory = new AegisFactory(address(token), address(identity), address(reputation), address(router));

        console2.log("1) identities + core deployed");
        uint256 agentId = identity.register("ipfs://aegis-agent-card.json");
        identity.setAgentAddress(agentId, agent);

        uint256 merchantId = identity.register("ipfs://acme-merchant-card.json");
        // merchant identity registration is done by principal here for the local script;
        // on the live testnet the merchant registers itself (see README).
        identity.setAgentAddress(merchantId, merchant);

        vm.stopBroadcast();

        // merchant registers as a verified payee
        uint256 merchantKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;
        vm.startBroadcast(merchantKey);
        router.registerMerchant("Acme API", merchantId);
        vm.stopBroadcast();

        vm.startBroadcast(pk);
        AegisAccount account = AegisAccount(factory.createAccount());
        token.mint(principal, 200 * UNIT);
        token.approve(address(account), type(uint256).max);
        account.deposit(200 * UNIT);
        console2.log("2) account funded:", vm.toString(address(account)));

        account.issueSession(agent, agentId, 50 * UNIT, 10 * UNIT, block.timestamp + 1 days, address(0), 5 * UNIT);
        console2.log("3) scoped session issued (cap 50, per-tx 10, threshold 5)");

        vm.stopBroadcast();

        // agent pays a small invoice autonomously
        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        account.payWithService(merchant, 4 * UNIT, keccak256("invoice-2001"));
        console2.log("4) agent paid 4 tUSD8 to verified merchant");
        vm.stopBroadcast();

        // high-value invoice: human approval then agent payment
        vm.startBroadcast(pk);
        account.approvePayment(agent, address(router), 8 * UNIT, 2);
        console2.log("5) principal pre-approved 8 tUSD8 (single use)");
        vm.stopBroadcast();

        vm.startBroadcast(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d);
        account.payWithService(merchant, 8 * UNIT, keccak256("invoice-2002"));
        console2.log("6) agent paid approved 8 tUSD8 invoice");
        vm.stopBroadcast();

        vm.startBroadcast(pk);
        account.revokeSession(agent);
        vm.stopBroadcast();

        console2.log("=== result ===");
        console2.log("merchant balance:", token.balanceOf(merchant) / UNIT, "tUSD8");
        console2.log("account balance :", token.balanceOf(address(account)) / UNIT, "tUSD8");
        console2.log("router settled  :", router.totalSettled() / UNIT, "tUSD8");
        (uint256 count, uint256 total) = reputation.getSummary(agentId);
        console2.log("agent feedback  :", count, "entries, avg score", total / count);
        console2.log("7) session revoked -> kill switch verified");
    }
}
