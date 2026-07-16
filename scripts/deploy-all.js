// Deploys tonight's three mechanics and wires them to a LoyaltyPoints ledger.
//
//   If LOYALTY_ADDRESS is set in .env  -> attaches to YOUR Session 2 contract  (recommended!)
//   If it is not set                   -> deploys a fresh LoyaltyPoints first  (fallback)
//
// Run:  npx hardhat run scripts/deploy-all.js --network fuji
const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying as issuer:", deployer.address);

  // 0. The ledger — yours from Session 2, or a fresh fallback
  let loyaltyAddress = process.env.LOYALTY_ADDRESS;
  if (loyaltyAddress) {
    console.log("Attaching to YOUR Session 2 LoyaltyPoints ->", loyaltyAddress);
  } else {
    const loyalty = await hre.ethers.deployContract("LoyaltyPoints");
    await loyalty.waitForDeployment();
    loyaltyAddress = loyalty.target;
    console.log("(no LOYALTY_ADDRESS in .env — deployed a fresh ledger)");
    console.log("LoyaltyPoints      ->", loyaltyAddress);
  }

  // 1. Badges — tonight. Reads the ledger: composition.
  const badges = await hre.ethers.deployContract("AchievementBadges", [loyaltyAddress]);
  await badges.waitForDeployment();
  console.log("AchievementBadges  ->", badges.target);

  // 2. Streaks — tonight. Standalone habit engine.
  const streaks = await hre.ethers.deployContract("StreakTracker");
  await streaks.waitForDeployment();
  console.log("StreakTracker      ->", streaks.target);

  // 3. Tiers — tonight. A pure view over the ledger.
  const tiers = await hre.ethers.deployContract("TierSystem", [loyaltyAddress]);
  await tiers.waitForDeployment();
  console.log("TierSystem         ->", tiers.target);

  const out = {
    network: hre.network.name,
    issuer: deployer.address,
    LoyaltyPoints: loyaltyAddress,
    AchievementBadges: badges.target,
    StreakTracker: streaks.target,
    TierSystem: tiers.target,
  };
  fs.writeFileSync("deployments.json", JSON.stringify(out, null, 2));
  console.log("\nSaved to deployments.json — these addresses are your Quest 3 material.");
}

main().catch((e) => { console.error(e); process.exitCode = 1; });
