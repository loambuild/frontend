#!/bin/bash

# read .env file, but prefer explicitly set environment variables
IFS=$'\n'
for l in $(cat .env); do
    IFS='=' read -ra VARVAL <<< "$l"
    # If variable with such name already exists, preserves its value
    eval "export ${VARVAL[0]}=\${${VARVAL[0]}:-${VARVAL[1]}}"
done
unset IFS

# a good-enough implementation of __dirname from https://blog.daveeddy.com/2015/04/13/dirname-case-study-for-bash-and-node/
dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# variable for later setting pinned version of soroban in "$(dirname/target/bin/soroban)"
soroban="soroban"

echo "###################### Initializing ########################"

NETWORK_STATUS=$(curl -s -X POST "$SOROBAN_RPC_URL" -H "Content-Type: application/json" -d '{ "jsonrpc": "2.0", "id": 8675309, "method": "getHealth" }' | sed 's/.*"status":"\(.*\)".*/\1/')

echo Network
echo "  RPC:        $SOROBAN_RPC_URL"
echo "  Passphrase: \"$SOROBAN_PASSPHRASE\""
echo "  Status:     $NETWORK_STATUS"

if [[ "$NETWORK_STATUS" != "healthy" ]]; then
  echo "Network is not healthy (not running?), exiting"
  exit 1
fi

# Print command before executing, from https://stackoverflow.com/a/23342259/249801
# Discussion: https://github.com/stellar/soroban-tools/pull/1034#pullrequestreview-1690667116
exe() { echo"${@/eval/}" ; "$@" ; }

function fund_all() {
  exe eval "$soroban keys generate $SOROBAN_ACCOUNT"
  exe eval "$soroban keys fund $SOROBAN_ACCOUNT"
}

function build_all() {
  rm $dirname/target/wasm32-unknown-unknown/release/*.wasm
  rm $dirname/target/wasm32-unknown-unknown/release/*.d
  exe eval "$soroban contract build"
}

function deploy() {
  exe eval "($soroban contract deploy --wasm $1 --ignore-checks) > $dirname/.soroban/contract-ids/$(filename_no_extension $1).txt"
}
function filename_no_extension() {
  echo "$(basename $1 | cut -f 1 -d '.')"
}
function deploy_all() {
  mkdir -p $dirname/.soroban/contract-ids
  for wasm in $(ls $dirname/target/wasm32-unknown-unknown/release/*.wasm); do
    deploy $wasm
  done
}

# TODO: extend TTL of the contracts, but check that the wasm-hash is up to date. If it's not, upgrade or redeploy, then re-generate the bindings.

function bind() {
  exe eval "$soroban contract bindings typescript --contract-id $(cat $1) --output-dir $dirname/packages/$(filename_no_extension $1) --overwrite"
}
function bind_all() {
  for contract in $(ls $dirname/.soroban/contract-ids/*); do
    # if something goes wrong with deploy, the file will be empty
    if [ $(cat $contract | wc -c | xargs) -gt 0 ]; then
      bind $contract
    fi
  done
}

function import() {
  echo "overwrite $dirname/src/contracts/$1.ts"
  cat << EOF > $dirname/src/contracts/$1.ts
import * as Client from '$1';
import { rpcUrl } from './util';

export default new Client.Contract({
  ...Client.networks.standalone,
  rpcUrl,
});
EOF
}

function import_all() {
  for contract in $(ls $dirname/.soroban/contract-ids/*); do
    import $(filename_no_extension $contract)
  done
}

fund_all
build_all
deploy_all
bind_all
import_all
