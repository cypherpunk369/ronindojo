#!/bin/bash
# shellcheck disable=SC2154 source=/dev/null

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

if [ -d "$HOME"/dojo ]; then
    cat <<EOF
${red}
***
Dojo directory found, please uninstall Dojo first!
***
${nc}
EOF
    _sleep

    [ $# -eq 0 ] && _pause return
    bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
elif [ -f "${ronin_data_dir}"/system-install ]; then
    cat <<EOF
${red}
***
Previous system install detected. Exiting script...
***
${nc}
EOF
    [ $# -eq 0 ] && _pause return
    bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
else
    # Automatically set primary_storage for nvme capable hardware
    _nvme_check && _load_user_conf

    cat <<EOF
${red}
***
Setting up system and installing dependencies...
***
${nc}
EOF
fi
_sleep
# checks for "$HOME"/dojo directory, if found kicks back to menu

cat <<EOF
${red}
***
Use Ctrl+C to exit now if needed!
***
${nc}
EOF
_sleep 10 --msg "Installing in"

"$HOME"/RoninDojo/Scripts/.logo
# display ronindojo logo

test -f /etc/motd && sudo rm /etc/motd
# remove ssh banner for the script logo

if _disable_bluetooth; then
    cat <<EOF
${red}
***
Disabling Bluetooth...
***
${nc}
EOF
fi
# disable bluetooth, see functions.sh

if _disable_ipv6; then
    cat <<EOF
${red}
***
Disabling Ipv6...
***
${nc}
EOF
fi
# disable ipv6, see functions.sh

# Update mirrors
_pacman_update_mirrors

cat <<EOF
${red}
***
Checking package dependencies. Please wait...
***
${nc}
EOF

# Source update script
. "$HOME"/RoninDojo/Scripts/update.sh

# Run _update_19
test -f "$HOME"/.config/RoninDojo/data/updates/19-* || _update_19 # Uninstall bleeding edge Node.js and install LTS Node.js

# Install system dependencies
for pkg in "${!package_dependencies[@]}"; do
    _check_pkg "${pkg}" "${package_dependencies[$pkg]}"
done
# install system dependencies, see defaults.sh
# websearch "bash associative array" for info

if ! pacman -Q libusb 1>/dev/null; then
    cat <<EOF
${red}
***
Installing libusb...
***
${nc}
EOF
    sudo pacman --quiet -S --noconfirm libusb
fi

# Configure faillock
# https://man.archlinux.org/man/faillock.conf.5
sudo tee "/etc/security/faillock.conf" <<EOF >/dev/null
deny = 10
fail_interval = 120
unlock_time = 120
EOF


cat <<EOF
${red}
***
Setting up UFW...
***
${nc}
EOF

_sleep

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

cat <<EOF
${red}
***
Now that UFW is enabled, any computer connected to the same local network as your RoninDojo can access ports 22 (SSH) and 80 (HTTP).
***
${nc}
EOF

cat <<EOF
${red}
***
Leaving this setting default is NOT RECOMMENDED for users who are connecting to something like University, Public Internet, Etc.
***
${nc}
EOF

cat <<EOF
${red}
***
Firewall rules can be adjusted using the RoninDojo Firewall Menu.
***
${nc}
EOF
_sleep 10

cat <<EOF
${red}
***
All Dojo dependencies installed...
***
${nc}
EOF
_sleep

cat <<EOF
${red}
***
Creating ${install_dir} directory...
***
${nc}
EOF
_sleep

test -d "${install_dir}" || sudo mkdir "${install_dir}"
# test for ${install_dir} directory, otherwise creates using mkdir
# websearch "bash Logical OR (||)" for info

if [ -b "${primary_storage}" ]; then
    cat <<EOF
${red}
***
Creating ${storage_mount} directory...
***
${nc}
EOF
    _sleep

    test ! -d "${storage_mount}" && sudo mkdir "${storage_mount}"

    cat <<EOF
${red}
***
Attempting to mount drive for Blockchain data salvage...
***
${nc}
EOF
    _sleep
    sudo mount "${primary_storage}" "${storage_mount}"
else
    cat <<EOF
${red}
***
Did not find ${primary_storage} for Blockchain data salvage.
***
${nc}
EOF
    _sleep
fi
# mount main storage drive to "${storage_mount}" directory if found in prep for data salvage

if sudo test -d "${bitcoin_ibd_backup_dir}/blocks"; then
    cat <<EOF
${red}
***
Found Blockchain data for salvage!
***
${nc}
EOF
_sleep

    # Check if swap in use
    if check_swap "${storage_mount}/swapfile"; then
        test -f "${storage_mount}/swapfile" && sudo swapoff "${storage_mount}/swapfile" &>/dev/null
    fi

    if [ -f "${storage_mount}"/swapfile ]; then
        sudo rm -rf "${storage_mount}"/{swapfile,docker,tor} &>/dev/null
    fi

    if findmnt "${storage_mount}" 1>/dev/null; then
        sudo umount "${storage_mount}"
        sudo rmdir "${storage_mount}" &>/dev/null
    fi
    # if uninstall-salvage directory is found, delete older {docker,tor} directory and swapfile

    cat <<EOF
${red}
***
Mounting drive...
***
${nc}
EOF
_sleep

    # Mount primary drive if not already mounted
    findmnt "${primary_storage}" 1>/dev/null || sudo mount "${primary_storage}" "${install_dir}"

    cat <<EOF
${red}
***
Displaying the name on the external disk...
***
${nc}
EOF
_sleep

    lsblk -o NAME,SIZE,LABEL "${primary_storage}"
    # double-check that /dev/sda exists, and that its storage capacity is what you expected

    cat <<EOF
${red}
***
Check output for ${primary_storage} and make sure everything looks ok...
***
${nc}
EOF

    df -h "${primary_storage}"
    _sleep 5
    # checks disk info

    # Calculate swapfile size
    _swap_size

    create_swap --file "${install_dir_swap}" --count "${_size}"
    # created a 2GB swapfile on the external drive instead of sd card to preserve sd card life

    _setup_tor
    # tor configuration setup, see functions.sh

    _docker_datadir_setup
    # docker data directory setup, see functions.sh

    _create_dir "${ronin_data_dir}"
    # create directory to store user info, see functions.sh

    cat <<EOF
${red}
***
Dojo is ready to be installed!
***
${nc}
EOF

    # Make sure to wait for user interaction before continuing
    [ $# -eq 0 ] && _pause continue

    # Make sure we don't run system install twice
    touch "${ronin_data_dir}"/system-install

    exit
else
    cat <<EOF
${red}
***
No Blockchain data found for salvage check 1...
***
${nc}
EOF
    _sleep
fi
# checks for blockchain data to salvage, if found exits this script to dojo install, and if not found continue to salvage check 2 below

if sudo test -d "${storage_mount}/${bitcoind_data_dir}/_data/blocks"; then
    if sudo test -d "${storage_mount}/${indexer_data_dir}/_data/db"; then
        _indexer_salvage=true
    else
        _indexer_salvage=false
    fi

    cat <<EOF
${red}
***
Found Blockchain data for salvage!
***
${nc}
EOF
    _sleep

    cat <<EOF
${red}
***
Moving to temporary directory...
***
${nc}
EOF
    _sleep

    test -d "${bitcoin_ibd_backup_dir}" || sudo mkdir -p "${bitcoin_ibd_backup_dir}"

    sudo mv -v "${storage_mount}/${bitcoind_data_dir}/_data/"{blocks,chainstate,indexes} "${bitcoin_ibd_backup_dir}"/ 1>/dev/null
    # moves blockchain salvage data to ${storage_mount} if found

    if "${_indexer_salvage}"; then
        test -d "${indexer_backup_dir}" || sudo mkdir -p "${indexer_backup_dir}"
        sudo mv -v "${storage_mount}/${indexer_data_dir}/_data/db" "${indexer_backup_dir}"/ 1>/dev/null
    fi

    cat <<EOF
${red}
***
Blockchain data prepared for salvage!
***
${nc}
EOF
    _sleep

    # Check if swap in use
    if check_swap "${storage_mount}/swapfile"; then
        test -f "${storage_mount}/swapfile" && sudo swapoff "${storage_mount}/swapfile" &>/dev/null
    fi

    sudo rm -rf "${storage_mount}"/{docker,tor,swapfile} &>/dev/null

    if findmnt "${storage_mount}" 1>/dev/null; then
        sudo umount "${storage_mount}"
        sudo rmdir "${storage_mount}" &>/dev/null
    fi
    # remove docker, tor, swap file directories from ${storage_mount}
    # then unmount and remove ${storage_mount}

    cat <<EOF
${red}
***
Mounting drive...
***
${nc}
EOF
    _sleep

    # Mount primary drive if not already mounted
    findmnt "${primary_storage}" 1>/dev/null || sudo mount "${primary_storage}" "${install_dir}"

    _sleep

    cat <<EOF
${red}
***
Displaying the name on the external disk...
***
${nc}
EOF
    _sleep

    lsblk -o NAME,SIZE,LABEL "${primary_storage}"
    # lsblk lists disk by device
    # double-check that ${primary_storage} exists, and its storage capacity is what you expected

    cat <<EOF
${red}
***
Check output for ${primary_storage} and make sure everything looks ok...
***
${nc}
EOF

    df -h "${primary_storage}"
    _sleep 5
    # checks disk info

    # Calculate swapfile size
    _swap_size

    create_swap --file "${install_dir_swap}" --count "${_size}"
    # created a 2GB swapfile on the external drive instead of sd card to preserve sd card life

    _setup_tor
    # tor configuration setup, see functions.sh

    _docker_datadir_setup
    # docker data directory setup, see functions.sh

    cat <<EOF
${red}
***
Dojo is ready to be installed!
***
${nc}
EOF

    # Make sure to wait for user interaction before continuing
    [ $# -eq 0 ] && _pause continue

    # Make sure we don't run system install twice
    touch "${ronin_data_dir}"/system-install

    exit
else
    cat <<EOF
${red}
***
No Blockchain data found for salvage check 2...
***
${nc}
EOF
    _sleep

    # Check if swap in use
    if check_swap "${storage_mount}/swapfile" ; then
        test -f "${storage_mount}/swapfile" && sudo swapoff "${storage_mount}/swapfile" &>/dev/null
    fi

    if findmnt "${storage_mount}" 1>/dev/null; then
        sudo umount "${storage_mount}"
        sudo rmdir "${storage_mount}"
    fi
fi
# checks for blockchain data to salvage, if found exit to dojo install, and if not found continue to format drive

cat <<EOF
${red}
***
Formatting the SSD...
***
${nc}
EOF
_sleep 5

if ! create_fs --label "main" --device "${primary_storage}" --mountpoint "${install_dir}"; then
    printf "\n %sFilesystem creation failed! Exiting now...%s" "${red}" "${nc}"
    _sleep 3
    exit 1
fi
# create a partition table with a single partition that takes the whole disk
# format partition

cat <<EOF
${red}
***
Displaying the name on the external disk...
***
${nc}
EOF
_sleep

lsblk -o NAME,SIZE,LABEL "${primary_storage}"
# double-check that ${primary_storage} exists, and its storage capacity is what you expected

cat <<EOF
${red}
***
Check output for ${primary_storage} and make sure everything looks ok...
***
${nc}
EOF

df -h "${primary_storage}"
_sleep 5
# checks disk info

# tor configuration setup, see functions.sh
_setup_tor

# docker data directory setup, see functions.sh
_docker_datadir_setup

# Install Ronin UI
cat <<EOF
${red}
***
Installing Ronin UI...
***
${nc}
EOF

_ronin_ui_install

_install_gpio

# Calculate swapfile size
_swap_size

# created a 2GB swapfile on the external drive instead of sd card to preserve sd card life
create_swap --file "${install_dir_swap}" --count "${_size}"

cat <<EOF
${red}
***
Installing SW Toolkit...
***
${nc}
EOF
_sleep

cat <<EOF
${red}
***
Installing Boltzmann Calculator...
***
${nc}
EOF
_sleep

_install_boltzmann
# install Boltzmann

cat <<EOF
${red}
***
Installing Whirlpool Stat Tool...
***
${nc}
EOF
_sleep

_install_wst

cat <<EOF
${red}
***
Dojo is ready to be installed!
***
${nc}
EOF

# Make sure to wait for user interaction before continuing
[ $# -eq 0 ] && _pause continue

# Make sure we don't run system install twice
touch "${ronin_data_dir}"/system-install

# will continue to dojo install if it was selected on the install menu