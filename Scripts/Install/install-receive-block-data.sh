#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

##############################
# LOADING VARS AND FUNCTIONS #
##############################

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

_print_message "Preparing to copy data from your Backup Data Drive now..."
_sleep


#######################################
# STORAGE DEVICES SETUP: LOADING VARS #
#######################################


backup_storage_partition_uuid=$(lsblk -no UUID "${backup_storage_partition}" 2> /dev/null)
install_dir_partition=$(findmnt -n -o SOURCE --target "${install_dir}")
install_dir_partition_uuid=$(lsblk -no UUID "${install_dir_partition}")


#####################################
# STORAGE DEVICES SETUP: ASSERTIONS #
#####################################


if ! sudo test -d "${docker_volume_bitcoind}"/_data; then
    _print_message "Blockchain data not found! Did you forget to install RoninDojo?"
    _pause return
    bash -c "${ronin_dojo_menu2}"
    exit
fi

if [ -z ${backup_storage_partition} ]; then

    _setup_storage_config

    . "${HOME}"/RoninDojo/Scripts/defaults.sh

    if [ -z ${backup_storage_partition} ]; then
        _print_error_message "No backup storage device found"
        _pause return
        bash -c "${ronin_dojo_menu2}"
        exit
    fi
fi

if [ ! -b ${backup_storage_partition} ]; then
    _print_message "Backup storage partition missing, if you haven't connected the device please do and retry."
    _pause return
    bash -c "${ronin_dojo_menu2}"
    exit
fi

if [[ "${blockdata_storage_partition}" != "${install_dir_partition}" ]]; then
    _print_error_message "${install_dir} is not mounted to the prescribed partition ${blockdata_storage_partition}, instead found to be mounted to ${install_dir_partition}"
    _pause return
    bash -c "${ronin_dojo_menu2}"
    exit
fi

if [[ "${install_dir_partition_uuid}" == "${backup_storage_partition_uuid}" ]]; then
    _print_error_message "Backup drive unusable, conflicts with drive mounted to /mnt/usb, both having the UUID ${install_dir_partition_uuid}"
    _pause return
    bash -c "${ronin_dojo_menu2}"
    exit
fi


###################################
# STORAGE DEVICES SETUP: MOUNTING #
###################################


sudo test -d "${backup_mount}" || sudo mkdir -p"${backup_mount}"

if ! findmnt "${backup_mount}" 1>/dev/null; then
    _print_message "Mounting the backup storage mount ${backup_mount}..."
    sudo mount "${backup_storage_partition}" "${backup_mount}"
fi


#############
# PREPARING #
#############


_print_message "Making sure Dojo is stopped..."
_sleep

_stop_dojo


###############
# MAKING ROOM #
###############


_print_message "Removing old data..."
_sleep

for dir in blocks chainstate indexes; do
    if sudo test -d "${docker_volume_bitcoind}"/_data/"${dir}"; then
        sudo rm -rf "${docker_volume_bitcoind}"/_data/"${dir}"
    fi
done


########################
# RECEIVING BLOCK DATA #
########################


_print_message "Copying..."
_sleep

sudo cp -av "${bitcoin_ibd_backup_dir}"/{blocks,chainstate,indexes} "${docker_volume_bitcoind}"/_data/

_print_message "Transfer Complete!"
_sleep
_pause "continue" # press to continue is needed because sudo password can be requested for next step, if user is AFK there may be timeout


##############
# AFTER CARE #
##############


_print_message "Unmounting..."
_sleep

sudo umount "${backup_mount}" && sudo rmdir "${backup_mount}"

_print_message "You can now safely unplug your backup drive!"
_sleep

_print_message "Starting Dojo..."
_sleep
_start_dojo

_pause return
bash -c "${ronin_dojo_menu2}"
