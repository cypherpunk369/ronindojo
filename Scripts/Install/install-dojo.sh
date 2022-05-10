#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/generated-credentials.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if ! findmnt "${install_dir}" 1>/dev/null; then
    cat <<EOF
${red}
***
Missing drive mount at ${install_dir}! Please contact support for assistance...
***
${nc}
EOF
    _sleep
    cat <<EOF
${red}
***
Exiting RoninDojo...
***
${nc}
EOF
    _sleep
    [ $# -eq 0 ] && _pause return
    exit 1
fi

if [ -d "${dojo_path_my_dojo}" ]; then
    cat <<EOF
${red}
***
RoninDojo is already installed...
***
${nc}
EOF
    _sleep
    [ $# -eq 0 ] && _pause return
    ronin
    exit
fi
# Makes sure RoninDojo has been uninstalled

cat <<EOF
${red}
***
Running RoninDojo install...
***
${nc}
EOF
_sleep

cat <<EOF
${red}
***
Use Ctrl+C to exit now if needed!
***
${nc}
EOF
_sleep 10 --msg "Installing in"

cat <<EOF
${red}
***
Downloading latest RoninDojo release...
***
${nc}
EOF

cd "$HOME" || exit
git clone -q "${samourai_repo}" dojo 2>/dev/null
cd "${dojo_path}" || exit
git checkout -q -f "${samourai_commitish}"

# Check if RoninUI needs installing
if ! _is_ronin_ui; then
    printf "%s\n***\nInstalling Ronin UI...\n***\n%s\n" "${red}" "${nc}"

    _ronin_ui_install
fi

# Install network check before roninui to ensure network and UFW are working correctly.
if -f /etc/systemd/system/ronin.network.service; then 
    _backup_network_info
    _ssd_backup_network_info
    bash "${ronin_scripts_dir}"/network-check.sh
else
    _install_network_check_service
fi

_install_gpio

cat <<EOF
${red}
***
Credentials necessary for usernames, passwords, etc. will randomly be generated now...
***
${nc}
EOF
_sleep 4

cat <<EOF
${red}
***
Credentials are found in RoninDojo menu, ${dojo_path_my_dojo}/conf, or the ~/RoninDojo/user.conf.example file...
***
${nc}
EOF
_sleep 4

cat <<EOF
${red}
***
Be aware these credentials are used to login to Dojo Maintenance Tool, Block Explorer, and more!
***
${nc}
EOF
_sleep 4

cat <<EOF
${red}
***
Setting the RPC User and Password...
***
${nc}
EOF
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

cat <<EOF
${red}
***
Please see Wiki for FAQ, help, and so much more...
***
${nc}
EOF
_sleep 3

cat <<EOF
${red}
***
https://wiki.ronindojo.io
***
${nc}
EOF
_sleep 3

cat <<EOF
${red}
***
Installing Samourai Wallet's Dojo...
***
${nc}
EOF
_sleep

# Restart docker here for good measure
sudo systemctl restart --quiet docker

cd "$dojo_path_my_dojo" || exit

if ./dojo.sh install --nolog --auto; then

    # Installing SW Toolkit
    if [ ! -d "${HOME}"/boltzmann ]; then
        cat <<EOF
${red}
***
Installing Boltzmann Calculator...
***
${nc}
EOF
        # install Boltzmann
        _install_boltzmann
    fi

    if [ ! -d "${HOME}"/Whirlpool-Stats-Tool ]; then
        cat <<EOF
${red}
***
Installing Whirlpool Stat Tool...
***
${nc}
EOF
        # install Whirlpool Stat Tool
        _install_wst
    fi

    cat <<EOF
${red}
***
Any previous node data will now be salvaged if you choose to continue...
***
${nc}
EOF
_sleep

    # Make sure to wait for user interaction before continuing
    [ $# -eq 0 ] && _pause continue

    # Restore any saved IBD from a previous uninstall
    "${dojo_data_bitcoind_backup}" && _dojo_data_bitcoind restore

    # Restore any saved indexer data from a previous uninstall
    "${dojo_data_indexer_backup}" && _dojo_data_indexer restore

    if ${tor_backup}; then
        _tor_restore
        docker restart tor 1>/dev/null
    fi
    # restore tor credentials backup to container

    cat <<EOF
${red}
***
All RoninDojo feature installations complete!
***
${nc}
EOF
_sleep

    # Source update script
    . "$HOME"/RoninDojo/Scripts/update.sh

    # Run _update_08
    test -f "$HOME"/.config/RoninDojo/data/updates/08-* || _update_08 # Make sure mnt-usb.mount is available

    # Press to continue to prevent from snapping back to menu too quickly
    [ $# -eq 0 ] && _pause return
else
        cat <<EOF
${red}
***
Install failed! Please contact support...
***
${nc}
EOF

        [ $# -eq 0 ] && _pause return
        [ $# -eq 0 ] && ronin
fi
