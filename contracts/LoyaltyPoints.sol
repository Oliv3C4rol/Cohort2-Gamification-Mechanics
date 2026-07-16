// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title LoyaltyPoints — the core on-chain loyalty ledger (Session 2)
/// @notice The business (issuer) awards points; customers redeem self-service.
///         Pattern: issuer gate for giving, open access for spending, events for analytics.
contract LoyaltyPoints {
    address public issuer;

    mapping(address => uint256) private balances;
    uint256 public totalIssued;   // lifetime points created
    uint256 public totalRedeemed; // lifetime points burned

    event PointsEarned(address indexed customer, uint256 amount, string reason);
    event PointsRedeemed(address indexed customer, uint256 amount, string reward);

    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not the issuer");
        _;
    }

    constructor() {
        issuer = msg.sender; // whoever deploys = the business
    }

    /// @notice Issuer credits a customer after a verified real-world action.
    function earnPoints(address customer, uint256 amount, string calldata reason)
        external
        onlyIssuer
    {
        balances[customer] += amount;
        totalIssued += amount;
        emit PointsEarned(customer, amount, reason);
    }

    /// @notice Customer spends points — self-service, burn on redeem.
    function redeemPoints(uint256 amount, string calldata reward) external {
        require(balances[msg.sender] >= amount, "Insufficient points");
        balances[msg.sender] -= amount;
        totalRedeemed += amount;
        emit PointsRedeemed(msg.sender, amount, reward);
    }

    /// @notice Free read for any app, dashboard, or auditor.
    function pointsOf(address customer) external view returns (uint256) {
        return balances[customer];
    }

    /// @notice Outstanding liability = points promised but not yet redeemed.
    function outstandingLiability() external view returns (uint256) {
        return totalIssued - totalRedeemed;
    }
}
