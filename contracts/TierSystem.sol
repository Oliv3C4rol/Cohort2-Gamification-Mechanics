// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILoyaltyPointsView {
    function pointsOf(address) external view returns (uint256);
}

/// @title TierSystem — status as a free view over the ledger (Session 3)
/// @notice Zero storage per customer, zero maintenance, can never drift out
///         of sync — because a tier IS the points balance seen through thresholds.
contract TierSystem {
    ILoyaltyPointsView public points; // composition, again

    uint256[3] public thresholds = [1000, 5000, 20000];
    // Silver              Gold        Platinum

    constructor(address ledger) {
        points = ILoyaltyPointsView(ledger);
    }

    /// @notice 0 = Member, 1 = Silver, 2 = Gold, 3 = Platinum. Free to call.
    function tierOf(address customer) public view returns (uint8) {
        uint256 p = points.pointsOf(customer);
        if (p >= thresholds[2]) return 3;
        if (p >= thresholds[1]) return 2;
        if (p >= thresholds[0]) return 1;
        return 0;
    }

    function tierNameOf(address customer) external view returns (string memory) {
        uint8 t = tierOf(customer);
        if (t == 3) return "Platinum";
        if (t == 2) return "Gold";
        if (t == 1) return "Silver";
        return "Member";
    }
}
