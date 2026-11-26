// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MockTUSD8} from "../../src/mocks/MockTUSD8.sol";
import {MockIdentityRegistry} from "../../src/mocks/MockIdentityRegistry.sol";
import {MockReputationRegistry} from "../../src/mocks/MockReputationRegistry.sol";
import {PaymentRouter} from "../../src/PaymentRouter.sol";
import {AegisFactory} from "../../src/AegisFactory.sol";
import {AegisAccount} from "../../src/AegisAccount.sol";

/// @notice Shared fixture: principal + ERC-8004 agent + verified ERC-8004 merchant.
contract AegisTestBase is Test {
    uint256 internal constant TOKEN_UNIT = 1e6; // tUSD8 has 6 decimals on Aevum

    MockTUSD8 internal token;
    MockIdentityRegistry internal identity;
    MockReputationRegistry internal reputation;
    PaymentRouter internal router;
    AegisFactory internal factory;
    AegisAccount internal account;

    address internal principal = makeAddr("principal");
    address internal agent = makeAddr("agent");
    address internal merchant = makeAddr("merchant");
    address internal outsider = makeAddr("outsider");
    uint256 internal agentId;
    uint256 internal merchantId;

    function setUp() public virtual {
        token = new MockTUSD8();
        identity = new MockIdentityRegistry();
        reputation = new MockReputationRegistry();
        router = new PaymentRouter(address(token), address(reputation), address(identity));
        factory = new AegisFactory(address(token), address(identity), address(reputation), address(router));

        vm.prank(principal);
        account = AegisAccount(factory.createAccount());

        token.mint(principal, 1_000 * TOKEN_UNIT);

        vm.startPrank(principal);
        agentId = identity.register("ipfs://aegis-agent-card.json");
        identity.setAgentAddress(agentId, agent);
        token.approve(address(account), type(uint256).max);
        account.deposit(200 * TOKEN_UNIT);
        vm.stopPrank();

        vm.startPrank(merchant);
        merchantId = identity.register("ipfs://acme-merchant-card.json");
        identity.setAgentAddress(merchantId, merchant);
        router.registerMerchant("Acme API", merchantId);
        vm.stopPrank();

        vm.label(address(account), "AegisAccount");
        vm.label(address(router), "PaymentRouter");
    }

    function issueDefaultSession() internal {
        vm.prank(principal);
        account.issueSession(agent, agentId, 50 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 0);
    }

    function issueSessionFor(
        address agent_,
        uint256 totalCap_,
        uint256 perTxCap_,
        uint256 expiry_,
        address recipient_,
        uint256 threshold_
    ) internal {
        vm.prank(principal);
        account.issueSession(agent_, agentId, totalCap_, perTxCap_, expiry_, recipient_, threshold_);
    }
}
