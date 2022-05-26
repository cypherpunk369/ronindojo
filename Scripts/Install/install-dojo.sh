#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/generated-credentials.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if ! findmnt "${install_dir}" 1>/dev/null; then
    _print_message "Missing drive mount at ${install_dir}! Please contact support for assistance..."
    _print_message "Exiting RoninDojo..."
    [ $# -eq 0 ] && _pause return
    exit 1
fi

if [ -d "${dojo_path_my_dojo}" ]; then
    _print_message "RoninDojo is already installed..."
    _print_message "Exiting RoninDojo..."
    [ $# -eq 0 ] && _pause return
    exit 1
fi

_print_message "Running RoninDojo install..."
_print_message "Use Ctrl+C to exit now if needed!"
_sleep 3 --msg "Installing in"

_print_message "Downloading latest RoninDojo release..."

cd "$HOME" || exit
git clone -q "${samourai_repo}" dojo 2>/dev/null
cd "${dojo_path}" || exit
git checkout -q -f "${samourai_commitish}"

_print_message "Credentials necessary for usernames, passwords, etc. will randomly be generated now..."
_print_message "Credentials are found in RoninDojo menu, ${dojo_path_my_dojo}/conf, or the ~/RoninDojo/user.conf.example file..."
_print_message "Be aware these credentials are used to login to Dojo Maintenance Tool, Block Explorer, and more!"
_print_message "Setting the RPC User and Password..."

_restore_or_create_dojo_confs


_check_salvage_db

if (($?==2)); then
    # No indexer found or fresh install
    # Enable default electrs indexer unless dojo_indexer="samourai-indexer" set in user.conf
    # default set in defaults.sh
    _set_indexer

    if [ "${dojo_indexer}" = "samourai-indexer" ]; then
        if sudo test -d "${dojo_backup_indexer}"/_data/db/bitcoin; then
            sudo rm -rf "${dojo_backup_indexer}"/_data/db/bitcoin
        fi
    else
        bash "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh
        touch "$HOME"/.config/RoninDojo/data/electrs.install
    fi

elif (($?==0)); then # Found electrs previous install.
    _set_indexer
    bash "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh
    sudo test -d "${dojo_backup_indexer}"/_data/db/mainnet && sudo rm -rf "${dojo_backup_indexer}"/_data/db/mainnet
    touch "$HOME"/.config/RoninDojo/data/electrs.install
    # checks for electrs 0.8.x db and deletes if it was previously used)

elif (($?==1)); then # found addrindexrs previous install
    _set_indexer 
fi

_print_message "Please see Wiki for FAQ, help, and so much more..."
_print_message "https://wiki.ronindojo.io"
_print_message "Installing Samourai Wallet's Dojo..."

# Restart docker here for good measure
sudo systemctl restart --quiet docker

cd "$dojo_path_my_dojo" || exit
if ! ./dojo.sh install --nolog --auto; then
    _print_error_message "Install failed! Please contact support..."
    [ $# -eq 0 ] && _pause return
    [ $# -eq 0 ] && ronin
    exit
fi

_print_message "Any previous node data will now be salvaged if you choose to continue..."
[ $# -eq 0 ] && _pause continue

"${dojo_data_bitcoind_backup}" && _dojo_data_bitcoind restore
"${dojo_data_indexer_backup}" && _dojo_data_indexer restore
if ${tor_backup}; then
    _tor_restore
    docker restart tor 1>/dev/null
fi

_print_message "All RoninDojo feature installations complete!"

. "$HOME"/RoninDojo/Scripts/update.sh

[ $# -eq 0 ] && _pause return
