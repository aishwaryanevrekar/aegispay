// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AegisTestBase} from "./utils/AegisTestBase.sol";
import {AegisAccount} from "../src/AegisAccount.sol";

/// @notice Full happy path exactly as the demo runner performs it on Aevum.
contract IntegrationTest is AegisTestBase {
    function testEndToEndFlow() public {
        // 1. identities already registered in fixture (principal->agent, merchant->merchant)
        assertTrue(identity.isAuthorized(agentId, agent));
        assertTrue(identity.isAuthorized(merchantId, merchant));
        assertEq(identity.ownerOf(agentId), principal);

        // 2. account created by factory and funded with tUSD8
        assertEq(factory.accountOf(principal), address(account));
        assertEq(token.balanceOf(address(account)), 200 * TOKEN_UNIT);

        // 3. scoped session: 50 cap, 10/tx, 1 day, verified payees only, 5-unit approval threshold
        vm.prank(principal);
        account.issueSession(agent, agentId, 50 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 5 * TOKEN_UNIT);
        assertTrue(account.isSessionValid(agent));

        // 4. agent pays a small invoice autonomously (under threshold)
        vm.prank(agent);
        account.payWithService(merchant, 4 * TOKEN_UNIT, keccak256("invoice-2001"));
        assertEq(token.balanceOf(merchant), 4 * TOKEN_UNIT);

        // 5. high-value invoice: human approves once, then agent pays
        vm.prank(principal);
        account.approvePayment(agent, address(router), 8 * TOKEN_UNIT, 2);
        vm.prank(agent);
        account.payWithService(merchant, 8 * TOKEN_UNIT, keccak256("invoice-2002"));
        assertEq(token.balanceOf(merchant), 12 * TOKEN_UNIT);
        assertEq(token.balanceOf(address(account)), 188 * TOKEN_UNIT);

        // 6. receipts + reputation are verifiable on chain
        assertEq(router.totalSettled(), 12 * TOKEN_UNIT);
        (uint256 count, uint256 total) = reputation.getSummary(agentId);
        assertEq(count, 2);
        assertEq(total, 200);

        // 7. principal retains sovereignty: instant kill switch
        vm.prank(principal);
        account.revokeSession(agent);
        assertFalse(account.isSessionValid(agent));
        vm.prank(agent);
        vm.expectRevert(AegisAccount.SessionInactive.selector);
        account.pay(merchant, 1 * TOKEN_UNIT);
    }
}
