// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// IMPORT: Foundry's Script utilities for deployment automation
// Script is the base contract for Foundry deployment scripts
// console is for logging output during deployment
import {Script, console} from "forge-std/Script.sol";

// IMPORT: All four gamification contracts from the contracts folder
// These are the core building blocks of our gamification system
import {LoyaltyPoints} from "../contracts/LoyaltyPoints.sol";
import {AchievementBadges} from "../contracts/AchievementBadges.sol";
import {StreakTracker} from "../contracts/StreakTracker.sol";
import {TierSystem} from "../contracts/TierSystem.sol";

/// @title Deploy — Foundry deployment script for gamification system
/// @notice Orchestrates deployment of all four gamification contracts
/// 
/// GAMIFICATION TEACHING: This script demonstrates SYSTEM COMPOSITION.
/// Notice how the contracts depend on each other:
///   - LoyaltyPoints is the foundation (tracks points)
///   - AchievementBadges reads from LoyaltyPoints
///   - TierSystem reads from LoyaltyPoints
///   - StreakTracker is independent
/// 
/// This creates a MICROSERVICES ARCHITECTURE where:
/// 1. Core data lives in LoyaltyPoints
/// 2. Other contracts build on top via contract calls
/// 3. Everything stays in sync automatically
///
/// TWO DEPLOYMENT PATHS:
///   1. LOYALTY_ADDRESS set in .env -> attach to existing Session 2 ledger (recommended for production)
///   2. LOYALTY_ADDRESS empty -> deploy a fresh ledger (great for testing/development)
///
/// RUN COMMAND:
///   forge script script/Deploy.s.sol --rpc-url fuji --broadcast
/// 
/// This deploys all contracts to the Avalanche Fuji testnet and broadcasts the transactions.
contract Deploy is Script {
    /// @notice Main execution function called by Foundry when running the script
    /// This orchestrates the deployment of all gamification contracts
    function run() external {
        // STEP 1: READ PRIVATE KEY from environment
        // The private key is used to sign all blockchain transactions during deployment
        // This ensures the deployer has the authority to create the contracts
        uint256 pk = vm.envUint("PRIVATE_KEY");
        
        // STEP 2: READ LOYALTY_ADDRESS from environment (or use zero address as default)
        // vm.envOr is a Foundry helper that reads env vars with a fallback value
        // If LOYALTY_ADDRESS is not set, it defaults to address(0) - the null address
        // TEACHING POINT: This demonstrates COMPOSITION - we can attach to existing systems
        address ledger = vm.envOr("LOYALTY_ADDRESS", address(0));

        // STEP 3: START BROADCAST
        // vm.startBroadcast signs all subsequent transactions with the private key
        // All contract deployments that follow will be sent to the blockchain
        vm.startBroadcast(pk);

        // STEP 4: CONDITIONAL DEPLOYMENT OF LOYALTY POINTS
        // Check if an existing LoyaltyPoints contract address was provided
        if (ledger == address(0)) {
            // PATH A: No existing ledger provided - deploy a NEW one
            // This is useful for development/testing or starting a fresh system
            LoyaltyPoints loyalty = new LoyaltyPoints();
            
            // Update the ledger variable to point to the newly deployed contract
            // This address will be used for AchievementBadges and TierSystem
            ledger = address(loyalty);
            
            // Log information about the new deployment
            console.log("(no LOYALTY_ADDRESS - deployed fresh ledger)");
            console.log("LoyaltyPoints     ->", ledger);
        } else {
            // PATH B: Existing ledger provided - attach to it
            // This is COMPOSITION in action - we're integrating with an existing system
            // Great for production where you already have a Session 2 ledger running
            console.log("Attaching to YOUR Session 2 LoyaltyPoints ->", ledger);
        }

        // STEP 5: DEPLOY ACHIEVEMENT BADGES CONTRACT
        // This contract needs the ledger address so it can READ point balances
        // Pass the ledger address to the AchievementBadges constructor
        AchievementBadges badges = new AchievementBadges(ledger);
        
        // Log the deployed contract address
        console.log("AchievementBadges ->", address(badges));

        // STEP 6: DEPLOY STREAK TRACKER CONTRACT
        // StreakTracker is INDEPENDENT - it doesn't need any other contract
        // It manages habits completely on its own
        StreakTracker streaks = new StreakTracker();
        
        // Log the deployed contract address
        console.log("StreakTracker     ->", address(streaks));

        // STEP 7: DEPLOY TIER SYSTEM CONTRACT
        // TierSystem needs the ledger address so it can READ point balances
        // It determines a customer's tier based on their points
        TierSystem tiers = new TierSystem(ledger);
        
        // Log the deployed contract address
        console.log("TierSystem        ->", address(tiers));

        // STEP 8: STOP BROADCAST
        // vm.stopBroadcast ends the transaction signing session
        // Any code after this line will NOT be signed or broadcast
        vm.stopBroadcast();
        
        // DEPLOYMENT SUMMARY:
        // At this point, all four gamification contracts are live on the blockchain!
        // The addresses are logged so you can copy them for frontend integration.
        // 
        // KEY INSIGHT: Notice how some contracts depend on others (AchievementBadges, TierSystem need ledger)
        // while StreakTracker stands alone. This is MODULAR DESIGN.
        // You can use each contract independently or combine them as a system.
    }
}
