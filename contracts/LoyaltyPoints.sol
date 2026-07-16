// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title LoyaltyPoints — the core on-chain loyalty ledger (Session 2)
/// @notice The business (issuer) awards points; customers redeem self-service.
///         Pattern: issuer gate for giving, open access for spending, events for analytics.
/// 
/// GAMIFICATION CONCEPT: Points are the primary CURRENCY in a loyalty system.
/// They act as a universal reward that customers can earn through desired behaviors
/// and redeem for value. This creates a feedback loop: Action → Points → Reward.
contract LoyaltyPoints {
    // STORAGE: Store the address of the business/issuer who controls point allocation
    // This ensures only the authorized entity can award points to prevent fraud
    address public issuer;

    // STORAGE: A mapping keeps track of each customer's current point balance
    // Think of it as a ledger for each wallet address that holds loyalty points
    mapping(address => uint256) private balances;
    
    // STORAGE: Track the total points ever created (lifetime metric for analytics)
    // This helps businesses understand reward distribution patterns
    uint256 public totalIssued;   // lifetime points created
    
    // STORAGE: Track the total points ever redeemed (spent by customers)
    // This helps businesses understand redemption rates and customer engagement
    uint256 public totalRedeemed; // lifetime points burned

    // EVENT: Emit when a customer earns points
    // Events create an immutable audit trail on the blockchain for all transactions
    event PointsEarned(address indexed customer, uint256 amount, string reason);
    
    // EVENT: Emit when a customer redeems points
    // This allows external systems to track customer behavior and trigger responses
    event PointsRedeemed(address indexed customer, uint256 amount, string reward);

    // MODIFIER: Enforce that only the issuer can call certain functions
    // This is the permission gate that ensures only the business can award points
    modifier onlyIssuer() {
        require(msg.sender == issuer, "Not the issuer");
        _;
    }

    // CONSTRUCTOR: Initialize the contract and set the deployer as the issuer
    // The deployer becomes the business owner who controls all point awards
    constructor() {
        issuer = msg.sender; // whoever deploys = the business
    }

    /// @notice Issuer credits a customer after a verified real-world action.
    /// TEACHING POINT: This is the "carrot" in gamification - the reward.
    /// The issuer (backend) verifies an action occurred (purchase, referral, task completion)
    /// and then awards points as a token of gratitude for that action.
    function earnPoints(address customer, uint256 amount, string calldata reason)
        external
        onlyIssuer
    {
        // Increase the customer's point balance by the awarded amount
        // Think of this as crediting their loyalty account
        balances[customer] += amount;
        
        // Track the total lifetime points issued for business analytics
        // This number never decreases - only grows as the business awards more points
        totalIssued += amount;
        
        // Emit an event so everyone can see this transaction happened
        // The 'reason' parameter stores WHY points were awarded (e.g., "purchase of $50")
        emit PointsEarned(customer, amount, reason);
    }

    /// @notice Customer spends points — self-service, burn on redeem.
    /// TEACHING POINT: This is the "redemption" phase - customers cash in their rewards.
    /// The customer decides when and how to spend their points without needing permission.
    /// This autonomy increases engagement and satisfaction in gamification.
    function redeemPoints(uint256 amount, string calldata reward) external {
        // Verify the customer has enough points to redeem (prevent overspending)
        // This is critical - you can't spend points you don't have!
        require(balances[msg.sender] >= amount, "Insufficient points");
        
        // Deduct the points from the customer's balance (they're spending their reward)
        // This happens atomically - either the full transaction succeeds or it fails
        balances[msg.sender] -= amount;
        
        // Track the total lifetime points redeemed for business metrics
        // This shows how many rewards customers have actually claimed
        totalRedeemed += amount;
        
        // Emit an event documenting what reward the customer claimed
        // The 'reward' parameter describes what they redeemed for (e.g., "10% discount")
        emit PointsRedeemed(msg.sender, amount, reward);
    }

    /// @notice Free read for any app, dashboard, or auditor.
    /// TEACHING POINT: Transparency is key - anyone can check their balance!
    /// This builds trust because customers can always verify their point balance.
    function pointsOf(address customer) external view returns (uint256) {
        // Simple getter function that returns a customer's current point balance
        // View functions don't modify state and don't consume gas for reading
        return balances[customer];
    }

    /// @notice Outstanding liability = points promised but not yet redeemed.
    /// TEACHING POINT: Business accounting - track outstanding rewards liability.
    /// This shows how many points are still "owed" to customers who might redeem later.
    function outstandingLiability() external view returns (uint256) {
        // Calculate points that customers could potentially redeem
        // This is a key business metric for budgeting and financial planning
        return totalIssued - totalRedeemed;
    }
}
