// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LoyaltyPoints} from "../contracts/LoyaltyPoints.sol";
import {AchievementBadges} from "../contracts/AchievementBadges.sol";
import {StreakTracker} from "../contracts/StreakTracker.sol";
import {TierSystem} from "../contracts/TierSystem.sol";

/// Foundry twin of test/Session3.test.js — same behaviours, Solidity-native.
/// Run:  forge test -vv
contract Session3Test is Test {
    LoyaltyPoints loyalty;
    AchievementBadges badges;
    StreakTracker streaks;
    TierSystem tiers;
    address alice = address(0xA11CE);

    function setUp() public {
        loyalty = new LoyaltyPoints();           // this test contract = issuer
        badges = new AchievementBadges(address(loyalty));
        streaks = new StreakTracker();
        tiers = new TierSystem(address(loyalty));
    }

    function test_EarnRedeemLiability() public {
        loyalty.earnPoints(alice, 1500, "purchase");
        assertEq(loyalty.pointsOf(alice), 1500);

        vm.prank(alice);
        loyalty.redeemPoints(200, "coffee-voucher");
        assertEq(loyalty.pointsOf(alice), 1300);
        assertEq(loyalty.outstandingLiability(), 1300);
    }

    function test_OnlyIssuerCanEarn() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Not the issuer"));
        loyalty.earnPoints(alice, 1, "hack");
    }

    function test_BadgeSelfClaimReadsLedger() public {
        badges.addBadge("First 1000", 1000);

        vm.prank(alice);
        vm.expectRevert(bytes("Threshold not met"));
        badges.claimBadge(0);

        loyalty.earnPoints(alice, 1000, "purchases");
        vm.prank(alice);
        badges.claimBadge(0);
        assertTrue(badges.earned(alice, 0));
    }

    function test_StreakGraceAndRecord() public {
        vm.warp(1_000_000);                      // set a sane starting time
        vm.startPrank(alice);
        streaks.checkIn();                       // day 1
        vm.warp(block.timestamp + 1 days);
        streaks.checkIn();                       // day 2 (within grace)
        (uint32 cur,,) = streaks.streakOf(alice);
        assertEq(cur, 2);

        vm.warp(block.timestamp + 3 days);       // gone too long
        streaks.checkIn();                       // reset
        (uint32 cur2, uint32 longest,) = streaks.streakOf(alice);
        assertEq(cur2, 1);
        assertEq(longest, 2);                    // the record is forever
        vm.stopPrank();
    }

    function test_TiersFollowBalance() public {
        assertEq(tiers.tierOf(alice), 0);
        loyalty.earnPoints(alice, 1000, "a");
        assertEq(tiers.tierOf(alice), 1);        // Silver
        loyalty.earnPoints(alice, 19000, "b");
        assertEq(tiers.tierOf(alice), 3);        // Platinum
    }
}
