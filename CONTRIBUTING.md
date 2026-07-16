# Contributing — team1 Kenya Session Repos

Karibu! 👋 This repo is part of the **team1 Kenya** GitHub organization — the home of Mini Hack cohort code, session starters, and builder contributions. Whether you're a cohort builder submitting a quest, fixing a typo, or adding a whole new mechanic, this guide is the path.

---

## The two ways people use this repo

### 1 · Cohort builders (quests & the Jam) — **fork, don't PR**

If you're working on a quest or your Jam project, your work lives in **your fork**, not in this repo:

1. **Fork** this repo (button top-right) → your own copy under your GitHub account
2. **Clone your fork** and build:
   ```bash
   git clone https://github.com/<YOUR-USERNAME>/session-3-gamification-mechanics.git
   ```
3. Modify, deploy, push to **your fork**:
   ```bash
   git add . && git commit -m "Quest 3: weekly chama streak tracker" && git push origin main
   ```
4. Submit your fork URL + contract address + explorer link via **Plug and Play**

Your fork is your portfolio: public proof of work under your own name. Keep it clean — a good README in your fork describing *what you changed and which behaviour it targets* is worth more to a future employer than the code itself.

> ⚠️ **Never commit secrets.** `.env` is git-ignored — leave it that way. If you ever accidentally push a private key, consider that key burned forever: create a new account and move on. (Test keys hold nothing of value — that's why we insist on them.)

### 2 · Contributing back to this repo — **PRs welcome**

Found a bug in a contract? A confusing line in COMMANDS.md? Want to add a new example mechanic, a test, or a translation? That's a contribution to the org, and it's exactly how you climb the team1 progression ladder (L1 → L5): **shipped, reviewed contributions are the currency.**

**The flow:**

1. **Open an issue first** for anything non-trivial — describe what and why in a few sentences. For typos/doc fixes, skip straight to a PR.
2. Fork → create a branch off `main`:
   ```bash
   git checkout -b fix/streak-grace-comment
   ```
   Branch prefixes: `fix/` bugs · `docs/` documentation · `feat/` new mechanics or scripts · `test/` test coverage
3. Make the change. **Both toolchains must stay green:**
   ```bash
   npx hardhat test     # Hardhat suite
   forge test           # Foundry suite (if you have Foundry installed)
   ```
4. Commit with a message that says what and why:
   `fix: grace window off-by-one when lastCheckIn is 0`
5. Push and **open a Pull Request** against `Team1Kenya:main`. Fill in:
   - What changed & why (link the issue)
   - How you tested it (paste the test output)
   - If a contract changed: the Fuji address where you deployed and verified it
6. A maintainer (Technical Lead or an L3+ Core Member) reviews within ~48 hours — same rhythm as quest reviews.

**What gets merged:**
- ✅ Bug fixes with a test that fails before and passes after
- ✅ Documentation that makes a beginner's path smoother (including Swahili translations — highly welcome)
- ✅ New example mechanics that follow the house pattern (below), with tests in **both** suites
- ✅ Deployment/tooling improvements that keep the one-command experience
- ❌ Contract changes that break the teaching narrative of the session decks (open an issue to discuss first)
- ❌ Dependency additions without a strong reason — this repo stays beginner-light
- ❌ Anything with secrets, mainnet keys, or real funds involved

---

## The house pattern (read before adding a mechanic)

Every contract in the org's cohort repos follows the same architecture — keep it:

1. **One ledger, many mechanics** — new mechanics *read* `LoyaltyPoints` via a minimal interface; they don't fork its state
2. **Issuer gate for giving, open access for claiming/spending** — the business attests, the user self-serves
3. **Events for everything** — every state change emits; the event stream is the analytics feed
4. **Solvency by design** — anything that issues value must have a cap or a budget argument
5. **Comments teach** — code in this org is read aloud in sessions; write comments for the person hearing Solidity for the first time
6. **No surprise dependencies** — OpenZeppelin is fine when the standard is the point; otherwise keep it plain

## Code style, quickly

- Solidity `^0.8.24`, NatSpec (`///`) on every public function
- Names say what they are: `earnPoints`, not `procRwd`
- Tests mirror behaviours, not functions — name them like `test_StreakGraceAndRecord`
- Docs: plain language first, jargon second, one command per line in COMMANDS-style files

## Recognition & progression

Merged contributions are tracked and count toward your **L1 → L5 progression** in the technical portfolio: consistent, reviewed, shipped work is how collaborators become members and members become core. Meaningful contributions get shout-outs in the weekly Friday review and the community channels.

## Questions & help

- **Discord tech channel** — fastest answer, and your question probably helps ten silent people
- **Issues** on this repo — for anything about the code itself
- **Maintainer:** Scotch — Technical Lead, team1 Kenya

*One team. One mission. Ship things people can verify.* 🔺
