const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("Session 3 — Gamification Mechanics", function () {
  let issuer, alice, loyalty, badges, streaks, tiers;

  beforeEach(async () => {
    [issuer, alice] = await ethers.getSigners();
    loyalty = await ethers.deployContract("LoyaltyPoints");
    badges  = await ethers.deployContract("AchievementBadges", [loyalty.target]);
    streaks = await ethers.deployContract("StreakTracker");
    tiers   = await ethers.deployContract("TierSystem", [loyalty.target]);
  });

  describe("LoyaltyPoints (the ledger)", () => {
    it("issuer earns, customer redeems, liability tracks", async () => {
      await loyalty.earnPoints(alice.address, 1500, "purchase");
      expect(await loyalty.pointsOf(alice.address)).to.equal(1500);

      await loyalty.connect(alice).redeemPoints(200, "coffee-voucher");
      expect(await loyalty.pointsOf(alice.address)).to.equal(1300);
      expect(await loyalty.outstandingLiability()).to.equal(1300);
    });

    it("blocks non-issuer earning and overdraft redeeming", async () => {
      await expect(loyalty.connect(alice).earnPoints(alice.address, 1, "hack"))
        .to.be.revertedWith("Not the issuer");
      await expect(loyalty.connect(alice).redeemPoints(1, "x"))
        .to.be.revertedWith("Insufficient points");
    });
  });

  describe("AchievementBadges (soulbound registry)", () => {
    it("issuer-attested award works once", async () => {
      await badges.addBadge("Workshop Hero", 0);
      await expect(badges.awardBadge(alice.address, 0))
        .to.emit(badges, "BadgeAwarded").withArgs(alice.address, 0, "Workshop Hero");
      await expect(badges.awardBadge(alice.address, 0))
        .to.be.revertedWith("Already earned");
    });

    it("self-claim reads the ledger (composition)", async () => {
      await badges.addBadge("First 1000", 1000);
      await expect(badges.connect(alice).claimBadge(0))
        .to.be.revertedWith("Threshold not met");

      await loyalty.earnPoints(alice.address, 1000, "purchases");
      await badges.connect(alice).claimBadge(0);
      expect(await badges.earned(alice.address, 0)).to.equal(true);
    });
  });

  describe("StreakTracker (loss aversion)", () => {
    it("continues within grace, resets beyond it, keeps the record", async () => {
      await streaks.connect(alice).checkIn(); // day 1
      await time.increase(24 * 3600);
      await streaks.connect(alice).checkIn(); // day 2 (within DAY+GRACE)
      let s = await streaks.streakOf(alice.address);
      expect(s[0]).to.equal(2);

      await time.increase(3 * 24 * 3600);     // gone too long
      await streaks.connect(alice).checkIn(); // resets to 1
      s = await streaks.streakOf(alice.address);
      expect(s[0]).to.equal(1);
      expect(s[1]).to.equal(2);               // the record is forever
    });

    it("blocks double check-in in one day", async () => {
      await streaks.connect(alice).checkIn();
      await expect(streaks.connect(alice).checkIn())
        .to.be.revertedWith("Already checked in today");
    });
  });

  describe("TierSystem (a free view over the ledger)", () => {
    it("tiers follow the balance with zero maintenance", async () => {
      expect(await tiers.tierNameOf(alice.address)).to.equal("Member");
      await loyalty.earnPoints(alice.address, 1000, "a");
      expect(await tiers.tierNameOf(alice.address)).to.equal("Silver");
      await loyalty.earnPoints(alice.address, 4000, "b");
      expect(await tiers.tierNameOf(alice.address)).to.equal("Gold");
      await loyalty.earnPoints(alice.address, 15000, "c");
      expect(await tiers.tierNameOf(alice.address)).to.equal("Platinum");
    });
  });
});
