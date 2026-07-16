// The full journey, end to end, against your deployed contracts.
// Run AFTER deploy-all:  npx hardhat run scripts/interact.js --network fuji
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const d = JSON.parse(fs.readFileSync("deployments.json"));
  const [me] = await hre.ethers.getSigners();

  const loyalty = await hre.ethers.getContractAt("LoyaltyPoints", d.LoyaltyPoints);
  const badges  = await hre.ethers.getContractAt("AchievementBadges", d.AchievementBadges);
  const streaks = await hre.ethers.getContractAt("StreakTracker", d.StreakTracker);
  const tiers   = await hre.ethers.getContractAt("TierSystem", d.TierSystem);

  console.log("1) Issuer awards 1500 points for a 'purchase'...");
  await (await loyalty.earnPoints(me.address, 1500, "purchase")).wait();
  console.log("   balance:", (await loyalty.pointsOf(me.address)).toString());

  console.log("2) Define a self-claimable badge: 'First 1000' (threshold 1000)...");
  await (await badges.addBadge("First 1000", 1000)).wait();

  console.log("3) Customer self-claims the badge (contract reads the ledger)...");
  await (await badges.claimBadge(0)).wait();
  console.log("   earned badge 0:", await badges.earned(me.address, 0));

  console.log("4) Daily check-in on the streak tracker...");
  await (await streaks.checkIn()).wait();
  const s = await streaks.streakOf(me.address);
  console.log("   current:", s[0].toString(), "| longest:", s[1].toString());

  console.log("5) Tier check (free view over the ledger)...");
  console.log("   tier:", await tiers.tierNameOf(me.address));

  console.log("6) Customer redeems 200 points for a 'coffee-voucher'...");
  await (await loyalty.redeemPoints(200, "coffee-voucher")).wait();
  console.log("   balance:", (await loyalty.pointsOf(me.address)).toString(),
              "| outstanding liability:", (await loyalty.outstandingLiability()).toString());

  console.log("\nDone — every step above is now permanently on the explorer.");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });
