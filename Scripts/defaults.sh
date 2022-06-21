#!/bin/bash
# shellcheck disable=SC2034

# RoninDojo Version tag
if [ -d "$HOME"/RoninDojo/.git ]; then
    cd "$HOME"/RoninDojo || exit
    ronindojo_version=$(git describe --tags)
fi

#
# Package dependencies associative array
#
declare -A package_dependencies=(
    [avahi-daemon]=avahi
    [pm2]=pm2
    [nginx]=nginx
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
    [node]=nodejs-lts-fermium
    [npm]=npm
    [jq]=jq
    [pipenv]=python-pipenv
    [sgdisk]=gptfdisk
    [gcc]=gcc
)

#
# OS package ignore list
#
declare -a pkg_ignore=(
    tor
    docker
    docker-compose
    bridge-utils
)

#
# Dialog Variables
#
HEIGHT=22
WIDTH=76
CHOICE_HEIGHT=16
TITLE="RoninDojo ${ronindojo_version}"
MENU="Choose one of the following menu options:"

# RoninDojo Paths
ronin_dir="$HOME/RoninDojo"
ronin_gpio_dir="$ronin_dir/GPIO"
ronin_scripts_dir="$ronin_dir/Scripts"
ronin_menu_dir="$ronin_scripts_dir/Menu"

# RoninDojo menu Paths
ronin_applications_menu="$ronin_menu_dir/menu-applications.sh"
ronin_applications_manage_menu="$ronin_menu_dir/menu-applications-manage.sh"
ronin_credentials_menu="$ronin_menu_dir/menu-credentials.sh"
ronin_boltzmann_menu="$ronin_menu_dir/menu-boltzmann.sh"
ronin_dojo_menu="$ronin_menu_dir/menu-dojo.sh"
ronin_dojo_menu2="$ronin_menu_dir/menu-dojo2.sh"
ronin_electrs_menu="$ronin_menu_dir/menu-electrs.sh"
ronin_networking_menu="$ronin_menu_dir/menu-networking.sh"
ronin_ssh_menu="$ronin_menu_dir/menu-ssh.sh"
ronin_firewall_menu="$ronin_menu_dir/menu-firewall.sh"
ronin_firewall_menu2="$ronin_menu_dir/menu-firewall2.sh"
ronin_mempool_menu="$ronin_menu_dir/menu-mempool.sh"
ronin_system_menu="$ronin_menu_dir/menu-system.sh"
ronin_system_menu2="$ronin_menu_dir/menu-system2.sh"
ronin_system_monitoring="$ronin_menu_dir/menu-system-monitoring.sh"
ronin_system_update="$ronin_menu_dir/menu-system-updates.sh"
ronin_system_storage="$ronin_menu_dir/menu-system-storage.sh"
ronin_ui_menu="$ronin_menu_dir/menu-ronin-ui.sh"
ronin_updates_menu="$ronin_menu_dir/menu-system-updates.sh"
ronin_whirlpool_menu="$ronin_menu_dir/menu-whirlpool.sh"
ronin_whirlpool_stat_menu="$ronin_menu_dir/menu-whirlpool-wst.sh"
ronin_samourai_toolkit_menu="$ronin_menu_dir/menu-samourai-toolkit.sh"

#
# Terminal Colors
#
red=$(tput setaf 1)
green=$(tput setaf 2)
nc=$(tput sgr0) # No Color

#
# Install Defaults
#
dojo_path="$HOME/dojo"
dojo_path_my_dojo="${dojo_path}/docker/my-dojo"
ronin_data_dir="$HOME/.config/RoninDojo/data"
ronin_debug_dir="$HOME/.config/RoninDojo/debug"
ronin_gpio_data_dir="$HOME/.config/RoninDojo/GPIO"
boltzmann_path="$HOME/boltzmann"
ronin_ui_path="$HOME/Ronin-UI"

#
# Data backup variables
#
dojo_data_bitcoind_backup=true
dojo_data_indexer_backup=true
is_active_dojo_conf_backup=true
tor_backup=true
backup_format=false

#
# Repositories
#
ronin_dojo_branch="origin/release/v1.14.3" # defaults to origin/master
ronin_dojo_repo="https://code.samourai.io/ronindojo/RoninDojo.git"
samourai_repo='https://code.samourai.io/ronindojo/samourai-dojo.git'
samourai_commitish="origin/release/v1.14.1" # Tag release
boltzmann_repo='https://code.samourai.io/oxt/boltzmann.git'
whirlpool_stats_repo='https://code.samourai.io/whirlpool/whirlpool_stats.git'
ronin_ui_repo="https://code.samourai.io/ronindojo/ronin-ui.git"

#
# Filesystem Defaults
#
primary_storage="/dev/sda1"
secondary_storage="/dev/sdb1"
storage_mount="/mnt/backup"

bitcoin_ibd_backup_dir="${storage_mount}/backup/bitcoin"
indexer_backup_dir="${storage_mount}/backup/indexer"
tor_backup_dir="${storage_mount}/backup/tor"

install_dir="/mnt/usb"
install_dir_tor="${install_dir}/tor"
install_dir_swap="${install_dir}/swapfile"
install_dir_docker="${install_dir}/docker"

docker_volumes="${install_dir_docker}/volumes"
docker_volume_tor="${docker_volumes}/my-dojo_data-tor"
docker_volume_wp="${docker_volumes}/my-dojo_data-whirlpool"
docker_volume_bitcoind="${docker_volumes}/my-dojo_data-bitcoind"
docker_volume_indexer="${docker_volumes}/my-dojo_data-indexer"

# Dojo Related Backup Paths
dojo_backup_bitcoind="${install_dir}/backup/bitcoin"
dojo_backup_indexer="${install_dir}/backup/indexer"
dojo_backup_dir="${install_dir}/backup/dojo"
dojo_backup_conf="${install_dir}/backup/dojo/conf"
dojo_backup_tor="${install_dir}/backup/tor"

tor_data_dir="docker/volumes/my-dojo_data-tor"
bitcoind_data_dir="docker/volumes/my-dojo_data-bitcoind"
indexer_data_dir="docker/volumes/my-dojo_data_indexer"

sudoers_file="/etc/sudoers.d/21-ronindojo"

# Workaround when on desktop systems and autologin is enabled for the user account
if [ "$(getent group 1000 | cut -d ':' -f1)" = "autologin" ]; then
    ronindojo_user=$(getent group 1000 | cut -d ':' -f4)
else
    ronindojo_user=$(getent group 1000 | cut -d ':' -f1)
fi

# Network info
ip_current=$(ip route get 1 | awk '{print $7}')
interface_current=$(ip route get 1 | awk '{print $5}')
network_current="$(ip route | grep $interface_current | grep -v default | awk '{print $1}')"

# bitcoind defaults
bitcoind_db_cache=1024 
bitcoind_mempool_size=1024 

declare -a backup_dojo_data=(
    tor
    indexer
    bitcoind
)

# RoninUI defaults
roninui_version_staging=false
roninui_version_file="https://ronindojo.io/downloads/RoninUI/version.json"
if [ "$roninui_version_staging" = true ]; then
    roninui_version_file="https://ronindojo.io/downloads/RoninUI/version-staging.json"
fi
