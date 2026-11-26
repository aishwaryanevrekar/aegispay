// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AegisTestBase} from "./utils/AegisTestBase.sol";
import {PaymentRouter} from "../src/PaymentRouter.sol";

contract PaymentRouterTest is AegisTestBase {
    function testPayeeMustControlIdentity() public {
        vm.prank(outsider);
        vm.expectRevert(PaymentRouter.IdentityNotAuthorized.selector);
        router.registerMerchant("Fake Acme", merchantId);
    }

    function testSettleForwardsFundsAndWritesReputation() public {
        issueDefaultSession();
        bytes32 ref = keccak256("invoice-1001");

        vm.expectEmit(true, true, true, false, address(router));
        emit PaymentRouter.ServiceSettled(address(account), merchant, 4 * TOKEN_UNIT, ref, agentId);

        vm.prank(agent);
        account.payWithService(merchant, 4 * TOKEN_UNIT, ref);

        assertEq(token.balanceOf(merchant), 4 * TOKEN_UNIT);
        assertEq(router.totalSettled(), 4 * TOKEN_UNIT);
        assertEq(router.merchantPayments(merchant), 4 * TOKEN_UNIT);
        assertEq(router.merchantIdentity(merchant), merchantId);

        (uint256 count, uint256 total) = reputation.getSummary(agentId);
        assertEq(count, 1);
        assertEq(total, 100);
        (uint256 mCount, uint256 mTotal) = reputation.getSummary(merchantId);
        assertEq(mCount, 1);
        assertEq(mTotal, 100);
    }

    function testUnknownMerchantCannotReceiveSettlement() public {
        issueDefaultSession();
        vm.prank(agent);
        vm.expectRevert(PaymentRouter.UnknownMerchant.selector);
        account.payWithService(outsider, 4 * TOKEN_UNIT, bytes32("invoice-bad"));
        assertEq(token.balanceOf(outsider), 0);
        assertEq(token.balanceOf(address(account)), 200 * TOKEN_UNIT); // atomic revert
    }

    function testMultipleSettlementsAccumulate() public {
        issueDefaultSession();
        vm.startPrank(agent);
        account.payWithService(merchant, 4 * TOKEN_UNIT, bytes32("a"));
        account.payWithService(merchant, 6 * TOKEN_UNIT, bytes32("b"));
        vm.stopPrank();
        assertEq(router.totalSettled(), 10 * TOKEN_UNIT);
        assertEq(account.remainingBudget(agent), 40 * TOKEN_UNIT);
        (uint256 count,) = reputation.getSummary(agentId);
        assertEq(count, 2);
    }
}
