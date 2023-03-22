#!/bin/bash

##############################
# LOADING VARS AND FUNCTIONS #
##############################


# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf


################
# LOADING VARS #
################


install_dir_partition=$(findmnt -n -o SOURCE --target "${install_dir}" 2> /dev/null)
install_dir_partition_uuid=$(lsblk -no UUID "${install_dir_partition}" 2> /dev/null)

backup_storage_partition_uuid=$(lsblk -no UUID "${backup_storage_partition}" 2> /dev/null)


##############
# ASSERTIONS #
##############

if [ -z ${backup_storage_partition} ]; then

    _setup_storage_config

    . "${HOME}"/RoninDojo/Scripts/defaults.sh

    if [ -z ${backup_storage_partition} ]; then
        _print_error_message "No backup storage device found"
        _pause return
        exit
    fi
fi

if [[ "${blockdata_storage_partition}" != "${install_dir_partition}" ]]; then
    _print_error_message "${install_dir} is not mounted to the prescribed partition ${blockdata_storage_partition}, instead found to be mounted to ${install_dir_partition}"
    _pause return
    exit
fi

if [[ "${install_dir_partition_uuid}" == "${backup_storage_partition_uuid}" ]]; then
    _print_error_message "Backup drive unusable, conflicts with drive mounted to /mnt/usb"
    _pause return
    exit
fi


#######################
# FIXING DEPENDENCIES #
#######################


_print_message "Installing dependencies..."
_install_pkg_if_missing "gdisk" 


#####################
# SETUP DIRECTORIES #
#####################


if findmnt "${backup_mount}" 1>/dev/null; then
    sudo umount -f "${backup_mount}"
fi

sudo rm -rf "${backup_mount}" &>/dev/null

if [ -d "${backup_mount}" ]; then
    _print_error_message "Directory of mountpoint ${backup_mount} still exists after attempt to remove."
    _pause "to return"
    exit
fi

if ! sudo mkdir -p "${backup_mount}"; then
    _print_error_message "Could not create ${backup_mount} directory..."
    _pause "to return"
    exit
fi


##########################
# PRE-EMPT THE PROCEDURE #
##########################

_print_message "Preparing to format ${backup_storage_partition} partition and mount it to ${backup_mount}..."

if [ -n "$(lsblk -no FSTYPE "${backup_storage_partition}" 2> /dev/null)" ]; then
    _print_message "Assigned backup partition ${backup_storage_partition} has a filesystem already"
    _print_message "It is mounted to the following: " "$(lsblk -o MOUNTPOINTS $backup_storage_partition | tail -1)"
fi

_print_message "WARNING: Any existing data on this backup drive will be lost!"
_print_message "Are you sure?"

while true; do
    read -rp "[${green}Yes${nc}/${red}No${nc}]: " answer
    case $answer in
        [yY][eE][sS]|[yY]) break;;
        [nN][oO]|[nN]) return;;
        * )
            _print_message "Invalid answer! Enter Y or N"
            ;;
    esac
done


#######################################
# STORAGE DEVICES SETUP: LOADING VARS #
#######################################


if [[ "${backup_storage_partition}" =~ "/dev/sd" ]]; then
    _device="${backup_storage_partition%?}"
elif [[ "${backup_storage_partition}" =~ "/dev/nvme" ]]; then
    _device="${backup_storage_partition%??}"
else
    _print_error_message "Device type unrecognized: ${backup_storage_partition}"
    _pause return
    return
fi


###############################################
# STORAGE DEVICES SETUP: FORMAT NEW AND MOUNT #
###############################################


_print_message "Formatting the Backup Data Partition..."
_sleep

sudo umount -f "${backup_storage_partition}"
sudo wipefs -a --force "${_device}" 1>/dev/null
sudo sgdisk -Zo -n 1 -t 1:8300 "${_device}" 1>/dev/null
sudo mkfs.ext4 -q -F -L "backup" "${backup_storage_partition}" 1>/dev/null
sudo mount "${backup_storage_partition}" "${backup_mount}"

_print_message "Mounted ${backup_storage_partition} to ${backup_mount}"
_print_message "Filesystem creation success!"


##############
# AFTER CARE #
##############


_print_message "Displaying the name on the external disk..."
lsblk -o NAME,SIZE,LABEL "${backup_storage_partition}"
_sleep

_print_message "Check the output for ${backup_storage_partition} and make sure everything looks ok..."
df -h "${backup_storage_partition}"
_sleep

_pause return
