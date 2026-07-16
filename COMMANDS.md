# COMMANDS.md — Every Command, In Order

Follow top to bottom. Each block says **what it does** before the command.
`$` means "type this in your terminal" — don't type the `$` itself.

---

## 0 · Prerequisites (once per machine)

**Check Node.js is installed and version 18+ (we recommend 20 LTS):**
```bash
node -v
```
No Node / too old? Install Node 20 via [nvm](https://github.com/nvm-sh/nvm):
```bash
nvm install 20 && nvm use 20
```

**Check Git:**
```bash
git --version
```

> 🪟 **Windows:** run everything inside **WSL2 (Ubuntu)**. It will save you a night of pain.

---

## 1 · Get the code

**Fork first** (button on the repo page) — then clone *your* fork:
```bash
git clone https://github.com/<YOUR-USERNAME>/session-3-gamification-mechanics.git
cd session-3-gamification-mechanics
```

**Install the project's tools (Hardhat & friends) — takes a minute:**
```bash
npm install
```

---

## 2 · Configure your keys

**Create your private config file from the template:**
```bash
cp .env.example .env
```

**Edit `.env`** (in VS Code: `code .env`) and set:
- `PRIVATE_KEY` — a **TEST-ONLY** key from your Core Wallet test account
  (Core → account menu → *Show private key*)
- `LOYALTY_ADDRESS` — **your Session 2 LoyaltyPoints address** (Quest 2). Tonight's
  contracts attach to YOUR ledger. Use the same key that deployed it, so you stay the issuer.
  (Optional — leave empty and the deploy script creates a fresh ledger.)
- `FUJI_RPC_URL` — already filled with the default; leave it

**Fund that account with free test AVAX:**
Builders Hub console → [build.avax.network](https://build.avax.network) → Fuji faucet → paste your `0x...` address.

> ⚠️ Rules that are law: **never** a key that has ever held real funds; **never** commit `.env` (it's already in `.gitignore`).

---

## 3 · Compile & test locally (free — no network, no gas)

**Compile the contracts:**
```bash
npx hardhat compile
```
*Translates the Solidity into deployable form. Your typos get caught here, on your laptop — not on the chain.*

**Run the test suite:**
```bash
npx hardhat test
```
*Spins up a private throwaway blockchain in memory, deploys all four contracts to it, and checks every behaviour — issuer gates, overdrafts, badge claims, streak grace windows, tier thresholds. All green = the stack works.*

**Optional — see how the streak time-travel test works:**
open `test/Session3.test.js` and find `time.increase(...)` — on the local test chain we can fast-forward time. (No, you can't do that on Fuji. 😄)

---

## 4 · Deploy the full stack to Fuji

**One command deploys tonight's mechanics, wired to your ledger:**
```bash
npx hardhat run scripts/deploy-all.js --network fuji
```
*Attaches to YOUR Session 2 LoyaltyPoints (from `LOYALTY_ADDRESS` in `.env`) — or deploys a fresh ledger if you left it empty — then passes that address into AchievementBadges and TierSystem (composition!), plus the standalone StreakTracker. Prints the addresses and saves them to `deployments.json`.*

**Look at what you just made:**
```bash
cat deployments.json
```
Those addresses are permanent. Copy them somewhere safe — **they're your Quest 3 material.**

---

## 5 · Use it — the full journey

**Run the end-to-end demo against your deployed contracts:**
```bash
npx hardhat run scripts/interact.js --network fuji
```
*As the issuer, awards yourself 1500 points for a "purchase" → defines a self-claimable badge → claims it (the badge contract reads the ledger!) → daily streak check-in → tier check (you'll be Silver) → redeems 200 points for a "coffee-voucher" → prints the outstanding liability.*

Every step lands on-chain in ~1–2 seconds. Run it, then go look at the receipts:

**View everything on the public explorer:**
open `https://testnet.snowtrace.io/address/<YOUR-LOYALTYPOINTS-ADDRESS>`
*Deployment, transactions, event logs — public, verifiable, permanent. That link is your proof.*

---

## 6 · Optional — verify your source code on the explorer

*Verification publishes your source next to the bytecode so anyone can read it — the gold standard of "deployed, not demoed."*
```bash
npx hardhat verify --network avalancheFujiTestnet <LOYALTYPOINTS-ADDRESS>
npx hardhat verify --network avalancheFujiTestnet <BADGES-ADDRESS> <LOYALTYPOINTS-ADDRESS>
npx hardhat verify --network avalancheFujiTestnet <STREAKS-ADDRESS>
npx hardhat verify --network avalancheFujiTestnet <TIERS-ADDRESS> <LOYALTYPOINTS-ADDRESS>
```
*(Badges and Tiers take the ledger address as a constructor argument, so it's repeated after their own address.)*

---

## 7 · Push your work to your fork (Quest 3 evidence)

```bash
git add .
git commit -m "Session 3: deployed gamification mechanics to Fuji"
git push origin main
```
*(`deployments.json` is git-ignored by default — if you WANT to publish your addresses in your fork, remove it from `.gitignore` first, or paste them into your README.)*

---

---

## 8 · The Foundry track — same repo, second toolkit

*Everything above used Hardhat. The repo also ships full Foundry support — same contracts, same env vars — so you learn both toolkits the ecosystem uses.*

**Install Foundry (once):**
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**Install the test library (once per clone):**
```bash
forge install foundry-rs/forge-std --no-commit
```

**Compile:**
```bash
forge build
```

**Run the Foundry test suite** (a Solidity twin of the Hardhat one — open `test/Session3.t.sol` and compare):
```bash
forge test -vv
```
*Note the superpowers: `vm.prank` impersonates any address, `vm.warp` time-travels, `vm.expectRevert` catches the bouncers.*

**Deploy the stack to Fuji** (reads the same `.env` — `PRIVATE_KEY` and optional `LOYALTY_ADDRESS`):
```bash
source .env
forge script script/Deploy.s.sol --rpc-url fuji --broadcast
```

**Talk to your contracts with cast:**
```bash
cast call <LOYALTY_ADDRESS> "pointsOf(address)(uint256)" <YOUR_0x> --rpc-url $FUJI_RPC_URL
cast send <LOYALTY_ADDRESS> "earnPoints(address,uint256,string)" <CUSTOMER_0x> 100 "purchase" \
  --rpc-url $FUJI_RPC_URL --private-key $PRIVATE_KEY
```

**Which toolkit should I use?** Either — the concepts are identical. Hardhat: JavaScript workflow, one-command npm scripts. Foundry: faster, tests in Solidity, and `cast` for terminal-level contract poking. Professionals typically know both; now so do you.

---

## 🚑 When things break — fast fixes

| Symptom | Fix |
|---|---|
| `command not found: npx` | Node isn't installed / not on PATH → `nvm install 20 && nvm use 20`, restart terminal |
| `npm install` fails on old Node | `nvm use 20` |
| `insufficient funds for gas` | Faucet again at build.avax.network; confirm the key in `.env` matches the funded account |
| `invalid private key` | No `0x` prefix issues both ways — paste exactly what Core shows; no spaces or quotes |
| Deploy hangs / nonce errors | Wait ~30s and rerun the script |
| Core Wallet shows no balance | You're on the wrong network — switch to **Fuji Testnet (C-Chain)** |
| Windows: weird path/permission errors | Move into WSL2 (Ubuntu) |
| Still stuck | `STUCK` in the session chat, or the Discord tech channel with the exact error message pasted |
