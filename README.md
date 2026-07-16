# Session 3 — Gamification Mechanics in Solidity

**Road to Mini Hack · Cohort 2 — Building Gamified Solutions for Businesses · team1 Kenya**

Four smart contracts that together form a complete gamified-solution backend on Avalanche:

| Contract | Mechanic | Behavioural drive | Pattern it teaches |
|---|---|---|---|
| `LoyaltyPoints.sol` | Points — **your Session 2 contract** (reference copy included) | Value & progress | Issuer gate for giving, open access for spending, events for analytics |
| `AchievementBadges.sol` | Badges (soulbound achievements) | Accomplishment | Composition — reads the ledger; **no transfer function = soulbound by design** |
| `StreakTracker.sol` | Streaks (daily check-in + grace window) | Loss aversion | Timestamp logic with a mercy rule |
| `TierSystem.sol` | Tiers (Member → Silver → Gold → Platinum) | Status | A **pure view over the ledger** — zero storage, zero maintenance |

Everything is pre-configured for **both Hardhat and Foundry**, deploying to the **Avalanche Fuji testnet** (chain ID 43113) — same contracts, same `.env`, your choice of toolkit. (Hardhat is the guided path below; the Foundry track is section 8 of `COMMANDS.md`.)

> 📖 **Every command you need, in order, is in [`COMMANDS.md`](./COMMANDS.md).** Open it side-by-side with your terminal.

---

## Quick start (5 minutes)

**1 — Fork this repo** (button top-right). Your fork is your own copy — push your Quest 3 work to it; it lives on your GitHub profile as proof of work.

**2 — Clone *your* fork:**
```bash
git clone https://github.com/<YOUR-USERNAME>/session-3-gamification-mechanics.git
cd session-3-gamification-mechanics
npm install
```

**3 — Configure your environment:**
```bash
cp .env.example .env
```
Open `.env` and paste a **TEST-ONLY private key** funded with Fuji AVAX (faucet: Builders Hub console at [build.avax.network](https://build.avax.network) — your Quest 1 account unlocks it).
⚠️ **Never use a key that has ever held real funds. Never commit `.env`.**

**4 — Prove it works locally (free, no network needed):**
```bash
npx hardhat test
```
All tests green = the whole stack works on your machine.

**5 — Point tonight's contracts at YOUR ledger, then deploy:**
In `.env`, set `LOYALTY_ADDRESS` to your Session 2 LoyaltyPoints address (from Quest 2) — tonight's badges and tiers will read **your** ledger. Composition, for real. (Leave it empty and the script deploys a fresh ledger instead.) Then:
```bash
npx hardhat run scripts/deploy-all.js --network fuji
```
Addresses print and save to `deployments.json` — **your Quest 3 submission material.**

**6 — Run the full journey (earn → claim badge → check in → tier → redeem):**
```bash
npx hardhat run scripts/interact.js --network fuji
```

---

## Repository layout

```
contracts/          The four contracts, commented for reading in session
scripts/
  deploy-all.js     Deploys the whole stack in order, saves deployments.json
  interact.js       Demonstrates the full user journey end-to-end
test/
  Session3.test.js  Hardhat suite covering all four contracts (run locally, free)
  Session3.t.sol    Foundry twin of the same suite (forge test)
script/
  Deploy.s.sol      Foundry deploy script (twin of scripts/deploy-all.js)
hardhat.config.js   Fuji network + Snowtrace verification pre-configured
foundry.toml        Foundry config — coexists with Hardhat cleanly
.env.example        Copy to .env — RPC + your test key
COMMANDS.md         Every command, in order, with what each one does
```

## Architecture — one ledger, many mechanics

```
                    ┌──────────────────┐
                    │  LoyaltyPoints    │  ← the single source of truth
                    │  (the ledger)     │
                    └───┬───────────┬──┘
              reads via │           │ reads via
              interface │           │ interface
        ┌───────────────▼──┐   ┌───▼────────────┐
        │ AchievementBadges │   │   TierSystem    │
        │  (self-claims)    │   │  (pure view)    │
        └───────────────────┘   └─────────────────┘

        ┌───────────────────┐
        │   StreakTracker    │  ← standalone; its events can trigger
        │  (habit engine)    │     point bonuses via your backend
        └───────────────────┘
```

The pattern to internalize: **small contracts, one ledger, events everywhere.** This is also the architecture of your Jam project on Friday.

## Quest 3

Pick **ONE** mechanic (badges, streaks, or tiers), deploy it to Fuji, and submit via Plug and Play:
1. The contract address + explorer link ([testnet.snowtrace.io](https://testnet.snowtrace.io))
2. **One sentence naming the behaviour it targets** — the Routledge test, graded
3. Bonus: wire it to *your own* Session 2 LoyaltyPoints via the interface — composition is the skill

Deadline: **before Thursday's session (July 16).**

## Contributing

Fixes, docs, translations, and new example mechanics are welcome — see [`CONTRIBUTING.md`](./CONTRIBUTING.md). Merged contributions count toward your L1→L5 progression in the technical portfolio.

## Getting help

- `STUCK` in the session chat → a mentor picks you up in a thread
- Discord tech channel: patient, documented answers
- Common failures + fixes: bottom of [`COMMANDS.md`](./COMMANDS.md)

---

*team1 Kenya · Mini Hack Cohort 2 · Technical Lead: Scotch · Community: [@AvaxAfrica](https://x.com/AvaxAfrica) · t.me/avaxDAOAfrica*
