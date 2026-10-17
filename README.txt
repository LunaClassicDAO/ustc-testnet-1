USTC staking TESTNET (ustc-testnet-1) - validator join kit. Testnet only; tokens have no value.
  curl -fsSLO https://35-209-120-74.sslip.io/join/join-ustc-testnet.sh
  sha256sum -c <(grep join-ustc-testnet.sh <(curl -fsSL https://35-209-120-74.sslip.io/join/SHA256SUMS))
  MONIKER=my-node bash join-ustc-testnet.sh install      # add SYSTEMD=1 to run as a service
  bash join-ustc-testnet.sh start                        # or: sudo systemctl status ustc-testnet
  bash join-ustc-testnet.sh status                       # wait for "catching_up":false
  KEY=validator bash join-ustc-testnet.sh create-validator
Peer: 23c7fe447532302e7a9cce51b1e8e48afda8371f@35.209.120.74:26656   Min gas: 28.325uluna
RPC https://35-209-120-74.sslip.io/rpc  LCD https://35-209-120-74.sslip.io/lcd  Faucet https://35-209-120-74.sslip.io/faucet
Binaries: https://github.com/LunaClassicDAO/ustc-testnet-1/releases/tag/v1
Guide: docs/ustc-testnet-validators.md in LunaClassicDAO/v0-lunaclassic-alliance-dashboard-27
