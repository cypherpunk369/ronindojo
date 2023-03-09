#!/bin/bash

##############################
# LOADING VARS AND FUNCTIONS #
##############################

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
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
fi

if [ -f "${ronin_data_dir}"/system-install ] || [ -f /etc/systemd/system/ronin.network.service ]; then
    _print_message "Previous system install detected, please uninstall RoninDojo first!"
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

#_apt_update

#_print_message "Checking package dependencies. Please wait..."

#for pkg in "${package_dependencies[@]}"; do
#    _install_pkg_if_missing "${pkg}"
#done


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

if ! _setup_storage_config; then
    _print_error_message "Could not determine primary/secondary storage setup, please make sure all storage devices are connected and reboot first!"
    if [ $# -eq 0 ]; then
        _pause return
        bash "$HOME"/RoninDojo/Scripts/Menu/menu-install.sh
    fi
    exit
fi

. "${ronin_data_dir}/blockdata_storage_partition"

if [[ "${blockdata_storage_partition}" =~ "/dev/sd" ]]; then
    _device="${blockdata_storage_partition%?}"
elif [[ "${blockdata_storage_partition}" =~ "/dev/nvme" ]]; then
    _device="${blockdata_storage_partition%??}"
else
    _print_error_message "Device type unrecognized: ${blockdata_storage_partition}"
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

if [ ! -b "${blockdata_storage_partition}" ]; then
    _print_message "No partition table found, creating one ..."
    sudo sgdisk -Zo -n 1 -t 1:8300 "${_device}" 1>/dev/null
fi

##################################
# STORAGE DEVICES SETUP: SALVAGE #
##################################

_print_message "Creating ${backup_mount} directory..."
test ! -d "${backup_mount}" && sudo mkdir "${backup_mount}"
_print_message "Attempting to mount drive for Blockchain data salvage..."
sudo mount "${blockdata_storage_partition}" "${backup_mount}"

if sudo test -d "${backup_mount}/${bitcoind_data_dir}/_data/blocks"; then #bitcoind

    _print_message "Found Blockchain data for salvage!"
    _print_message "Moving to data backup"
    test -d "${bitcoin_ibd_backup_dir}" || sudo mkdir -p "${bitcoin_ibd_backup_dir}"

    sudo mv -v "${backup_mount}/${bitcoind_data_dir}/_data/"{blocks,chainstate,indexes} "${bitcoin_ibd_backup_dir}"/

    _print_message "Blockchain data prepared for salvage!"
fi

if sudo test -d "${backup_mount}/${indexer_data_dir}/_data/addrindexrs"; then # Addrindexrs

    _print_message "Found Addrindexrs data for salvage!"
    _print_message "Moving to data backup"

    test -d "${indexer_backup_dir}" || sudo mkdir -p "${indexer_backup_dir}"
    sudo mv -v "${backup_mount}/${indexer_data_dir}/_data" "${indexer_backup_dir}"/

    _print_message "Addrindexrs data prepared for salvage!"

elif sudo test -d "${backup_mount}/${electrs_data_dir}/_data"; then # Electrs

    _print_message "Found Electrs data for salvage!"
    _print_message "Moving to data backup"

    test -d "${electrs_backup_dir}" || sudo mkdir -p "${electrs_backup_dir}"
    sudo mv -v "${backup_mount}/${electrs_data_dir}/_data" "${electrs_backup_dir}"/

    _print_message "Electrs data prepared for salvage!"

elif sudo test -d "${backup_mount}/${fulcrum_data_dir}/_data"; then # Fulcrum

    _print_message "Found Fulcrum data for salvage!"
    _print_message "Moving to data backup"
    
    test -d "${fulcrum_backup_dir}" || sudo mkdir -p "${fulcrum_backup_dir}"
    sudo mv -v "${backup_mount}/${fulcrum_data_dir}/_data" "${fulcrum_backup_dir}"/

    _print_message "Fulcrum data prepared for salvage!"
fi

if sudo test -d "${backup_mount}/${tor_data_dir}/_data/hsv3dojo"; then # tor

    _print_message "Found Tor data for salvage!"
    _print_message "Moving to data backup"
    test -d "${tor_backup_dir}" || sudo mkdir -p "${tor_backup_dir}"

    sudo bash -c "mv -v ${backup_mount}/${tor_data_dir}/_data/hsv3* ${tor_backup_dir}/"

    _print_message "Tor data prepared for salvage!"
fi


##########################################
# STORAGE DEVICES SETUP: SALVAGE CLEANUP #
##########################################

if check_swap "${backup_mount}/swapfile"; then
    test -f "${backup_mount}/swapfile" && sudo swapoff "${backup_mount}/swapfile" &>/dev/null
fi
sudo rm -rf "${backup_mount}"/{docker,tor,swapfile} &>/dev/null


#######################################################
# STORAGE DEVICES SETUP: MOUNT EXISTING OR FORMAT NEW #
#######################################################

if sudo test -d "${bitcoin_ibd_backup_dir}/blocks"; then

    _print_message "Creating ${install_dir} directory..."
    test -d "${install_dir}" || sudo mkdir -p "${install_dir}"

    _print_message "Found Blockchain data backup!"
    _print_message "Mounting drive..."
    sudo mount "${blockdata_storage_partition}" "${install_dir}"

else
    _print_message "No Blockchain data found for salvage..."
    _print_message "Formatting the SSD..."

    if findmnt "${blockdata_storage_partition}" 1>/dev/null; then
        if ! sudo umount "${blockdata_storage_partition}"; then
            _print_error_message "Could not prepare device ${blockdata_storage_partition} for formatting, was likely still in use"
            _print_error_message "Filesystem creation failed!"
            _pause return
            exit 1
        fi
    fi

    sudo wipefs -a --force "${_device}" 1>/dev/null
    sudo sgdisk -Zo -n 1 -t 1:8300 "${_device}" 1>/dev/null
    sudo mkfs.ext4 -q -F -L "main" "${blockdata_storage_partition}" 1>/dev/null

    _sleep 5 # kernel doesn't pick up on changes immediately, giving it some time

fi

####################################################
# STORAGE DEVICES SETUP: INSTALL MOUNT IN SYSTEMD  #
####################################################

_print_message "Writing systemd mount unit file for device ${blockdata_storage_partition}..."

#TODO: below, replace this by-uuid construct with a simple use of ${blockdata_storage_partition}, gotta fix sda Vs sdb first though
#USECASE: by-uuid construct doesn't survive wipefs and reformat, would require a remake of the mountfile
#ALTERNATIVE: if the partition has always been labelled "main", maybe we can use the by-label construct instead, preventing sda Vs sdb scenarios from being a problem

mountUnitName="$(echo "${install_dir:1}" | tr '/' '-').mount"
sudo tee "/etc/systemd/system/${mountUnitName}" <<EOF >/dev/null
[Unit]
Description=Mount primary storage ${blockdata_storage_partition}

[Mount]
What=/dev/disk/by-uuid/$(lsblk -no UUID "${blockdata_storage_partition}")
Where=${install_dir}
Type=$(blkid -o value -s TYPE "${blockdata_storage_partition}")
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start --quiet "${mountUnitName}"
sudo systemctl enable --quiet "${mountUnitName}"

_print_message "Mounted ${blockdata_storage_partition} to ${install_dir}"

###########################################
# STORAGE DEVICES SETUP: USER INTERACTION #
###########################################

_print_message "Displaying the name on the external disk..."
lsblk -o NAME,SIZE,LABEL "${blockdata_storage_partition}"
_sleep

_print_message "Check output for ${blockdata_storage_partition} and make sure everything looks ok..."
df -h "${blockdata_storage_partition}"


#########################################
# STORAGE DEVICES SETUP: SYSTEMS CONFIG #
#########################################

_swap_size
create_swap --file "${install_dir_swap}" --count "${_size}" &

_setup_tor
_docker_datadir_setup

#######################
# INSTALLING FINALIZE #
#######################

_create_dir "${ronin_data_dir}"
touch "${ronin_data_dir}"/system-install
_print_message "Dojo is ready to be installed!"
if [ $# -eq 0 ]; then
  _pause continue
fi
