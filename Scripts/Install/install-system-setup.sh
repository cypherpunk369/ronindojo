#!/bin/bash
# shellcheck disable=SC2154 source=/dev/null

##############################
# LOADING VARS AND FUNCTIONS #
##############################

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf


##############
# ASSERTIONS #
##############

if [ -d "$HOME"/dojo ]; then
    _print_message "Dojo directory found, please uninstall Dojo first!"
    if [ $# -eq 0 ]; then
        _pause return
        bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
    fi
    exit
elif [ -f "${ronin_data_dir}"/system-install ] || [ -f /etc/systemd/system/ronin.network.service ]; then
    _print_message "Previous system install detected. Exiting script..."
    if [ $# -eq 0 ]; then
        _pause return
        bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
    fi
    exit
fi


####################
# INSTRUCTING USER #
####################

_print_message "Setting up system and installing dependencies..."
_sleep

_print_message "Use Ctrl+C to exit now if needed!"
_sleep 3 --msg "Installing in"

"$HOME"/RoninDojo/Scripts/.logo
# display ronindojo logo

test -f /etc/motd && sudo rm /etc/motd


##################################
# DISABLING UNNECESSARY SERVICES #
##################################

if _disable_bluetooth; then
    _print_message "Disabling Bluetooth..."
fi

if _disable_ipv6; then
    _print_message "Disabling Ipv6..."
fi


#######################
# FIXING DEPENDENCIES #
#######################

_pacman_update_mirrors

_print_message "Checking package dependencies. Please wait..."

. "$HOME"/RoninDojo/Scripts/update.sh
_update_19 # Uninstall bleeding edge Node.js and install LTS Node.js

for pkg in "${!package_dependencies[@]}"; do
    _check_pkg "${pkg}" "${package_dependencies[$pkg]}"
done

# TODO: replace this with use of _install_pkg_if_missing
if ! pacman -Q libusb 1>/dev/null; then
    _print_message "Installing libusb..."
    sudo pacman --quiet -S --noconfirm libusb
fi


###############################
# SETTING UP SECURITY PROFILE #
###############################

# Configure faillock
# https://man.archlinux.org/man/faillock.conf.5
sudo tee "/etc/security/faillock.conf" <<EOF >/dev/null
deny = 10
fail_interval = 120
unlock_time = 120
EOF

_print_message "Setting up UFW..."

sudo ufw default deny incoming &>/dev/null
sudo ufw default allow outgoing &>/dev/null
sudo ufw --force enable &>/dev/null
sudo ufw reload &>/dev/null

_install_network_check_service

sudo systemctl enable --now --quiet ufw

_print_message "Now that UFW is enabled, any computer connected to the same local network as your RoninDojo can access ports 22 (SSH) and 80 (HTTP)."
_print_message "Leaving this setting default is NOT RECOMMENDED for users who are connecting to something like University, Public Internet, Etc."
_print_message "Firewall rules can be adjusted using the RoninDojo Firewall Menu."
_print_message "All Dojo dependencies installed..."


#######################################
# STORAGE DEVICES SETUP: LOADING VARS #
#######################################

_nvme_check && _load_user_conf

_print_message "Creating ${install_dir} directory..."
test -d "${install_dir}" || sudo mkdir "${install_dir}"

if [[ "${primary_storage}" =~ "/dev/sd" ]]; then
    _device="${primary_storage%?}"
elif [[ "${primary_storage}" =~ "/dev/nvme" ]]; then
    _device="${primary_storage%??}"
else
    _print_error_message "Device type unrecognized: ${primary_storage}"
    _pause return
    exit 1
fi

#####################################
# STORAGE DEVICES SETUP: ASSERTIONS #
#####################################

if [ ! -b "${_device}" ]; then
    _print_error_message "device ${_device} not found!"
    [ $# -eq 0 ] && _pause return
    exit 1
fi

####################################################
# STORAGE DEVICES SETUP: PREPARING PARTITION TABLE #
####################################################

if [ ! -b "${primary_storage}" ]; then
    _print_message "No partition table found, creating one ..."
    sudo sgdisk -Zo -n 1 -t 1:8300 "${_device}" 1>/dev/null
fi

##################################
# STORAGE DEVICES SETUP: SALVAGE #
##################################

_print_message "Creating ${storage_mount} directory..."
test ! -d "${storage_mount}" && sudo mkdir "${storage_mount}"
_print_message "Attempting to mount drive for Blockchain data salvage..."
sudo mount "${primary_storage}" "${storage_mount}"

if sudo test -d "${storage_mount}/${bitcoind_data_dir}/_data/blocks"; then

    _print_message "Found Blockchain data for salvage!"
    _print_message "Moving to data backup"
    test -d "${bitcoin_ibd_backup_dir}" || sudo mkdir -p "${bitcoin_ibd_backup_dir}"

    sudo mv -v "${storage_mount}/${bitcoind_data_dir}/_data/"{blocks,chainstate,indexes} "${bitcoin_ibd_backup_dir}"/ 1>/dev/null

    _print_message "Blockchain data prepared for salvage!"
fi

if sudo test -d "${storage_mount}/${indexer_data_dir}/_data/db"; then

    _print_message "Found Indexer data for salvage!"
    _print_message "Moving to data backup"
    test -d "${indexer_backup_dir}" || sudo mkdir -p "${indexer_backup_dir}"

    sudo mv -v "${storage_mount}/${indexer_data_dir}/_data/db" "${indexer_backup_dir}"/ 1>/dev/null
    if [ -d "${storage_mount}/${indexer_data_dir}/_data/addrindexrs" ]; then
        sudo mv -v "${storage_mount}/${indexer_data_dir}/_data/addrindexrs" "${indexer_backup_dir}"/ 1>/dev/null
    fi

    _print_message "Indexer data prepared for salvage!"
fi

if sudo test -d "${storage_mount}/${tor_data_dir}/_data/hsv3dojo"; then

    _print_message "Found Tor data for salvage!"
    _print_message "Moving to data backup"
    test -d "${tor_backup_dir}" || sudo mkdir -p "${tor_backup_dir}"

    sudo bash -c 'cp -rpv "${storage_mount}/${tor_data_dir}/_data/hsv3"* "${tor_backup_dir}"/ 1>/dev/null'

    _print_message "Tor data prepared for salvage!"
fi


##########################################
# STORAGE DEVICES SETUP: SALVAGE CLEANUP #
##########################################

if check_swap "${storage_mount}/swapfile"; then
    test -f "${storage_mount}/swapfile" && sudo swapoff "${storage_mount}/swapfile" &>/dev/null
fi
sudo rm -rf "${storage_mount}"/{docker,tor,swapfile} &>/dev/null


#######################################################
# STORAGE DEVICES SETUP: MOUNT EXISTING OR FORMAT NEW #
#######################################################

if sudo test -d "${bitcoin_ibd_backup_dir}/blocks"; then
    _print_message "Found Blockchain data backup!"
    _print_message "Mounting drive..."
    sudo mount "${primary_storage}" "${install_dir}"

else
    _print_message "No Blockchain data found for salvage..."
    _print_message "Formatting the SSD..."

    if findmnt "${primary_storage}" 1>/dev/null; then
        if ! sudo umount "${primary_storage}"; then
            _print_error_message "Could not prepare device ${primary_storage} for formatting, was likely still in use"
            _print_error_message "Filesystem creation failed!"
            _pause return
            exit 1
        fi
    fi

    sudo wipefs -a --force "${_device}" 1>/dev/null
    sudo sgdisk -Zo -n 1 -t 1:8300 "${_device}" 1>/dev/null
    sudo mkfs.ext4 -q -F -L "main" "${primary_storage}" 1>/dev/null

fi

####################################################
# STORAGE DEVICES SETUP: INSTALL MOUNT IN SYSTEMD  #
####################################################

_print_message "Writing systemd mount unit file for device ${primary_storage}..."

#TODO: below, replace this by-uuid construct with a simple use of ${primary_storage}, gotta fix sda Vs sdb first though
#USECASE: by-uuid construct doesn't survive wipefs and reformat, would require a remake of the mountfile
#ALTERNATIVE: if the partition has always been labelled "main", maybe we can use the by-label construct instead, preventing sda Vs sdb scenarios

sudo tee "/etc/systemd/system/$(echo ${install_dir:1} | tr '/' '-').mount" <<EOF >/dev/null
[Unit]
Description=Mount primary storage ${primary_storage}

[Mount]
What=/dev/disk/by-uuid/$(lsblk -no UUID "${primary_storage}")
Where=${install_dir}
Type=$(blkid -o value -s TYPE "${primary_storage}")
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start --quiet mnt-usb.mount
sudo systemctl enable --quiet mnt-usb.mount

###########################################
# STORAGE DEVICES SETUP: USER INTERACTION #
###########################################

_print_message "Displaying the name on the external disk..."
lsblk -o NAME,SIZE,LABEL "${primary_storage}"
_sleep

_print_message "Check output for ${primary_storage} and make sure everything looks ok..."
df -h "${primary_storage}"


#########################################
# STORAGE DEVICES SETUP: SYSTEMS CONFIG #
#########################################

_swap_size
create_swap --file "${install_dir_swap}" --count "${_size}"

_setup_tor
_docker_datadir_setup


#######################
# INSTALLING TOOLSETS #
#######################

_print_message "Installing Ronin UI..."
_ronin_ui_install
_install_gpio

_print_message "Installing Boltzmann Calculator..."
_install_boltzmann
_print_message "Installing Whirlpool Stat Tool..."
_install_wst


#######################
# INSTALLING FINALIZE #
#######################

_create_dir "${ronin_data_dir}"
touch "${ronin_data_dir}"/system-install
_print_message "Dojo is ready to be installed!"
[ $# -eq 0 ] && _pause continue
