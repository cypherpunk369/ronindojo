#!/bin/bash
# shellcheck source=/dev/null disable=1004,SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if [ ! -f "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf ]; then # new install
    . "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf.tpl
else # existing install so load
    . "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
fi
# Retrieve bitcoind RPC credentials

cat <<EOF > "${dojo_path_my_dojo}"/indexer/electrs.toml
auth = "$BITCOIND_RPC_USER:$BITCOIND_RPC_PASSWORD"
server_banner = "Welcome to your RoninDojo ${ronindojo_version} Electrs Server!"
EOF

chmod 600 "${dojo_path_my_dojo}"/indexer/electrs.toml || exit 1
# create electrs.toml for electrs dockerfile

sed -i "/\if \[ \"\$EXPLORER_INSTALL\" \=\= \"on\" \]\; then/i\
if [ \"\$INDEXER_INSTALL\" == \"on\" ]; then\n\
  tor_options+=(--HiddenServiceDir /var/lib/tor/hsv3electrs)\n\
  tor_options+=(--HiddenServiceVersion 3)\n\
  tor_options+=(--HiddenServicePort \"50001 172.28.1.6:50001\")\n\
  tor_options+=(--HiddenServiceDirGroupReadable 1)\n\
fi\n\
" "${dojo_path_my_dojo}"/tor/restart.sh
# modify tor/restart.sh for electrs hidden service
# using the backslash \ along with sed insert command so that the spaces are not ignored
# we append everything above the EXPLORER if statement

sed -i "/onion() {/a\
if [ \"\$INDEXER_INSTALL\" == \"on\" ]; then\n\
  tor_addr_electrs=\$( docker exec -it tor cat /var/lib/tor/hsv3electrs/hostname )\n\
  echo \"Electrs hidden service address (v3) = \$tor_addr_electrs\"\n\
fi\n\
" "${dojo_path_my_dojo}"/dojo.sh
# modify dojo.sh for electrs
# using the backslash \ along with sed insert command so that the spaces are not ignored

sed -i \
  -e 's/--indexer-rpc-addr/--electrum-rpc-addr/' \
  -e 's/--daemon-p2p-addr/a\  --daemon-rpc-addr="$BITCOIND_IP:$BITCOIND_RPC_PORT"' \
  -e 's/--jsonrpc-import/d' \
  -e '/--indexer-http-addr*/d' \
  -e '/--cookie=.*$/d' \
  -e '/--txid-limit=.*$/d' \
  -e 's/--blocktxids-cache-size-mb=.*$/--index-lookup-limit="$INDEXER_TXID_LIMIT"/' \
  -e 's/^addrindexrs/electrs/' "${dojo_path_my_dojo}"/indexer/restart.sh
# modify indexer/restart.sh for electrs

cp "${dojo_path_my_dojo}"/indexer/electrs.Dockerfile.tpl Dockerfile
# replace indexer Dockerfile for electrs support