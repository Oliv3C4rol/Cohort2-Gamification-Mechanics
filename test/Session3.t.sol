// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// IMPORT: Foundry's Test framework for unit testing
// Test is the base contract for writing Solidity tests
import {Test} from "forge-std/Test.sol";

// IMPORT: All gamification contracts to test
import {LoyaltyPoints} from "../contracts/LoyaltyPoints.sol";
import {AchievementBadges} from "../contracts/AchievementBadges.sol";
import {StreakTracker} from "../contracts/StreakTracker.sol";
import {TierSystem} from "../contracts/TierSystem.sol";

/// @title Session3Test — Comprehensive test suite for gamification system
/// @notice Foundry native tests demonstrating all gamification mechanics
/// 
/// TESTING APPROACH:
/// This test suite verifies that our gamification contracts:
/// 1. Execute core functionality correctly
/// 2. Enforce security constraints (permissions)
/// 3. Handle edge cases (grace periods, records)
/// 4. Maintain data integrity across the system
/// 5. Work together as a cohesive gamification platform
///
/// RUN COMMAND:
///   forge test -vv    (verbose output showing all assertions)
///
/// TEACHING POINT: Tests are DOCUMENTATION - they show exactly how
/// to use the contracts and what behaviors are guaranteed.
contract Session3Test is Test {
    // STATE: Contract instances for testing
    // We deploy fresh instances in setUp() for each test
    LoyaltyPoints loyalty;
    AchievementBadges badges;
    StreakTracker streaks;
    TierSystem tiers;
    
    // TEST ACTOR: A test address representing a customer
    // We use this address to simulate customer interactions
    // 0xA11CE is a memorable hex pattern representing "Alice"
    address alice = address(0xA11CE);

    /// @notice Setup function - runs before each test
    /// Creates fresh instances of all contracts for test isolation
    /// TEACHING POINT: setUp() ensures tests don't interfere with each other.
    /// Each test gets a clean slate.
    function setUp() public {
        // CREATE: Deploy a new LoyaltyPoints contract
        // In tests, the test contract itself becomes the "issuer"
        // This allows us to call earnPoints() without special permission tricks
        loyalty = new LoyaltyPoints();           // this test contract = issuer
        
        // CREATE: Deploy AchievementBadges, passing the loyalty contract address
        // This demonstrates contract composition - one contract depends on another
        badges = new AchievementBadges(address(loyalty));
        
        // CREATE: Deploy StreakTracker independently
        // No dependencies needed - streaks work standalone
        streaks = new StreakTracker();
        
        // CREATE: Deploy TierSystem, passing the loyalty contract address
        // TierSystem reads point balances to determine tier levels
        tiers = new TierSystem(address(loyalty));
    }

    /// @notice TEST 1: Core loyalty cycle - earn points, redeem points, track liability
    /// TEACHING POINT: This tests the fundamental loyalty loop:
    /// Action → Earn Points → Redeem Points → Burn Points
    function test_EarnRedeemLiability() public {
        // ACTION 1: Customer earns 1500 points for a purchase
        // The test contract (as issuer) credits Alice's account
        loyalty.earnPoints(alice, 1500, "purchase");
        
        // VERIFY: Check Alice's balance immediately after earning
        // This tests that earnPoints() correctly updates the ledger
        assertEq(loyalty.pointsOf(alice), 1500);

        // ACTION 2: Alice spends 200 of her points on a reward
        // vm.prank() simulates calling from Alice's address
        // This tests customer-initiated spending (no permission gate)
        vm.prank(alice);
        loyalty.redeemPoints(200, "coffee-voucher");
        
        // VERIFY: Check that Alice's balance decreased correctly
        // 1500 - 200 = 1300 remaining points
        assertEq(loyalty.pointsOf(alice), 1300);
        
        // VERIFY: Check outstanding liability (points still owed)
        // Outstanding = totalIssued - totalRedeemed = 1500 - 200 = 1300
        // This matters for business accounting and budgeting
        assertEq(loyalty.outstandingLiability(), 1300);
    }

    /// @notice TEST 2: Permission gate - only the issuer can award points
    /// TEACHING POINT: Security test - verify authorization rules.
    /// Anyone (including Alice) trying to award points to themselves
    /// should be rejected by the "Not the issuer" check.
    function test_OnlyIssuerCanEarn() public {
        // ACTION: Try to call earnPoints() as Alice instead of the issuer
        // vm.prank() makes the call appear to come from Alice
        vm.prank(alice);
        
        // EXPECT: The call should fail with "Not the issuer" error
        // vm.expectRevert() verifies that an error was thrown
        vm.expectRevert(bytes("Not the issuer"));
        
        // ATTEMPT: Try to award points to herself (should fail)
        // This prevents fraud - only the business can issue points
        loyalty.earnPoints(alice, 1, "hack");
    }

    /// @notice TEST 3: Self-claim badges - customers can claim if they meet the threshold
    /// TEACHING POINT: This demonstrates the AUTONOMY gamification pattern.
    /// Customers can claim achievements on their own without admin approval.
    function test_BadgeSelfClaimReadsLedger() public {
        // SETUP: Create a badge requiring 1000 points to self-claim
        // badgeId = 0 (first badge in the array)
        // threshold = 1000 (unlock condition)
        badges.addBadge("First 1000", 1000);

        // TEST: Alice tries to claim before meeting threshold
        vm.prank(alice);
        
        // EXPECT: Should fail - she hasn't earned enough points yet
        vm.expectRevert(bytes("Threshold not met"));
        
        // ATTEMPT: Claim the badge (should fail)
        badges.claimBadge(0);

        // ACTION: Issuer awards Alice 1000 points (meeting the threshold)
        // Now she qualifies for the "First 1000" badge
        loyalty.earnPoints(alice, 1000, "purchases");
        
        // ACTION: Alice claims the badge now that she qualifies
        vm.prank(alice);
        badges.claimBadge(0);
        
        // VERIFY: Check that the badge is now earned
        // This tests that the contract correctly reads the points balance
        // and grants the badge when the threshold is met
        assertTrue(badges.earned(alice, 0));
    }

    /// @notice TEST 4: Streak mechanics with grace period and permanent record
    /// TEACHING POINT: This tests the most psychologically sophisticated mechanic.
    /// - Grace period prevents punishing real-world interruptions
    /// - Longest streak creates a trophy that never goes away
    /// - Loss aversion motivates maintaining current streak
    function test_StreakGraceAndRecord() public {
        // SETUP: Set a starting time for predictable timestamp management
        // vm.warp() jumps the blockchain time to a specific point
        // This lets us test daily streaks without waiting 24 hours
        vm.warp(1_000_000);                      // set a sane starting time
        
        // ENTER: Start all subsequent calls as Alice
        vm.startPrank(alice);
        
        // DAY 1: First check-in
        // Current streak = 1, Longest = 1
        streaks.checkIn();                       // day 1
        
        // TIME JUMP: Move forward 1 day (exactly the DAY constant)
        vm.warp(block.timestamp + 1 days);
        
        // DAY 2: Second consecutive check-in
        // Current streak = 2 (streak continues within grace)
        streaks.checkIn();                       // day 2 (within grace)
        
        // VERIFY: Check that the streak built to 2
        (uint32 cur,,) = streaks.streakOf(alice);
        assertEq(cur, 2);

        // TIME JUMP: Skip 3 days (exceeds the 1-day grace period)
        // Now the total elapsed time is 4 days, breaking the streak
        vm.warp(block.timestamp + 3 days);       // gone too long
        
        // DAY UNKNOWN: Check-in after gap
        // Current streak resets to 1 (starting fresh)
        // But longest = 2 (the record survives!)
        streaks.checkIn();                       // reset
        
        // VERIFY: Check both current and longest streaks
        (uint32 cur2, uint32 longest,) = streaks.streakOf(alice);
        
        // CURRENT: Reset to 1 because she broke the streak
        assertEq(cur2, 1);
        
        // LONGEST: Still 2 - the personal best is forever
        // This creates the psychological hook - "I had a 2-day streak, I need to beat it!"
        assertEq(longest, 2);                    // the record is forever
        
        // EXIT: End the prank context
        vm.stopPrank();
    }

    /// @notice TEST 5: Tiers follow points automatically
    /// TEACHING POINT: This demonstrates "computed state" - tiers aren't stored,
    /// they're calculated from points on-demand. Changes to points = instant tier update.
    function test_TiersFollowBalance() public {
        // INITIAL STATE: Alice has no points
        // Expected tier = 0 (Member - the default)
        assertEq(tiers.tierOf(alice), 0);
        
        // ACTION: Award Alice 1000 points
        // This crosses the Silver threshold (1000 points)
        loyalty.earnPoints(alice, 1000, "a");
        
        // VERIFY: Alice is now Silver (tier 1)
        // Notice: No separate tier update needed!
        // Tier auto-updates because it reads from the points balance
        assertEq(tiers.tierOf(alice), 1);        // Silver
        
        // ACTION: Award Alice 19000 MORE points
        // Total = 20000, crossing the Platinum threshold
        loyalty.earnPoints(alice, 19000, "b");
        
        // VERIFY: Alice is now Platinum (tier 3)
        // The highest tier available in the system
        // This demonstrates how points = tier progression
        assertEq(tiers.tierOf(alice), 3);        // Platinum
    }
}

