#!/bin/bash
# shellcheck disable=SC2034

#
# Package dependencies associative array
#
declare -A package_dependencies=(
    [java]=jdk11-openjdk
    [tor]=tor
    [python3]=python3
    [fail2ban-python]=fail2ban
    [ifconfig]=net-tools
    [htop]=htop
    [vim]=vim
    [unzip]=unzip
    [which]=which
    [wget]=wget
    [docker]=docker
    [docker-compose]=docker-compose
    [ufw]=ufw
    [rsync]=rsync
    [npm]=npm
    [node]=nodejs
)

#
# Terminal Colors
#
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)
# No Color

#
# Install Defaults
#
RONIN_DOJO_BRANCH="" # defaults to master

DOJO_PATH="$HOME/dojo/docker/my-dojo"

SAMOURAI_REPO='https://code.samourai.io/ronindojo/samourai-dojo.git'
SAMOURAI_COMMITISH="v1.7.0" # empty defaults to master

#
# Backend GUI
#
GUI_API=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
GUI_JWT=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

#
# Filesystem Defaults
#
INSTALL_DIR="/mnt/usb"
INSTALL_DIR_TOR="${INSTALL_DIR}/tor"
INSTALL_DIR_SWAP="${INSTALL_DIR}/swapfile"
INSTALL_DIR_UNINSTALL="${INSTALL_DIR}/uninstall-salvage"
INSTALL_DIR_SYSTEM="${INSTALL_DIR}/system-setup-salvage"

INSTALL_DIR_DOCKER="${INSTALL_DIR}/docker"
DOCKER_VOLUMES="${INSTALL_DIR_DOCKER}/volumes"
DOCKER_VOLUME_TOR="${DOCKER_VOLUMES}/my-dojo_data-tor"
DOCKER_VOLUME_WP="${DOCKER_VOLUMES}/my-dojo_data-whirlpool"
DOCKER_VOLUME_BITCOIND="${DOCKER_VOLUMES}/my-dojo_data-bitcoind"

SALVAGE_MOUNT="/mnt/usb1"
SALVAGE_MOUNT_SYSTEM="${SALVAGE_MOUNT}/system-setup-salvage"
SALVAGE_DIR="/mnt/salvage"
SALVAGE_DIR_UNINSTALL="${SALVAGE_DIR}/uninstall-salvage"
SALVAGE_DIR_SYSTEM="${SALVAGE_DIR}/system-setup-salvage"
SALVAGE_DIR_BITCOIND="${SALVAGE_DIR}/docker/volumes/my-dojo_data-bitcoind"

# Workaround when on x86 systems and autologin is enabled for the user account
if [ "$(getent group 1000 | cut -d ':' -f1)" = "autologin" ]; then
    USER=$(getent group 1000 | cut -d ':' -f4)
else
    USER=$(getent group 1000 | cut -d ':' -f1)
fi

#
# Dialog Variables
#
HEIGHT=22
WIDTH=76
CHOICE_HEIGHT=16
TITLE="RoninDojo"
MENU="Choose one of the following options:"

#
# Dojo Existing Configuration Values
#
if [ -f "${DOJO_PATH}"/conf/docker-node.conf ]; then
    NODE_API_KEY_TOR=$(grep NODE_API_KEY "${DOJO_PATH}"/conf/docker-node.conf | cut -d '=' -f2)
    NODE_ADMIN_KEY_TOR=$(grep NODE_ADMIN_KEY "${DOJO_PATH}"/conf/docker-node.conf | cut -d '=' -f2)
fi

#
# Dojo Docker Settings
#
# bitcoind
RPC_PASS=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)
RPC_USER=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

if [ -f "${DOJO_PATH}"/conf/docker-bitcoind.conf ]; then
    RPC_PASS_CONF=$(grep BITCOIND_RPC_PASSWORD "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
    RPC_USER_CONF=$(grep BITCOIND_RPC_USER "${DOJO_PATH}"/conf/docker-bitcoind.conf | cut -d '=' -f2)
fi

# node
NODE_API_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
NODE_JWT_SECRET=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
NODE_ADMIN_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 32 | head -n 1)

# mysql
MYSQL_ROOT_PASSWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)
MYSQL_USER=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 12 | head -n 1)
MYSQL_PASSWORD=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 64 | head -n 1)

# explorer
EXPLORER_KEY=$(tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w 16 | head -n 1)
if [ -f "${DOJO_PATH}"/conf/docker-explorer.conf ]; then
    EXPLORER_KEY_TOR=$(grep EXPLORER_KEY "${DOJO_PATH}"/conf/docker-explorer.conf | cut -d '=' -f2)
fi

# whirlpool
if sudo test -f "${DOCKER_VOLUME_WP}"/_data/.whirlpool-cli/whirlpool-cli-config.properties; then
    WHIRLPOOL_API_KEY=$(sudo grep cli.apiKey "${DOCKER_VOLUME_WP}"/_data/.whirlpool-cli/whirlpool-cli-config.properties | cut -d '=' -f2)
fi

#
# Tor Hidden Service Addresses
#
# dojo maintanance tool
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3dojo; then
    V3_ADDR_API=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3dojo/hostname)
fi

# whirlpool
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3whirlpool; then
    V3_ADDR_WHIRLPOOL=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3whirlpool/hostname)
fi

# explorer
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3explorer; then
    V3_ADDR_EXPLORER=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3explorer/hostname)
fi

# electrum server
if sudo test -d "${DOCKER_VOLUME_TOR}"/_data/hsv3electrs; then
    V3_ADDR_ELECTRS=$(sudo cat "${DOCKER_VOLUME_TOR}"/_data/hsv3electrs/hostname)
fi

# ronindojo menu paths
RONIN_DOJO_MENU="$HOME/RoninDojo/Scripts/Menu/menu-dojo.sh"
RONIN_DOJO_MENU2="$HOME/RoninDojo/Scripts/Menu/menu-dojo2.sh"
RONIN_WHIRLPOOL_MENU="$HOME/RoninDojo/Scripts/Menu/menu-whirlpool.sh"
