// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AegisTestBase} from "./utils/AegisTestBase.sol";
import {AegisAccount} from "../src/AegisAccount.sol";

contract AegisAccountTest is AegisTestBase {
    function testFixtureIsFunded() public view {
        assertEq(token.balanceOf(address(account)), 200 * TOKEN_UNIT);
        assertEq(account.owner(), principal);
    }

    function testOwnerCanIssueSession() public {
        issueDefaultSession();
        assertTrue(account.isSessionValid(agent));
        assertEq(account.remainingBudget(agent), 50 * TOKEN_UNIT);

        (bool active, uint256 cap, uint256 spent, uint256 perTx, uint256 expiry,, bool locked, uint256 id, uint256 threshold, uint256 nonce) =
            account.sessions(agent);
        assertTrue(active);
        assertEq(cap, 50 * TOKEN_UNIT);
        assertEq(spent, 0);
        assertEq(perTx, 10 * TOKEN_UNIT);
        assertGt(expiry, block.timestamp);
        assertFalse(locked);
        assertEq(id, agentId);
        assertEq(threshold, 0);
        assertEq(nonce, 0);
    }

    function testAgentCanPayWithinCap() public {
        issueDefaultSession();
        vm.prank(agent);
        account.pay(merchant, 5 * TOKEN_UNIT);

        assertEq(token.balanceOf(merchant), 5 * TOKEN_UNIT);
        assertEq(token.balanceOf(address(account)), 195 * TOKEN_UNIT);
        assertEq(account.remainingBudget(agent), 45 * TOKEN_UNIT);
        (
            ,
            ,
            uint256 spent,
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 nonce
        ) = account.sessions(agent);
        assertEq(spent, 5 * TOKEN_UNIT);
        assertEq(nonce, 1);
    }

    function testCannotExceedPerTxCap() public {
        issueDefaultSession();
        vm.prank(agent);
        vm.expectRevert(AegisAccount.AmountExceedsPerTxCap.selector);
        account.pay(merchant, 11 * TOKEN_UNIT);
    }

    function testCannotExceedTotalCap() public {
        issueSessionFor(agent, 20 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 0);
        vm.startPrank(agent);
        account.pay(merchant, 10 * TOKEN_UNIT);
        account.pay(merchant, 10 * TOKEN_UNIT);
        vm.expectRevert(AegisAccount.CapExceeded.selector);
        account.pay(merchant, 1 * TOKEN_UNIT);
        vm.stopPrank();
    }

    function testExpiredSessionReverts() public {
        issueDefaultSession();
        vm.warp(block.timestamp + 1 days + 1);
        assertEq(account.remainingBudget(agent), 0);
        vm.prank(agent);
        vm.expectRevert(AegisAccount.SessionExpired.selector);
        account.pay(merchant, 1 * TOKEN_UNIT);
    }

    function testRevokedSessionRevertsInstantly() public {
        issueDefaultSession();
        vm.prank(principal);
        account.revokeSession(agent);
        assertFalse(account.isSessionValid(agent));
        vm.prank(agent);
        vm.expectRevert(AegisAccount.SessionInactive.selector);
        account.pay(merchant, 1 * TOKEN_UNIT);
    }

    function testRecipientLockIsEnforced() public {
        issueSessionFor(agent, 50 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, merchant, 0);
        vm.startPrank(agent);
        vm.expectRevert(AegisAccount.RecipientNotAllowed.selector);
        account.pay(outsider, 1 * TOKEN_UNIT);
        account.pay(merchant, 2 * TOKEN_UNIT);
        vm.stopPrank();
        assertEq(token.balanceOf(outsider), 0);
    }

    function testUnauthorizedAgentCannotPay() public {
        issueDefaultSession();
        vm.prank(outsider);
        vm.expectRevert(AegisAccount.SessionInactive.selector);
        account.pay(merchant, 1 * TOKEN_UNIT);
    }

    function testIdentityMustAuthorizeAgent() public {
        vm.prank(principal);
        vm.expectRevert(AegisAccount.IdentityNotAuthorized.selector);
        account.issueSession(outsider, agentId, 10 * TOKEN_UNIT, 1 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 0);
    }

    function testIdentityMustBeOwnedByPrincipal() public {
        vm.startPrank(outsider);
        uint256 foreignId = identity.register("ipfs://foreign.json");
        identity.setAgentAddress(foreignId, outsider);
        vm.stopPrank();

        vm.prank(principal);
        vm.expectRevert(AegisAccount.IdentityOwnerMismatch.selector);
        account.issueSession(outsider, foreignId, 10 * TOKEN_UNIT, 1 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 0);
    }

    function testHighValuePaymentRequiresHumanApproval() public {
        issueSessionFor(agent, 50 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 5 * TOKEN_UNIT);

        vm.prank(agent);
        vm.expectRevert(AegisAccount.ApprovalRequired.selector);
        account.pay(merchant, 8 * TOKEN_UNIT);

        vm.startPrank(principal);
        account.approvePayment(agent, merchant, 8 * TOKEN_UNIT, 1);
        vm.expectRevert(AegisAccount.ApprovalAlreadyUsed.selector);
        account.approvePayment(agent, merchant, 8 * TOKEN_UNIT, 1); // duplicate before use
        vm.stopPrank();

        vm.prank(agent);
        account.pay(merchant, 8 * TOKEN_UNIT);
        assertEq(token.balanceOf(merchant), 8 * TOKEN_UNIT);
    }

    function testLowValuePaymentNeedsNoApproval() public {
        issueSessionFor(agent, 50 * TOKEN_UNIT, 10 * TOKEN_UNIT, block.timestamp + 1 days, address(0), 5 * TOKEN_UNIT);
        vm.prank(agent);
        account.pay(merchant, 5 * TOKEN_UNIT);
        assertEq(token.balanceOf(merchant), 5 * TOKEN_UNIT);
    }

    function testOwnerRetainsDirectControl() public {
        vm.prank(principal);
        account.pay(merchant, 3 * TOKEN_UNIT);
        assertEq(token.balanceOf(merchant), 3 * TOKEN_UNIT);
    }

    function testNonOwnerCannotIssueOrRevoke() public {
        vm.prank(outsider);
        vm.expectRevert(AegisAccount.Unauthorized.selector);
        account.revokeSession(agent);
    }

    function testEmergencyWithdraw() public {
        vm.prank(principal);
        account.emergencyWithdraw(principal, 200 * TOKEN_UNIT);
        assertEq(token.balanceOf(address(account)), 0);
        assertEq(token.balanceOf(principal), 1_000 * TOKEN_UNIT);
    }
}
