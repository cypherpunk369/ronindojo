#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/update.sh

# Create Updates history directory
test ! -d "$HOME"/.config/RoninDojo/data/updates && mkdir -p "$HOME"/.config/RoninDojo/data/updates

## Perform update checks ##

# Remove update file from a previous upgrade
test -f "$HOME"/.config/RoninDojo/data/updates/10-* && rm "$HOME"/.config/RoninDojo/data/updates/10-* &>/dev/null

# Migrate user.conf variables to lowercase
test -f "$HOME"/.config/RoninDojo/data/updates/10-* || _update_10

# Uninstall bleeding edge Node.js and install LTS Node.js instead
test -f "$HOME"/.config/RoninDojo/data/updates/19-* || _update_19

# Uninstall legacy Ronin UI
test -f "$HOME"/.config/RoninDojo/data/updates/17-* || _update_17

# Create mnt-usb.mount if missing and system is already mounted.
test -f "$HOME"/.config/RoninDojo/data/updates/08-* || _update_08

# Remove any existing docker-mempool.conf in favor of new tpl for v2 during upgrade
test -f "$HOME"/.config/RoninDojo/data/updates/22-* || _update_22

# Update reference from old development branch to develop branch in user.conf
test -f "$HOME"/.config/RoninDojo/data/updates/23-* || _update_23


## End update checks ##

_load_user_conf

_check_dojo_perms "${dojo_path_my_dojo}"
# make sure permissions are properly set for ${dojo_path_my_dojo}

if grep BITCOIND_RPC_EXTERNAL=off "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf 1>/dev/null; then
    sed -i 's/BITCOIND_RPC_EXTERNAL=.*$/BITCOIND_RPC_EXTERNAL=on/' "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf
fi
# enable BITCOIND_RPC_EXTERNAL

# Update Samourai Dojo repo
_dojo_update

cd "${HOME}" || exit
# return to previous working path

if _is_mempool; then
    _mempool_conf || exit
fi
# Check if mempool available or not, then install it if previously installed.

if [ -f /etc/systemd/system/whirlpool.service ] ; then
   sudo systemctl stop --quiet whirlpool

   cat <<EOF
${red}
***
Whirlpool will be installed via Docker...
***
${nc}

${red}
***
You will need to re-pair with GUI, see Wiki for more information...
***
${nc}
EOF
   _sleep 5
else
   cat <<EOF
${red}
***
Whirlpool will be installed via Docker...
***
${nc}

${red}
***
For pairing information see the wiki...
***
${nc}
EOF
   _sleep
fi
# stop whirlpool for existing whirlpool users

if _is_bisq ; then
    _bisq_install
fi

cd "${dojo_path_my_dojo}" || exit

# Re-enable the indexer
_check_indexer
ret=$?

if ((ret==0)); then
    bash -c "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh
    test -d "${docker_volume_indexer}"/_data/db/mainnet && sudo rm -rf "${docker_volume_indexer}"/_data/db/mainnet
elif ((ret==1)); then
    test -f "${dojo_path_my_dojo}"/indexer/electrs.toml && rm "${dojo_path_my_dojo}"/indexer/electrs.toml

    _set_indexer
fi

# Check if Network check is implemented. If not install and run it.
if ! -f /etc/systemd/system/ronin.network.service; then
    _install_network_check_service
else
    sudo systemctl restart ronin.network
fi

./dojo.sh upgrade --nolog --auto
# run upgrade

# Backup any changes made to the confs
"${dojo_conf_backup}" && _backup_dojo_confs

_pause return
