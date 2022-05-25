#!/bin/bash
# shellcheck disable=SC2154 source=/dev/null

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if [ -d "$HOME"/dojo ]; then
    _print_message "Dojo directory found, please uninstall Dojo first!"
    if [ $# -eq 0 ]; then
        _pause return
        bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
    fi
    exit
elif [ -f "${ronin_data_dir}"/system-install ]; then
    _print_message "Previous system install detected. Exiting script..."
    if [ $# -eq 0 ]; then
        _pause return
        bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
    fi
    exit
fi

_print_message "Setting up system and installing dependencies..."
_sleep

_print_message "Use Ctrl+C to exit now if needed!"
_sleep 3 --msg "Installing in"

"$HOME"/RoninDojo/Scripts/.logo
# display ronindojo logo

test -f /etc/motd && sudo rm /etc/motd

if _disable_bluetooth; then
    _print_message "Disabling Bluetooth..."
fi

if _disable_ipv6; then
    _print_message "Disabling Ipv6..."
fi

_pacman_update_mirrors

_print_message "Checking package dependencies. Please wait..."

. "$HOME"/RoninDojo/Scripts/update.sh
test -f "$HOME"/.config/RoninDojo/data/updates/19-* || _update_19 # Uninstall bleeding edge Node.js and install LTS Node.js

for pkg in "${!package_dependencies[@]}"; do
    _check_pkg "${pkg}" "${package_dependencies[$pkg]}"
done

# TODO: replace this with use of _install_pkg_if_missing
if ! pacman -Q libusb 1>/dev/null; then
    _print_message "Installing libusb..."
    sudo pacman --quiet -S --noconfirm libusb
fi

# Configure faillock
# https://man.archlinux.org/man/faillock.conf.5
sudo tee "/etc/security/faillock.conf" <<EOF >/dev/null
deny = 10
fail_interval = 120
unlock_time = 120
EOF

_print_message "Setting up UFW..."

if ! -f /etc/systemd/system/ronin.network.service; then 

    sudo ufw default deny incoming &>/dev/null
    sudo ufw default allow outgoing &>/dev/null
    sudo ufw enable &>/dev/null
    sudo ufw reload &>/dev/null

    _install_network_check_service

    sudo systemctl enable --now --quiet ufw
else
    sudo systemctl restart ronin.network
fi

_print_message "Now that UFW is enabled, any computer connected to the same local network as your RoninDojo can access ports 22 (SSH) and 80 (HTTP)."
_print_message "Leaving this setting default is NOT RECOMMENDED for users who are connecting to something like University, Public Internet, Etc."
_print_message "Firewall rules can be adjusted using the RoninDojo Firewall Menu."
_print_message "All Dojo dependencies installed..."

_nvme_check && _load_user_conf

_print_message "Creating ${install_dir} directory..."
test -d "${install_dir}" || sudo mkdir "${install_dir}"

if [ ! -b "${primary_storage}" ]; then
    _print_error_message "device ${primary_storage} not found!"
    [ $# -eq 0 ] && _pause return
    exit
fi

_print_message "Creating ${storage_mount} directory..."
test ! -d "${storage_mount}" && sudo mkdir "${storage_mount}"
_print_message "Attempting to mount drive for Blockchain data salvage..."
sudo mount "${primary_storage}" "${storage_mount}"

if sudo test -d "${storage_mount}/${bitcoind_data_dir}/_data/blocks"; then

    _print_message "Found Blockchain data for salvage!"
    _print_message "Moving to data backup"

    test -d "${bitcoin_ibd_backup_dir}" || sudo mkdir -p "${bitcoin_ibd_backup_dir}"
    sudo mv -v "${storage_mount}/${bitcoind_data_dir}/_data/"{blocks,chainstate,indexes} "${bitcoin_ibd_backup_dir}"/ 1>/dev/null
    if [ -d "${storage_mount}/${indexer_data_dir}/_data/db" ]; then
        test -d "${indexer_backup_dir}" || sudo mkdir -p "${indexer_backup_dir}"
        sudo mv -v "${storage_mount}/${indexer_data_dir}/_data/db" "${indexer_backup_dir}"/ 1>/dev/null
    fi
    _print_message "Blockchain data prepared for salvage!"
fi

if check_swap "${storage_mount}/swapfile"; then
    test -f "${storage_mount}/swapfile" && sudo swapoff "${storage_mount}/swapfile" &>/dev/null
fi
sudo rm -rf "${storage_mount}"/{docker,tor,swapfile} &>/dev/null

if findmnt "${storage_mount}" 1>/dev/null; then
    sudo umount "${storage_mount}"
    sudo rmdir "${storage_mount}" &>/dev/null
fi

if sudo test -d "${bitcoin_ibd_backup_dir}/blocks"; then
    _print_message "Found Blockchain data backup!"
    _print_message "Mounting drive..."
    findmnt "${primary_storage}" 1>/dev/null || sudo mount "${primary_storage}" "${install_dir}"

else
    _print_message "No Blockchain data found for salvage..."
    _print_message "Formatting the SSD..."

    if ! _create_fs --label "main" --device "${primary_storage}" --mountpoint "${install_dir}"; then
        _print_error_message "Filesystem creation failed! Exiting now..."
        _sleep 3
        exit 1
    fi
fi

_print_message "Displaying the name on the external disk..."
lsblk -o NAME,SIZE,LABEL "${primary_storage}"
_sleep

_print_message "Check output for ${primary_storage} and make sure everything looks ok..."
df -h "${primary_storage}"

_swap_size
create_swap --file "${install_dir_swap}" --count "${_size}"

_setup_tor
_docker_datadir_setup

_print_message "Installing Ronin UI..."
_ronin_ui_install
_install_gpio

_print_message "Installing Boltzmann Calculator..."
_install_boltzmann
_print_message "Installing Whirlpool Stat Tool..."
_install_wst

_create_dir "${ronin_data_dir}"
touch "${ronin_data_dir}"/system-install
_print_message "Dojo is ready to be installed!"
[ $# -eq 0 ] && _pause continue
