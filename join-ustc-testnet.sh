#!/usr/bin/env bash
# Join the USTC staking TESTNET (ustc-testnet-1). Testnet only: tokens have no value.
# Usage:
#   MONIKER=my-node bash join-ustc-testnet.sh install     # install terrad, init, genesis, peers, gas price
#   bash join-ustc-testnet.sh start                       # run the node in the foreground (skip if installed with SYSTEMD=1)
#   bash join-ustc-testnet.sh status                      # height + catching_up
#   KEY=mykey bash join-ustc-testnet.sh create-validator  # after catching_up=false and the key is funded
#   KEY=mykey bash join-ustc-testnet.sh unjail            # after a downtime jail (600 s) has passed
# Env: MONIKER, NODE_HOME (default ~/.ustc-testnet), BIN_DIR (default ~/ustc-testnet-bin), KEY (default validator),
#      KEYRING (default file), SYSTEMD=1 to install a systemd unit (needs sudo), PORT_OFFSET (default 0).
set -euo pipefail

CHAIN_ID="ustc-testnet-1"
COMMIT="35d68fe1b3eb811c27e8bf3f398d5cc197897229"
RELEASE_URL="https://github.com/LunaClassicDAO/ustc-testnet-1/releases/download/v1.1"
TARBALL="terrad-35d68fe-linux-amd64.tar.gz"
TARBALL_SHA256="07a26cfbb24c651b6d093d4cb5851f6d4959c4cb288255a97d5b0403c794d558"
GENESIS_URL="https://35-209-120-74.sslip.io/join/genesis.json"
GENESIS_SHA256="4c0639a7a8feb7be4a0d3a9b2b2dbef716e57ac412d528bdfd133753c8c1e495"
PEERS="23c7fe447532302e7a9cce51b1e8e48afda8371f@35.209.120.74:26656"
MIN_GAS="28.325uluna"
PUBLIC_RPC="https://35-209-120-74.sslip.io:443/rpc"
FAUCET="https://35-209-120-74.sslip.io/faucet"

NODE_HOME="${NODE_HOME:-$HOME/.ustc-testnet}"
BIN_DIR="${BIN_DIR:-$HOME/ustc-testnet-bin}"
KEY="${KEY:-validator}"
KEYRING="${KEYRING:-file}"
PORT_OFFSET="${PORT_OFFSET:-0}"
TERRAD="$BIN_DIR/terrad"
export LD_LIBRARY_PATH="$BIN_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "missing '$1' (install it first)"; }
sha_ok() { echo "$2  $1" | sha256sum -c --quiet - ; }

install_binary() {
  mkdir -p "$BIN_DIR"
  if [ -x "$TERRAD" ] && "$TERRAD" version >/dev/null 2>&1; then say "terrad already installed in $BIN_DIR"; return; fi
  case "$(uname -m)" in
    x86_64)
      say "Downloading prebuilt terrad ($COMMIT) + libwasmvm v3.0.8"
      local tmp; tmp="$(mktemp -d)"
      curl -fL --retry 3 -o "$tmp/$TARBALL" "$RELEASE_URL/$TARBALL"
      sha_ok "$tmp/$TARBALL" "$TARBALL_SHA256" || die "checksum mismatch for $TARBALL"
      tar xzf "$tmp/$TARBALL" -C "$tmp"
      install -m 755 "$tmp/terrad-35d68fe-linux-amd64/terrad" "$BIN_DIR/terrad"
      install -m 644 "$tmp/terrad-35d68fe-linux-amd64/libwasmvm.x86_64.so" "$BIN_DIR/libwasmvm.x86_64.so"
      rm -rf "$tmp"
      ;;
    aarch64|arm64)
      say "arm64: building terrad from source (needs git, make, gcc and Go 1.24.x)"
      need git; need go; need gcc
      local src="$BIN_DIR/src-core"
      [ -d "$src/.git" ] || git clone https://github.com/classic-terra/core.git "$src"
      git -C "$src" fetch origin ustc_staking && git -C "$src" checkout -q "$COMMIT"
      (cd "$src" && CGO_ENABLED=1 go build -o "$BIN_DIR/terrad" ./cmd/terrad)
      local lib; lib="$(cd "$src" && go list -m -f '{{.Dir}}' github.com/CosmWasm/wasmvm/v3)/internal/api/libwasmvm.aarch64.so"
      [ -f "$lib" ] || die "libwasmvm.aarch64.so not found at $lib"
      install -m 644 "$lib" "$BIN_DIR/libwasmvm.aarch64.so"
      ;;
    *) die "unsupported architecture $(uname -m)";;
  esac
  "$TERRAD" version >/dev/null 2>&1 || die "terrad does not run (glibc >= 2.34 required for the prebuilt binary: Ubuntu 22.04+/Debian 12+)"
  say "terrad installed: $TERRAD"
}

configure() {
  [ -n "${MONIKER:-}" ] || die "set MONIKER=<your node name>"
  if [ ! -f "$NODE_HOME/config/config.toml" ]; then
    say "Initialising $NODE_HOME"
    "$TERRAD" init "$MONIKER" --chain-id "$CHAIN_ID" --home "$NODE_HOME" >/dev/null 2>&1
  fi
  say "Fetching genesis"
  curl -fsSL --retry 3 -o "$NODE_HOME/config/genesis.json" "$GENESIS_URL"
  sha_ok "$NODE_HOME/config/genesis.json" "$GENESIS_SHA256" || die "genesis checksum mismatch"
  local c="$NODE_HOME/config/config.toml" a="$NODE_HOME/config/app.toml"
  sed -i "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" "$c"
  sed -i "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"$MIN_GAS\"|" "$a"
  sed -i 's|^pruning *=.*|pruning = "custom"|; s|^pruning-keep-recent *=.*|pruning-keep-recent = "10000"|; s|^pruning-interval *=.*|pruning-interval = "10"|' "$a"
  if [ "$PORT_OFFSET" != "0" ]; then
    local o="$PORT_OFFSET"
    sed -i "s|tcp://127.0.0.1:26657|tcp://127.0.0.1:$((26657+o))|; s|tcp://0.0.0.0:26656|tcp://0.0.0.0:$((26656+o))|; s|localhost:6060|localhost:$((6060+o))|" "$c"
    sed -i "s|tcp://localhost:1317|tcp://localhost:$((1317+o))|; s|localhost:9090|localhost:$((9090+o))|; s|0.0.0.0:9090|0.0.0.0:$((9090+o))|" "$a"
  fi
  if [ "${SYSTEMD:-0}" = "1" ]; then
    say "Installing systemd unit ustc-testnet.service"
    sudo tee /etc/systemd/system/ustc-testnet.service >/dev/null <<UNIT
[Unit]
Description=USTC staking testnet node ($CHAIN_ID)
After=network-online.target
[Service]
User=$USER
Environment=LD_LIBRARY_PATH=$BIN_DIR
ExecStart=$TERRAD start --home $NODE_HOME
Restart=always
RestartSec=5
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
UNIT
    sudo systemctl daemon-reload && sudo systemctl enable --now ustc-testnet
  fi
  local rpcport=$((26657+PORT_OFFSET))
  say "Done. Node ID: $("$TERRAD" comet show-node-id --home "$NODE_HOME")"
  if [ "${SYSTEMD:-0}" = "1" ]; then
    echo "Already running via systemd (sudo systemctl status ustc-testnet). Do NOT also run 'bash $0 start'."
  else
    echo "Start: bash $0 start"
  fi
  echo "Status: bash $0 status   (wait for \"catching_up\":false before create-validator; a few minutes at the current height)"
  echo "Open TCP $((26656+PORT_OFFSET)) inbound so other nodes can reach you (optional for a validator)."
}

status() {
  local rpcport=$((26657+PORT_OFFSET))
  local out; out="$(curl -s "localhost:$rpcport/status")" || die "node not reachable on $rpcport"
  echo "$out" | grep -oE '"(latest_block_height|catching_up)":("[0-9]+"|true|false)' || die "node not reachable on $rpcport"
  if echo "$out" | grep -q '"catching_up":true'; then echo "Still syncing. Compare with the public height: curl -s $PUBLIC_RPC/status"; fi
}

create_validator() {
  local rpcport=$((26657+PORT_OFFSET)) node="tcp://127.0.0.1:$((26657+PORT_OFFSET))"
  curl -s "localhost:$rpcport/status" | grep -q '"catching_up":false' || die "node is still syncing (catching_up=true); wait and retry"
  if ! "$TERRAD" keys show "$KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" >/dev/null 2>&1; then
    say "Creating key '$KEY' (keyring: $KEYRING). WRITE DOWN THE MNEMONIC SHOWN BELOW."
    "$TERRAD" keys add "$KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME"
  fi
  local addr; addr="$("$TERRAD" keys show "$KEY" -a --keyring-backend "$KEYRING" --home "$NODE_HOME")"
  local bal; bal="$("$TERRAD" q bank balance "$addr" uluna --node "$node" -o json 2>/dev/null | grep -oE '"amount":"[0-9]+"' | grep -oE '[0-9]+' || echo 0)"
  local amount="${SELF_BOND:-}"
  if [ -z "$amount" ]; then amount=$(( bal > 20000000 ? bal - 20000000 : 0 )); fi  # keep 20 LUNC for fees
  [ "$amount" -gt 0 ] || die "$addr has $bal uluna. Fund it first: faucet $FAUCET (50,000 LUNC) or request a validator grant: https://github.com/LunaClassicDAO/ustc-testnet-1/issues"
  local f; f="$(mktemp)"
  cat > "$f" <<JSON
{"pubkey": $("$TERRAD" comet show-validator --home "$NODE_HOME"),
 "amount": "${amount}uluna", "moniker": "${MONIKER:-$("$TERRAD" config get config moniker --home "$NODE_HOME" 2>/dev/null | tr -d '"' || echo validator)}",
 "commission-rate": "0.05", "commission-max-rate": "0.20", "commission-max-change-rate": "0.01", "min-self-delegation": "1"}
JSON
  say "Creating validator from $addr with self-bond ${amount}uluna"
  "$TERRAD" tx staking create-validator "$f" --from "$KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" \
    --chain-id "$CHAIN_ID" --node "$node" --gas auto --gas-adjustment 1.5 --gas-prices "$MIN_GAS" -y
  rm -f "$f"
  echo "Check: $TERRAD q staking validator \$($TERRAD keys show $KEY --bech val -a --keyring-backend $KEYRING --home $NODE_HOME) --node $node"
}

unjail() {
  local node="tcp://127.0.0.1:$((26657+PORT_OFFSET))"
  "$TERRAD" tx slashing unjail --from "$KEY" --keyring-backend "$KEYRING" --home "$NODE_HOME" \
    --chain-id "$CHAIN_ID" --node "$node" --gas auto --gas-adjustment 1.5 --gas-prices "$MIN_GAS" -y
}

case "${1:-install}" in
  install) need curl; need sha256sum; install_binary; configure;;
  start) exec "$TERRAD" start --home "$NODE_HOME";;
  status) status;;
  create-validator) create_validator;;
  unjail) unjail;;
  *) die "usage: $0 install|start|status|create-validator|unjail";;
esac
