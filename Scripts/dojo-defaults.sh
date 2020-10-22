#!/bin/bash
# shellcheck disable=SC2034

#
# Dojo Existing Configuration Values
#
if [ -f "${DOJO_PATH}"/conf/docker-node.conf ]; then
    NODE_API_KEY=$(grep NODE_API_KEY "${DOJO_PATH}"/conf/docker-node.conf | cut -d '=' -f2)
    NODE_ADMIN_KEY=$(grep NODE_ADMIN_KEY "${DOJO_PATH}"/conf/docker-node.conf | cut -d '=' -f2)
fi

if [ -f "${DOJO_PATH}"/conf/docker-bitcoind.conf ]; then
    RPC_PASS_CONF=$(grep BITCOIND_RPC_PASSWORD "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
    RPC_USER_CONF=$(grep BITCOIND_RPC_USER "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
    RPC_IP=$(grep BITCOIND_IP "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
    RPC_PORT=$(grep BITCOIND_RPC_PORT "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
fi

if [ -f "${DOJO_PATH}"/conf/docker-explorer.conf ]; then
    EXPLORER_KEY=$(grep EXPLORER_KEY "${DOJO_PATH}"/conf/docker-explorer.conf | cut -d '=' -f2)
fi

# Whirlpool
if sudo test -f "${DOCKER_VOLUME_WP}"/_data/.whirlpool-cli/whirlpool-cli-config.properties; then
    WHIRLPOOL_API_KEY=$(sudo grep cli.apiKey "${DOCKER_VOLUME_WP}"/_data/.whirlpool-cli/whirlpool-cli-config.properties | cut -d '=' -f2)
fi

#
# Tor Hidden Service Addresses
#

# Bitcoind
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv2bitcoind; then
    V2_ADDR_BITCOIN=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv2bitcoind/hostname)
fi

# Bitcoin Explorer
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3explorer; then
    V3_ADDR_EXPLORER=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3explorer/hostname)
fi

# Dojo Maintanance Tool
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3dojo; then
    V3_ADDR_API=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3dojo/hostname)
fi

# Electrum Server
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3electrs; then
    V3_ADDR_ELECTRS=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3electrs/hostname)
fi

# Whirlpool
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3whirlpool; then
    V3_ADDR_WHIRLPOOL=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3whirlpool/hostname)
fi

# Mempool
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3mempool; then
    V3_ADDR_MEMPOOL=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3mempool/hostname)
fi