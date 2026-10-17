# ustc-testnet-1 (TESTNET ONLY)

Validator join kit for the USTC staking testnet. Tokens have no value. Not mainnet.
Full validator guide: [VALIDATORS.md](./VALIDATORS.md). End-user guide: [HOW-TO-TEST.md](./HOW-TO-TEST.md).

```text
USTC staking TESTNET (ustc-testnet-1) - validator join kit. Testnet only; tokens have no value.
  curl -fsSLO https://35-209-120-74.sslip.io/join/join-ustc-testnet.sh
  sha256sum -c <(grep join-ustc-testnet.sh <(curl -fsSL https://35-209-120-74.sslip.io/join/SHA256SUMS))
  MONIKER=my-node bash join-ustc-testnet.sh install      # add SYSTEMD=1 to run as a service (then do NOT run start)
  bash join-ustc-testnet.sh start                        # foreground only; with SYSTEMD=1: sudo systemctl status ustc-testnet
  bash join-ustc-testnet.sh status                       # wait for "catching_up":false (a few minutes)
  KEY=validator bash join-ustc-testnet.sh create-validator
  KEY=validator bash join-ustc-testnet.sh unjail         # after a downtime jail (600 s)
Env: MONIKER NODE_HOME KEY KEYRING SYSTEMD=1 PORT_OFFSET (shift all ports, e.g. 100) SELF_BOND
Peer: 23c7fe447532302e7a9cce51b1e8e48afda8371f@35.209.120.74:26656   Min gas: 28.325uluna   Ports: open 26656 only
RPC https://35-209-120-74.sslip.io/rpc  LCD https://35-209-120-74.sslip.io/lcd  Faucet https://35-209-120-74.sslip.io/faucet
Binaries: https://github.com/LunaClassicDAO/ustc-testnet-1/releases/tag/v1.1  (terrad @ classic-terra/core 35d68fe, verify with SHA256SUMS)
Validator guide: https://35-209-120-74.sslip.io/join/VALIDATORS.md
End-user guide:  https://35-209-120-74.sslip.io/join/HOW-TO-TEST.md
Keplr chain:     https://35-209-120-74.sslip.io/join/keplr-chain.json
Validator grant requests / peers: https://github.com/LunaClassicDAO/ustc-testnet-1/issues
```
