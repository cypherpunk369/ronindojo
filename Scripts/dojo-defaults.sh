#!/bin/bash
# shellcheck disable=SC2034,SC2154 source=/dev/null

#
# Dojo Configuration Values
#
test -f "${dojo_path_my_dojo}"/conf/docker-node.conf && . "${dojo_path_my_dojo}"/conf/docker-node.conf

test -f "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf && . "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf

test -f "${dojo_path_my_dojo}"/conf/docker-explorer.conf && . "${dojo_path_my_dojo}"/conf/docker-explorer.conf

# Whirlpool
if sudo test -f "${docker_volume_wp}"/_data/.whirlpool-cli/whirlpool-cli-config.properties; then
    whirlpool_api_key=$(sudo grep cli.apiKey "${docker_volume_wp}"/_data/.whirlpool-cli/whirlpool-cli-config.properties | cut -d '=' -f2)
fi

#
# Tor Hidden Service Addresses
#

# Bitcoind
if sudo test -d "${docker_volume_tor}"/_data/hsv3bitcoind; then
    tor_addr_bitcoind=$(sudo cat "${docker_volume_tor}"/_data/hsv3bitcoind/hostname)
fi

# Bitcoin Explorer
if sudo test -d "${docker_volume_tor}"/_data/hsv3explorer; then
    tor_addr_explorer=$(sudo cat "${docker_volume_tor}"/_data/hsv3explorer/hostname)
fi

# Dojo Maintanance Tool
if sudo test -d "${docker_volume_tor}"/_data/hsv3dojo; then
    tor_addr_dojo_api=$(sudo cat "${docker_volume_tor}"/_data/hsv3dojo/hostname)
fi

# Electrum Server
if sudo test -d "${docker_volume_tor}"/_data/hsv3electrs; then
    tor_addr_electrs=$(sudo cat "${docker_volume_tor}"/_data/hsv3electrs/hostname)
fi

# Whirlpool
if sudo test -d "${docker_volume_tor}"/_data/hsv3whirlpool; then
    tor_addr_whirlpool=$(sudo cat "${docker_volume_tor}"/_data/hsv3whirlpool/hostname)
fi

# Mempool Space Visualizer
if sudo test -d "${docker_volume_tor}"/_data/hsv3mempool; then
    tor_addr_mempool=$(sudo cat "${docker_volume_tor}"/_data/hsv3mempool/hostname)
fi

if [ -d "${dojo_path}" ]; then
    _mempool_version="v$(grep MEMPOOL_API_VERSION_TAG "${dojo_path_my_dojo}"/.env | cut -d '=' -f2)"
fi
