#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
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
        echo $'\n127.0.0.1 localhost' | sudo tee -a "${hostsfile}" > /dev/null
    fi
}

# Remove specter
# shellcheck disable=SC2120
_update_37() {

    if [ ! -d "$HOME"/.venv_specter ]; then
        return 0
    fi

    cd ~ || exit

    for dir in specter*; do
        if [ -d "$dir" ]; then
            
            _specter_version="${dir#*-}"

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

        fi
    done

    cd - || exit

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

# Modify pacman.conf and add ignore packages
_update_32() {
    if ! grep -w "${pkg_ignore[1]}" /etc/pacman.conf 1>/dev/null; then
        sudo sed -i "s:^#IgnorePkg   =.*$:IgnorePkg   = ${pkg_ignore[*]}:" /etc/pacman.conf
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/32-"$(date +%m-%d-%Y)"
}

# Set the addrindexrs option explicitly, otherwise migration ends up with defaults meaning electrs
_update_33() {

    if sudo test -d "${docker_volume_indexer}"/_data/addrindexrs; then # checks for addrindexrs and sets new conf otherwise would be set to electrs by default
        _set_addrindexrs
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/33-"$(date +%m-%d-%Y)"
}

# Call _setup_storage_config to set the files
_update_34() {

    _setup_storage_config

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/34-"$(date +%m-%d-%Y)"
}

# Update RoninUI, specifically to fix a RoninDojo installation with an older UI, that upgrades RoninDojo before UI is ever initialized
_update_35() {

    _ronin_ui_install

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/35-"$(date +%m-%d-%Y)"
}

# Fulcrum Batch support migration
_update_36(){
    if _is_fulcrum; then
        sudo sed -i 's/INDEXER_BATCH_SUPPORT=.*$/INDEXER_BATCH_SUPPORT=active/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    else
        sudo sed -i 's/INDEXER_BATCH_SUPPORT=.*$/INDEXER_BATCH_SUPPORT=inactive/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    fi;

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/36-"$(date +%m-%d-%Y)"
}

# Fixes not being able to update the system because manjaro broke it
_update_38(){
    
    if ! grep -w "${pkg_ignore[1]}" /etc/pacman.conf 1>/dev/null; then
        sudo sed -i "s/^#IgnorePkg   =.*$/IgnorePkg   = ${pkg_ignore[*]}/" /etc/pacman.conf
    else
        sudo sed -i "/^IgnorePkg/ s/$/ linux linux-headers linux-firmware/" /etc/pacman.conf
    fi


    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/38-"$(date +%m-%d-%Y)"
}

# Reinstalls the GPIO with the contemporary additions for tanto 2.x
_update_39() {
    _install_gpio

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/39-"$(date +%m-%d-%Y)"
}

# The last 1.x update ever
_update_40() {

    sed -i 's/^samourai_commitish/#samourai_commitish/' "${HOME}/.config/RoninDojo/user.conf" # let the samoura_commitish be decided by the RD branch
    sed -i 's/#ronin_dojo_branch/ronin_dojo_branch/' "${HOME}/.config/RoninDojo/user.conf" # uncomment the line

    sed -i 's#ronin_dojo_branch=.*#ronin_dojo_branch="origin/utility/E-1"#' "${HOME}/.config/RoninDojo/user.conf"

    _ronindojo_update

    #update .bashrc with the warning
    sed -i '/^\/home\/ronindojo\/RoninDojo\/Scripts\/.logo$/a echo -e "\\nNOTICE\\n\\nYOUR CURRENT VERSION IS 1.15.1\\nRONINDOJO WILL NO LONGER UPDATE\\nTO MIGRATE TO RONINDOJO V2\\nPLEASE FLASH THE SYSTEM WITH THE LATEST IMAGE\\nAND RE-PAIR YOUR WALLET WITH DOJO\\n\\nEND OF NOTICE"\necho Press any key to continue\nread -n 1 -r -s' /home/ronindojo/.bashrc

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/40-"$(date +%m-%d-%Y)"

    _print_message "YOUR CURRENT VERSION IS 1.15.1 AND RONINDOJO WILL NO LONGER UPDATE."
    _print_message "TO MIGRATE TO RONINDOJO V2 PLEASE FLASH THE SYSTEM WITH THE LATEST IMAGE."
    _print_message "RE-PAIR YOUR WALLET WITH DOJO, OTHERWISE YOU WILL NOT SEE TRANSACTIONS."
    _pause "return"
}
