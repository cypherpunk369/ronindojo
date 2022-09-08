#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh

_load_user_conf

# Fix tor unit file
_update_05() {
    if findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor; then
        sudo sed -i 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _start_service_if_inactive tor
    fi

    # Some systems have issue with tor not starting unless User=tor is enabled. Here we check both directions as it takes care of edge cases where
    # the first if condition triggered but we still have problems.
    if findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor && ! grep "User=tor" /usr/lib/systemd/system/tor.service 1>/dev/null; then
        sudo sed -i -e 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' \
            -e '/Type=notify/a\User=tor' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _start_service_if_inactive tor
    elif findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor && grep "User=tor" /usr/lib/systemd/system/tor.service 1>/dev/null; then
        sudo sed -i -e 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' \
            -e '/User=tor/d' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _start_service_if_inactive tor
    fi
}

# Remove duplicate bisq integration changes
_update_15() {
    if _is_bisq; then
        if (($(grep -c "\-peerbloomfilters=1" "${dojo_path_my_dojo}"/bitcoin/restart.sh)>1)); then
            sed -i -e '/-peerbloomfilters=1/d' \
                -e "/-whitelist=bloomfilter@${ip}/d" "${dojo_path_my_dojo}"/bitcoin/restart.sh

            sed -i -e "/  -txindex=1/i\  -peerbloomfilters=1" \
                -e "/  -txindex=1/i\  -whitelist=bloomfilter@${ip}" "${dojo_path_my_dojo}"/bitcoin/restart.sh
        fi

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/15-"$(date +%m-%d-%Y)"
    fi
}

# Uninstall legacy Ronin UI
_update_17() {
    if [ -d "$HOME"/Ronin-UI-Backend ]; then
        cd "$HOME"/Ronin-UI-Backend || exit

        pm2 delete "Ronin Backend" &>/dev/null

        pm2 save 1>/dev/null

        cd "$HOME" || exit

        rm -rf "$HOME"/Ronin-UI-Backend || exit

        cat <<EOF
${red}
***
Legacy Ronin UI detected...
***
EOF

        _sleep

        cat <<EOF
***
Uninstalling Ronin UI Backend...
***
EOF

        _sleep

        cat <<EOF
***
Installing Ronin UI Server...
***
${nc}
EOF

        _is_ronin_ui || _ronin_ui_install --initialized

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/17-"$(date +%m-%d-%Y)"
    fi
}

# Uninstall bleeding edge Node.js and install LTS Node.js instead
_update_19() {
    # Remove nodejs-lts-erbium if available
    if pacman -Q nodejs-lts-erbium &>/dev/null; then
        cat <<EOF
${red}
***
Migrating to nodejs-lts-fermium, please wait...
***
${nc}
EOF
        sudo pacman -R --noconfirm --cascade nodejs-lts-erbium &>/dev/null
        sudo pacman -S --noconfirm --quiet nodejs-lts-fermium npm

        if _is_ronin_ui; then
            # Restart Ronin-UI
            cd "${ronin_ui_path}" || exit

            pm2 restart "RoninUI" 1>/dev/null
        fi

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/19-"$(date +%m-%d-%Y)"
    fi
}

# Remove any existing docker-mempool.conf in favor of new tpl for v2
_update_22() {
    if [ -f "${dojo_path_my_dojo}"/conf/docker-mempool.conf ]; then
        rm "${dojo_path_my_dojo}"/conf/docker-mempool.conf

        cp "${dojo_path_my_dojo}"/conf/docker-mempool.conf.tpl "${dojo_path_my_dojo}"/conf/docker-mempool.conf

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/22-"$(date +%m-%d-%Y)"
    fi
}

# Fix hosts file
_update_24() {
    hostsfile="/etc/hosts"

    #test if there's a hostsfile, create if there isn't
    if test ! -f "${hostsfile}"; then
        if test -e "${hostsfile}"; then
            >&2 echo "${hostsfile} is present but not a regular file"
            exit 1
        fi
        sudo touch "${hostsfile}"
    fi

    #test if there's a 127.0.0.1 entry, edit when necessary
    if grep -q -E "^\s*127\.0\.0\.1(\s+\w+)+$" "${hostsfile}"; then
        if ! grep -q -E "^\s*127\.0\.0\.1(\s+\w+)*(\s+localhost)(\s+\w+)*$" "${hostsfile}"; then
            #edit existing entry, appending the "localhost" alias
            sudo sed -i -E 's/(\s*127\.0\.0\.1\s.*$)/\1 localhost/g' "${hostsfile}"
        fi
    else
        #append the missing entry
        echo $'\n127.0.0.1 localhost' | sudo tee -a "${hostsfile}"
    fi
}

# Remove specter
_update_25() {

    if [ ! -d "$HOME"/.venv_specter ]; then
        return 0
    fi

    local _specter_version
    _specter_version="$1"

    local specter_version
    specter_version="v1.7.2"

    _load_user_conf

    cat <<EOF
${red}
***
Uninstalling Specter ${_specter_version:-$specter_version}...
***
${nc}
EOF

    if systemctl is-active --quiet specter; then
        sudo systemctl stop --quiet specter
        sudo systemctl --quiet disable specter
        sudo rm /etc/systemd/system/specter.service
        sudo systemctl daemon-reload
    fi
    # Remove systemd unit

    cd "${dojo_path_my_dojo}"/bitcoin || exit
    git checkout restart.sh &>/dev/null && cd - 1>/dev/null || exit
    # Resets to defaults

    if [ -f /etc/udev/rules.d/51-coinkite.rules ]; then
        cd "$HOME"/specter-"${_specter_version:-$specter_version}"/udev || exit

        for file in *.rules; do
            test -f /etc/udev/rules.d/"${file}" && sudo rm /etc/udev/rules.d/"${file}"
        done

        sudo udevadm trigger
        sudo udevadm control --reload-rules
    fi
    # Delete udev rules

    rm -rf "$HOME"/.specter "$HOME"/specter-* "$HOME"/.venv_specter &>/dev/null
    rm "$HOME"/.config/RoninDojo/specter* &>/dev/null
    # Deletes the .specter dir, source dir, venv directory, certificate files and specter.service file

    sudo sed -i -e "s:^ControlPort .*$:#ControlPort 9051:" -e "/specter/,+3d" /etc/tor/torrc
    sudo systemctl restart --quiet tor
    # Remove torrc changes

    if getent group plugdev | grep -q "${ronindojo_user}" &>/dev/null; then
        sudo gpasswd -d "${ronindojo_user}" plugdev 1>/dev/null
    fi
    # Remove user from plugdev group

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/25-"$(date +%m-%d-%Y)"
}

# Fix gpio
_update_26() {

    if [ -d "${ronin_ui_path}" ]; then
        _install_gpio
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/26-"$(date +%m-%d-%Y)"
}

# Fix Bitcoin DB Cache and Mempool Size for existing users:
_update_27() {
    if ! grep "BITCOIND_DB_CACHE=1024" "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf; then
        sed -i -e "s/BITCOIND_DB_CACHE=.*$/BITCOIND_DB_CACHE=${bitcoind_db_cache}/" "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf
    fi
    if ! grep "BITCOIND_MAX_MEMPOOL=1024" "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf; then
        sed -i -e "s/BITCOIND_MAX_MEMPOOL=.*$/BITCOIND_MAX_MEMPOOL=${bitcoind_mempool_size}/" "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/27-"$(date +%m-%d-%Y)"
}

# Fix users getting locked-out
_update_28() {

    # Configure faillock
    # https://man.archlinux.org/man/faillock.conf.5
    sudo tee "/etc/security/faillock.conf" <<EOF >/dev/null
deny = 10
fail_interval = 120
unlock_time = 120
EOF

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/28-"$(date +%m-%d-%Y)"
}

# Update Node.js and pnpm if necessary
_update_29() {
    sudo pacman -Syy --needed --noconfirm --noprogressbar nodejs-lts-fermium &>/dev/null
    sudo npm i -g pnpm@7 &>/dev/null
    pm2 restart "RoninUI" &>/dev/null

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/29-"$(date +%m-%d-%Y)"
}

# Add service to auto detect network change, overwrite previous version if exists, of ronin.network.service
_update_31() {

    if [ -f /etc/systemd/system/ronin.network.service ]; then
        sudo systemctl stop ronin.network
    fi

    _install_network_check_service

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/31-"$(date +%m-%d-%Y)"
}

# Migrate the electrs data to the new electrs backup data location
_update_32() {
    test ! -d "${dojo_backup_electrs}" && sudo mkdir "${dojo_backup_electrs}"
    
    if sudo test -d "${docker_volume_indexer}"/_data/db/bitcoin; then  # checks for 0.9.x electrs data only  
        _set_electrs
        sudo mv "${docker_volume_indexer}"/_data "${dojo_backup_electrs}"/
    elif sudo test -d "${docker_volume_indexer}"/_data/addrindexrs; then # checks for addrindexrs and sets new conf otherwise would be set to electrs by default
        _set_addrindexrs
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/32-"$(date +%m-%d-%Y)"
}

# Restore indexer backup data to new docker volume location
_update_33(){
    _fetch_configured_indexer_type
    ret=$?
    
    if ((ret==0)) && sudo test -d "${dojo_backup_electrs}"/_data ; then
        _stop_dojo

        sudo rm -rf "${docker_volume_electrs}"/_data
        sudo mv "${dojo_backup_electrs}"/_data "${docker_volume_electrs}"

        _start_dojo
    fi
    
    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/33-"$(date +%m-%d-%Y)"
}

# Modify pacman.conf and add ignore packages
_update_34() {
    if ! grep -w "${pkg_ignore[1]}" /etc/pacman.conf 1>/dev/null; then
        sudo sed -i "s:^#IgnorePkg   =.*$:IgnorePkg   = ${pkg_ignore[*]}:" /etc/pacman.conf
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/34-"$(date +%m-%d-%Y)"
}
