// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {LoyaltyPoints} from "../contracts/LoyaltyPoints.sol";
import {AchievementBadges} from "../contracts/AchievementBadges.sol";
import {StreakTracker} from "../contracts/StreakTracker.sol";
import {TierSystem} from "../contracts/TierSystem.sol";

/// Foundry twin of scripts/deploy-all.js — same logic, same env vars.
///   LOYALTY_ADDRESS set in .env -> attach to YOUR Session 2 ledger (recommended)
///   LOYALTY_ADDRESS empty      -> deploy a fresh ledger (fallback)
///
/// Run:
///   forge script script/Deploy.s.sol --rpc-url fuji --broadcast
contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address ledger = vm.envOr("LOYALTY_ADDRESS", address(0));

        vm.startBroadcast(pk);

        if (ledger == address(0)) {
            LoyaltyPoints loyalty = new LoyaltyPoints();
            ledger = address(loyalty);
            console.log("(no LOYALTY_ADDRESS - deployed fresh ledger)");
            console.log("LoyaltyPoints     ->", ledger);
        } else {
            console.log("Attaching to YOUR Session 2 LoyaltyPoints ->", ledger);
        }

        AchievementBadges badges = new AchievementBadges(ledger);
        console.log("AchievementBadges ->", address(badges));

        StreakTracker streaks = new StreakTracker();
        console.log("StreakTracker     ->", address(streaks));

        TierSystem tiers = new TierSystem(ledger);
        console.log("TierSystem        ->", address(tiers));

        vm.stopBroadcast();
    }
}
