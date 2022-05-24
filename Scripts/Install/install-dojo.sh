#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/generated-credentials.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if ! findmnt "${install_dir}" 1>/dev/null; then
    _print_message "Missing drive mount at ${install_dir}! Please contact support for assistance..."
    _print_message "Exiting RoninDojo..."
    _sleep
    [ $# -eq 0 ] && _pause return
    exit 1
fi

if [ -d "${dojo_path_my_dojo}" ]; then
    _print_message "RoninDojo is already installed..."
    _print_message "Exiting RoninDojo..."
    _sleep
    [ $# -eq 0 ] && _pause return
    exit 1
fi

_print_message "Running RoninDojo install..."
_print_message "Use Ctrl+C to exit now if needed!"
_sleep 10 --msg "Installing in"

_print_message "Downloading latest RoninDojo release..."

cd "$HOME" || exit
git clone -q "${samourai_repo}" dojo 2>/dev/null
cd "${dojo_path}" || exit
git checkout -q -f "${samourai_commitish}"

_print_message "Credentials necessary for usernames, passwords, etc. will randomly be generated now..."
_sleep 4
_print_message "Credentials are found in RoninDojo menu, ${dojo_path_my_dojo}/conf, or the ~/RoninDojo/user.conf.example file..."
_sleep 4
_print_message "Be aware these credentials are used to login to Dojo Maintenance Tool, Block Explorer, and more!"
_sleep 4
_print_message "Setting the RPC User and Password..."
_sleep

_restore_or_create_dojo_confs
_sleep

_check_indexer

if (($?==2)); then
    # No indexer found, fresh install
    # Enable default electrs indexer unless dojo_indexer="samourai-indexer" set in user.conf
    _set_indexer

    # Enable Samourai indexer
    if [ "${dojo_indexer}" = "samourai-indexer" ]; then
        _uninstall_electrs_indexer

        _set_indexer
    else
        bash "$HOME"/RoninDojo/Scripts/Install/install-electrs-indexer.sh

        touch "$HOME"/.config/RoninDojo/data/electrs.install
    fi
fi

_print_message "Please see Wiki for FAQ, help, and so much more..."
_sleep 3
_print_message "https://wiki.ronindojo.io"
_sleep 3
_print_message "Installing Samourai Wallet's Dojo..."
_sleep

# Restart docker here for good measure
sudo systemctl restart --quiet docker

cd "$dojo_path_my_dojo" || exit
if ! ./dojo.sh install --nolog --auto; then
    _print_error_message "Install failed! Please contact support..."
    [ $# -eq 0 ] && _pause return
    [ $# -eq 0 ] && ronin
    exit
fi

if [ ! -d "${HOME}"/boltzmann ]; then
    _print_message "Installing Boltzmann Calculator..."
    _install_boltzmann
fi

if [ ! -d "${HOME}"/Whirlpool-Stats-Tool ]; then
    _print_message "Installing Whirlpool Stat Tool..."
    _install_wst
fi

_print_message "Any previous node data will now be salvaged if you choose to continue..."
_sleep
[ $# -eq 0 ] && _pause continue

"${dojo_data_bitcoind_backup}" && _dojo_data_bitcoind restore
"${dojo_data_indexer_backup}" && _dojo_data_indexer restore
if ${tor_backup}; then
    _tor_restore
    docker restart tor 1>/dev/null
fi

_print_message "All RoninDojo feature installations complete!"
_sleep

. "$HOME"/RoninDojo/Scripts/update.sh

test -f "$HOME"/.config/RoninDojo/data/updates/08-* || _update_08 # Make sure mnt-usb.mount is available

[ $# -eq 0 ] && _pause return
