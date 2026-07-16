// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILoyaltyPoints {
    function pointsOf(address) external view returns (uint256);
}

/// @title AchievementBadges — soulbound achievement registry (Session 3)
/// @notice Two award paths: issuer-attested (backend verified an off-chain action)
///         and self-claimed against an on-chain points threshold.
///         There is NO transfer function — absence IS the soulbound design.
contract AchievementBadges {
    address public issuer;
    ILoyaltyPoints public points; // Session 2's ledger — composition at work

    struct Badge {
        string name;       // "First Save", "30-Day Streak"
        uint256 threshold; // points needed to self-claim (0 = issuer-award only)
    }

    Badge[] public badges; // badge id = array index
    mapping(address => mapping(uint256 => bool)) public earned;

    event BadgeAwarded(address indexed customer, uint256 indexed badgeId, string name);

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not the issuer");
        _;
    }

    constructor(address ledger) {
        issuer = msg.sender;
        points = ILoyaltyPoints(ledger);
    }

    /// @notice Define a new badge type. Returns its id.
    function addBadge(string calldata name, uint256 threshold)
        external
        onlyIssuer
        returns (uint256 badgeId)
    {
        badges.push(Badge(name, threshold));
        return badges.length - 1;
    }

    /// @notice Issuer-attested path: backend verified something off-chain.
    function awardBadge(address customer, uint256 badgeId) external onlyIssuer {
        require(badgeId < badges.length, "No such badge");
        require(!earned[customer][badgeId], "Already earned");
        earned[customer][badgeId] = true;
        emit BadgeAwarded(customer, badgeId, badges[badgeId].name);
    }

    /// @notice Self-claim path: the contract READS the ledger — no permission needed.
    function claimBadge(uint256 badgeId) external {
        require(badgeId < badges.length, "No such badge");
        Badge memory b = badges[badgeId];
        require(b.threshold > 0, "Issuer-award only");
        require(points.pointsOf(msg.sender) >= b.threshold, "Threshold not met");
        require(!earned[msg.sender][badgeId], "Already earned");
        earned[msg.sender][badgeId] = true;
        emit BadgeAwarded(msg.sender, badgeId, b.name);
    }

    function badgeCount() external view returns (uint256) {
        return badges.length;
    }
}
