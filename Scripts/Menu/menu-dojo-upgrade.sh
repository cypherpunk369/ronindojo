#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/update.sh

# Create Updates history directory
test ! -d "$HOME"/.config/RoninDojo/data/updates && mkdir -p "$HOME"/.config/RoninDojo/data/updates

## Perform update checks ##

# Uninstall bleeding edge Node.js and install LTS Node.js instead
test -f "$HOME"/.config/RoninDojo/data/updates/19-* || _update_19

# Uninstall legacy Ronin UI
test -f "$HOME"/.config/RoninDojo/data/updates/17-* || _update_17

# Remove any existing docker-mempool.conf in favor of new tpl for v2 during upgrade
test -f "$HOME"/.config/RoninDojo/data/updates/22-* || _update_22

# Update reference from old development branch to develop branch in user.conf
test -f "$HOME"/.config/RoninDojo/data/updates/23-* || _update_23

# Migrate the legacy indexer data location to the new indexer data location
test -f "$HOME"/.config/RoninDojo/data/updates/32-* || _update_32

## End update checks ##

_load_user_conf

_check_dojo_perms "${dojo_path_my_dojo}"

if grep BITCOIND_RPC_EXTERNAL=off "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf 1>/dev/null; then
    sed -i 's/BITCOIND_RPC_EXTERNAL=.*$/BITCOIND_RPC_EXTERNAL=on/' "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf
fi

_dojo_update

cd "${HOME}" || exit

if _is_mempool; then
    _mempool_conf || exit
fi

if [ -f /etc/systemd/system/whirlpool.service ] ; then
   sudo systemctl stop --quiet whirlpool

   _print_message "Whirlpool will be installed via Docker..."
   _print_message "You will need to re-pair with GUI, see Wiki for more information..."
   _sleep 5
else
   _print_message "Whirlpool will be installed via Docker..."
   _print_message "For pairing information see the wiki..."
   _sleep
fi

if _is_bisq ; then
    _bisq_install
fi

cd "${dojo_path_my_dojo}" || exit

# Re-enable the indexer
_fetch_configured_indexer_type
ret=$?

if ((ret==0)); then
    _set_electrs
    # keep electrs
elif ((ret==1)); then
    _set_addrindexrs
    # keep addrindexrs
elif ((ret==2)); then
    _set_fulcrum
    # keep fulcrum
else
    _set_electrs
    # sets default to electrs
fi

# Check if Network check is implemented. If not install and run it.
if [ ! -f /etc/systemd/system/ronin.network.service ]; then
    _install_network_check_service
else
    sudo systemctl restart ronin.network
fi

# run upgrade
./dojo.sh upgrade --nolog --auto

# Restore legacy indexer data to new db location
test -f "$HOME"/.config/RoninDojo/data/updates/33-* || _update_33

_pause return

#This next line of code is to be removed when enough users are on 1.14.0 or newer
ronin
