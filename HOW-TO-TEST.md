# How to test the USTC staking testnet (`ustc-testnet-1`)

**Testnet only. Tokens have no value.** Nothing here touches Terra Classic mainnet (columbus-5).
Website: https://v0-lunaclassic-alliance-dashboard.vercel.app/alliance/pools

| | |
|---|---|
| Chain ID | `ustc-testnet-1` |
| RPC | `https://35-209-120-74.sslip.io/rpc` |
| LCD (REST) | `https://35-209-120-74.sslip.io/lcd` |
| Faucet | https://35-209-120-74.sslip.io/faucet |
| Gas price | `28.325uluna` (fees are paid in test LUNC) |
| Coins | LUNC = `uluna`, USTC = `uusd`, 6 decimals, coin type 330 |

## 1. Add the network to Keplr

Open the pools page, expand **USTC Native Staking (Testnet)** and press **Connect Keplr (testnet)**. Keplr asks you to
add "USTC Testnet (ustc-testnet-1)". Approve it. Use a fresh test wallet, not your mainnet one.

The exact chain config the site suggests is published at https://35-209-120-74.sslip.io/join/keplr-chain.json
(chain ID `ustc-testnet-1`, coin type 330, prefix `terra`, LUNC `uluna` / USTC `uusd` with 6 decimals, fees in
`uluna` at 28.325). Station: add a custom network with the same chain ID, LCD and gas price. Signing on the site uses Keplr.

## 2. Get test tokens

Paste your `terra1…` address into the [faucet](https://35-209-120-74.sslip.io/faucet). You get **50,000 USTC + 50,000 LUNC**,
once per address and once per IP every 24 h. The faucet closes when 50,000,000 USTC is staked in total.

## 3. Stake USTC

In the USTC card choose a lock tier, enter an amount and press **Stake**. The tiers are numbered in the order the chain
defines them (`/lcd/terra/ustcstaking/v1/params`), not by length:

| Tier | Lock (unbonding) | Reward multiplier |
|---|---|---|
| 1 | 21 days | 1.0× |
| 2 | 1 hour | 1.1× |
| 3 | 7 days | 1.25× |

These are testnet settings. The 1-hour tier lets testers finish a full stake → unbond → withdraw cycle in about an
hour, and it pays 1.1×, more than the 21-day tier.

Your position appears under **Your positions** with pending rewards that grow every block.

* **Claim** pays out pending USTC rewards.
* **Begin unbonding** stops rewards and starts the tier's lock period; **Withdraw** returns the USTC once it unlocks.
* The APR shows a dash until 100,000 USTC is staked in total, because with a fixed daily release a tiny pool gives
  meaningless numbers. Rewards are 41,095.89 USTC/day from a 15M USTC pool (about one year).

## 4. LUNC boost pool

Expand the **Native Tokens Pool** card. The **LUNC Boost Pool (Testnet)** panel uses the same Keplr connection:

* **Deposit** test LUNC; rewards accrue in test USTC every second at a fixed rate from a funded reserve.
* **Claim rewards** pays out pending USTC.
* **Withdraw** queues your LUNC for a short unbonding period (60 s on testnet), then **Collect withdrawn LUNC**.
* The faucet gives 50,000 LUNC, enough to deposit a meaningful amount (keep a few LUNC for fees). Rewards are shared
  with everyone else in the pool, so small deposits earn small amounts.
* **Burn tax:** the Terra Classic burn tax (0.5% on this testnet, capped at 1 LUNC / 1 USTC per send) applies to the LUNC you deposit and to the coins the
  contract pays out, so you receive slightly less than the gross amount. The faucet's own payouts are taxed too
  (you receive about 49,999 LUNC + 49,999 USTC).

## What to test (please report tx hashes)

Open an issue at https://github.com/LunaClassicDAO/ustc-testnet-1/issues with the tx hash, what you did and what you
expected. Useful checks:

- [ ] Add the network in Keplr and claim from the faucet.
- [ ] Stake on **each** tier (1, 2, 3) and check the multiplier on the position.
- [ ] Claim rewards on a position; the claimed amount should match "pending" (minus the burn tax).
- [ ] Begin unbonding; rewards must stop for that position.
- [ ] Withdraw a Tier 2 position after its 1-hour lock ends.
- [ ] Boost pool: deposit, claim, withdraw, then "Collect withdrawn LUNC" after about 60 s.
- [ ] Edge cases: amounts with more than 6 decimals, 0, more than your balance, staking past the 50M cap;
      withdrawing more than you deposited. Each should be refused with a clear message.
- [ ] Check the burn-tax effect on what you receive.

## Known limits

* One validator (`alliance-val-1`) and one public node on a small free-tier VM. If it restarts, the site shows
  "Testnet not available" for up to a minute; just retry. Validators are welcome: see https://35-209-120-74.sslip.io/join/VALIDATORS.md.
* The endpoints use an `sslip.io` hostname; if your DNS blocks sslip.io the endpoints will not resolve.
* No block explorer yet; the site shows transaction hashes, which you can look up at
  `https://35-209-120-74.sslip.io/lcd/cosmos/tx/v1beta1/txs/<hash>`.
* The header totals on the pools page include testnet figures (marked "incl. testnet"); testnet USD values use real
  CoinGecko prices for display only.
* The boost pool contract is not audited and exists only on testnet. Mainnet needs an audit and a governance decision.
* The validator join kit is tested on x86_64 Linux; ARM builds from source and is untested.
