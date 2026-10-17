# Join ustc-testnet-1 as a validator (TESTNET ONLY)

Tokens on this chain have no value. Nothing here touches mainnet (columbus-5).
Public copies: https://35-209-120-74.sslip.io/join/VALIDATORS.md and https://github.com/LunaClassicDAO/ustc-testnet-1

| Item | Value |
|---|---|
| Chain ID | `ustc-testnet-1` |
| Binary | classic-terra/core `ustc_staking` @ `35d68fe1b3eb811c27e8bf3f398d5cc197897229` + libwasmvm v3.0.8 (SDK v0.53.6, CometBFT v0.38, go1.24.7) |
| Prebuilt (linux/amd64, glibc ≥ 2.34) | https://github.com/LunaClassicDAO/ustc-testnet-1/releases/tag/v1.1 (v1 kept; same binary) |
| arm64 | the script builds from source (needs git, gcc, Go 1.24.x); untested |
| Genesis | https://35-209-120-74.sslip.io/join/genesis.json, sha256 `4c0639a7a8feb7be4a0d3a9b2b2dbef716e57ac412d528bdfd133753c8c1e495` |
| Peer | `23c7fe447532302e7a9cce51b1e8e48afda8371f@35.209.120.74:26656` |
| Min gas price | `28.325uluna` |
| Public RPC / LCD | `https://35-209-120-74.sslip.io/rpc` · `https://35-209-120-74.sslip.io/lcd` (CLI: `--node https://35-209-120-74.sslip.io:443/rpc`) |
| Faucet | https://35-209-120-74.sslip.io/faucet (50,000 USTC + 50,000 LUNC per address / IP every 24 h) |
| Keplr chain JSON | https://35-209-120-74.sslip.io/join/keplr-chain.json (same config the website suggests) |
| End-user guide | https://35-209-120-74.sslip.io/join/HOW-TO-TEST.md |

## Quick start

```bash
curl -fsSLO https://35-209-120-74.sslip.io/join/join-ustc-testnet.sh
sha256sum -c <(grep join-ustc-testnet.sh <(curl -fsSL https://35-209-120-74.sslip.io/join/SHA256SUMS))
MONIKER=my-node bash join-ustc-testnet.sh install         # add SYSTEMD=1 to install + start a systemd service
bash join-ustc-testnet.sh start                           # foreground; SKIP this if you used SYSTEMD=1
bash join-ustc-testnet.sh status                          # repeat until "catching_up":false
KEY=validator bash join-ustc-testnet.sh create-validator  # creates the key if missing (write down the mnemonic)
```

Options (env vars): `NODE_HOME` (default `~/.ustc-testnet`), `BIN_DIR` (default `~/ustc-testnet-bin`), `KEYRING`
(default `file`), `KEY` (default `validator`), `SYSTEMD=1`, `PORT_OFFSET` (shift all ports, e.g. `100`),
`SELF_BOND` (uluna; default = balance − 20 LUNC kept for fees).

**systemd:** with `SYSTEMD=1` the node already runs as `ustc-testnet.service` (`sudo systemctl status ustc-testnet`,
logs: `journalctl -u ustc-testnet -f`). Do not also run `start`, or two processes fight over the same home.

## Sync

Blocks are kept from genesis, so plain block sync works; no snapshot or state sync is needed. At the current height
(about 9k blocks, chain started 2026-10-16) a fresh node syncs in a few minutes (our test: about 2 minutes).
Run `bash join-ustc-testnet.sh status` and wait for `"catching_up":false` before `create-validator`; the script refuses
to create the validator while the node is still catching up.

## Peers

There is one public peer today (the genesis node above) and no seed node. If it is down, new nodes cannot sync.
More persistent peers will be added here as validators join; if your node accepts inbound P2P, share your
`node-id@ip:26656` in a GitHub issue so it can be listed.

## Ports

| Port | Use | Expose? |
|---|---|---|
| 26656 | P2P | inbound optional (recommended, helps others sync) |
| 26657 | CometBFT RPC | keep local |
| 1317 | REST/LCD | keep local |
| 9090 | gRPC | keep local |

`PORT_OFFSET=100` moves all of them (26756, 26757, 1417, 9190) when you already run another node.
Example with ufw:

```bash
sudo ufw allow 22/tcp
sudo ufw allow 26656/tcp      # or 26656+PORT_OFFSET
sudo ufw enable
```

## Operator facts (from the live chain)

* Unbonding period: **21 days**. Max validators: **100**. Min commission: 0 (script uses 5%, max 20%, max change 1%).
* Min self-delegation: **1 uluna** (script default).
* A faucet-funded self-bond (about 49,979 LUNC after keeping 20 LUNC for fees) against the 9,000,000 LUNC on
  `alliance-val-1` is about **0.55%** of voting power.
* **Validator grant:** approved validators can receive a one-time **1,000,000 test LUNC + 10,000 USTC**. Grants are
  approved by Classic DAO admins. Request one by opening an issue at
  https://github.com/LunaClassicDAO/ustc-testnet-1/issues with your `terra1…` address and node moniker.

## Jailing and unjailing

Slashing params: signed-blocks window **100 blocks**, min signed **50%**, downtime jail **600 s**, downtime slash
**1%**, double-sign slash **5%** (tombstoned). With ~5 s blocks, missing about **5 minutes** of blocks jails the
validator for 10 minutes and slashes 1% of its stake. After the 600 s jail has passed:

```bash
KEY=validator bash join-ustc-testnet.sh unjail
# or directly:
~/ustc-testnet-bin/terrad tx slashing unjail --from validator --keyring-backend file --home ~/.ustc-testnet \
  --chain-id ustc-testnet-1 --node tcp://127.0.0.1:26657 --gas auto --gas-adjustment 1.5 --gas-prices 28.325uluna
```

Never run the same validator key on two machines (double-sign = 5% slash and permanent tombstone).
If you stop for good, unbond first (`terrad tx staking unbond …`) so you are not jailed for downtime.

## Verify the binary

The prebuilt `terrad` was built without version ldflags, so `terrad version --long` prints empty fields. Verify by hash
instead (values from `SHA256SUMS`):

```bash
sha256sum ~/ustc-testnet-bin/terrad               # ee2f7416dc643b6bf5b885961c74c7a9faa311965168f43a0214d26bbd45c013
sha256sum ~/ustc-testnet-bin/libwasmvm.x86_64.so  # 6d8e14980be78160caa7b4bdbdc913c87db76756b220a29813d43c7b43cbc841
```

Source: https://github.com/classic-terra/core/tree/35d68fe1b3eb811c27e8bf3f398d5cc197897229 (branch `ustc_staking`).
Tarball `terrad-35d68fe-linux-amd64.tar.gz`: `07a26cfbb24c651b6d093d4cb5851f6d4959c4cb288255a97d5b0403c794d558`.

## Tested

2026-10-17: a fresh node built with this kit on a separate machine (prebuilt amd64 binary, genesis from `/join/`)
block-synced from genesis over p2p `35.209.120.74:26656` in about 2 minutes, then `create-validator` succeeded
(tx `D5E4D0DAA33A61FC436B18153791FE7BBD1A63703AA035A4AAF2ACBB8996928D`) and the validator was bonded. It was unbonded
afterwards (test only).
