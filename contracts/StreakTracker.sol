// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StreakTracker — loss aversion, compiled (Session 3)
/// @notice Daily check-in with a one-day grace window. Tracks current and
///         longest streak; the longest is a permanent record that survives resets.
contract StreakTracker {
    uint256 public constant DAY = 1 days;   // check-in window
    uint256 public constant GRACE = 1 days; // one missed day forgiven

    struct Streak {
        uint64 lastCheckIn; // when they last showed up
        uint32 current;     // the streak they protect
        uint32 longest;     // permanent best — survives resets
    }

    mapping(address => Streak) public streaks;

    event CheckedIn(address indexed user, uint32 current, uint32 longest);

    /// @notice Self-service daily check-in. Habits are self-service.
    function checkIn() external {
        Streak storage s = streaks[msg.sender];
        uint256 elapsed = block.timestamp - s.lastCheckIn;

        require(elapsed >= DAY, "Already checked in today");

        if (s.lastCheckIn != 0 && elapsed <= DAY + GRACE) {
            s.current += 1; // streak continues (grace held)
        } else {
            s.current = 1; // day one (first ever, or streak reset)
        }

        if (s.current > s.longest) {
            s.longest = s.current; // the record is forever
        }

        s.lastCheckIn = uint64(block.timestamp);
        emit CheckedIn(msg.sender, s.current, s.longest);
    }

    function streakOf(address user)
        external
        view
        returns (uint32 current, uint32 longest, uint64 lastCheckIn)
    {
        Streak memory s = streaks[user];
        return (s.current, s.longest, s.lastCheckIn);
    }
}
