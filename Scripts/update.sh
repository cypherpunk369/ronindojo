#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh

_load_user_conf

_update_01() {
    if ! _check_pkg_ver bridge-utils 1.7-1; then
        cat <<EOF
${red}
***
Outdated and bridge-utils found...
***
${nc}
EOF
        _sleep
        cat <<EOF
${red}
***
Starting bridge-utils upgrade...
***
${nc}
EOF
        sudo pacman --quiet -U --noconfirm https://ronindojo.io/downloads/distfiles/bridge-utils-1.7-1-aarch64.pkg.tar.xz &>/dev/null

        # If existing dojo found, then reboot system to apply changes
        if [ -d "${HOME}/dojo" ]; then
            cat <<EOF
${red}
***
Existing dojo found! Rebooting system to apply changes...
***
${nc}
EOF
            _sleep
            cat <<EOF
${red}
***
Press Ctrl+C now if you wish to skip...
***
${nc}
EOF
            _sleep 10 --msg "Rebooting in"
            sudo systemctl reboot
        fi

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/01-"$(date +%m-%d-%Y)"
    fi
}

# Remove old whirlpool stats tool directory
_update_02() {
    if [ -d "$HOME"/wst ]; then
        rm -rf "$HOME"/wst

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/02-"$(date +%m-%d-%Y)"
    fi
}

# Add password less reboot/shutdown privileges to sudo
_update_03() {
    if [ -f "${sudoers_file}" ]; then
        if ! grep "/usr/bin/systemctl poweroff" "${sudoers_file}" 1>/dev/null; then
            sudo bash -c "cat <<EOF >>${sudoers_file}
ALL ALL=(root) NOPASSWD: /usr/bin/systemctl reboot, /usr/bin/systemctl poweroff
EOF"

            # Finalize
            touch "$HOME"/.config/RoninDojo/data/updates/03-"$(date +%m-%d-%Y)"
        fi
    fi
}

# Add password less for /usr/bin/{ufw,mount,umount,cat,grep,test,mkswap,swapon,swapoff} privileges to sudo
_update_04() {
    if [ -f "${sudoers_path}" ]; then
        if ! grep "/usr/bin/test" "${sudoers_file}" 1>/dev/null; then
            sudo bash -c "cat <<EOF >>${sudoers_file}
ALL ALL=(root) NOPASSWD: /usr/bin/test, /usr/bin/grep, /usr/bin/cat, /usr/bin/ufw
ALL ALL=(root) NOPASSWD: /usr/bin/umount, /usr/bin/mount, /usr/bin/mkswap, /usr/bin/swapon, /usr/bin/swapoff
EOF"
        fi

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/04-"$(date +%m-%d-%Y)"
    fi
}

# Fix tor unit file
_update_05() {
    if findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor; then
        sudo sed -i 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _is_active tor
    fi

    # Some systems have issue with tor not starting unless User=tor is enabled. Here we check both directions as it takes care of edge cases where
    # the first if condition triggered but we still have problems.
    if findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor && ! grep "User=tor" /usr/lib/systemd/system/tor.service 1>/dev/null; then
        sudo sed -i -e 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' \
            -e '/Type=notify/a\User=tor' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _is_active tor
    elif findmnt /mnt/usb 1>/dev/null && ! systemctl is-active --quiet tor && grep "User=tor" /usr/lib/systemd/system/tor.service 1>/dev/null; then
        sudo sed -i -e 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' \
            -e '/User=tor/d' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload

        _is_active tor
    fi
}

# Modify pacman.conf and add ignore packages
_update_06() {
    if ! grep -w "${pkg_ignore[1]}" /etc/pacman.conf 1>/dev/null; then
        sudo sed -i "s:^#IgnorePkg   =.*$:IgnorePkg   = ${pkg_ignore[*]}:" /etc/pacman.conf

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/06-"$(date +%m-%d-%Y)"
    fi
}

# Copy user.conf.example to correct location
_update_07() {
    if [ ! -f "$HOME"/.config/RoninDojo/user.conf ] ; then
        cp "$HOME"/RoninDojo/user.conf.example "$HOME"/.config/RoninDojo/user.conf

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/07-"$(date +%m-%d-%Y)"
    fi
}

# Migrate bitcoin ibd data to new backup directory
_update_09() {
    if sudo test -d "${install_dir}"/bitcoin && sudo test -d "${install_dir}"/bitcoin/blocks; then
        sudo test -d "${dojo_backup_bitcoind}" || sudo mkdir "${dojo_backup_bitcoind}"

        for dir in blocks chainstate indexes; do
            if sudo test -d "${install_dir}"/bitcoin/"${dir}"; then
                sudo mv "${install_dir}"/bitcoin/"${dir}" "${dojo_backup_bitcoind}"/
            fi
        done

        # Remove legacy directory
        rm -rf "${install_dir}"/bitcoin

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/09-"$(date +%m-%d-%Y)"
    fi
}

# Migrate user.conf variables to lowercase
_update_10() {
    if [ -f "${HOME}"/.config/RoninDojo/user.conf ]; then
        for var in "PRIMARY_STORAGE" "SECONDARY_STORAGE" "INSTALL_DIR" "GUI_API" "RONIN_DOJO_BRANCH" "SAMOURAI_COMMITISH"; do
            if grep "${var}" "${HOME}"/.config/RoninDojo/user.conf 1>/dev/null; then
                sed -i "s/${var}/${var,,}/" "${HOME}"/.config/RoninDojo/user.conf
            fi
        done

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/10-"$(date +%m-%d-%Y)"
    fi
}

# Migrate to new ui backend tor location
_update_11() {
    if grep "/var/lib/tor/hidden_service_ronin_backend" /etc/tor/torrc 1>/dev/null; then
        sudo sed -i 's:/var/lib/tor/hidden_service_ronin_backend/:/mnt/usb/tor/hidden_service_ronin_backend/:' /etc/tor/torrc
        sudo rm -rf /var/lib/tor/hidden_service_ronin_backend

        sudo systemctl restart --quiet tor

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/11-"$(date +%m-%d-%Y)"
    fi
}

# tag that system install has been installed already
_update_13() {
    if [ -d "${install_dir_tor}" ] && [ ! -f "${ronin_data_dir}"/system-install ]; then
        # Make sure we don't run system install twice
        touch "${ronin_data_dir}"/system-install

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/13-"$(date +%m-%d-%Y)"
    fi
}

# Remove user.config file if it exist
_update_14() {
    if test -f "$HOME"/.config/RoninDojo/user.config; then
        rm "$HOME"/.config/RoninDojo/user.config

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/14-"$(date +%m-%d-%Y)"
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

# Update reference from old development branch to develop branch in user.conf
_update_23() {
    if grep -q "^ronin_dojo_branch=\"origin/development"\" "$HOME"/.config/RoninDojo/user.conf; then
        sed -i 's:origin/development:origin/develop:' "$HOME"/.config/RoninDojo/user.conf

        # Finalize
        touch "$HOME"/.config/RoninDojo/data/updates/23-"$(date +%m-%d-%Y)"
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

# Add service to auto detect network change, for keeping UFW ruleset up to date
_update_30() {

    # Check if Network check is implemented. If not install and run it.
    if [ ! -f /etc/systemd/system/ronin.network.service ]; then
        _install_network_check_service
    else
        sudo systemctl restart ronin.network
    fi

    # Finalize
    touch "$HOME"/.config/RoninDojo/data/updates/30-"$(date +%m-%d-%Y)"
}
