#!/bin/bash

set -o pipefail -o errtrace -o errexit -o nounset

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Check Disk Space"
         2 "Format & Mount New Backup Drive"
         3 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear

case $CHOICE in
    1)
        _print_message "Showing Disk Space Info..."
        _sleep

        sd_free_ratio="$(df | grep "/$" | awk '{ print $4/$2*100 }' | tr -d '\n' 2>/dev/null)"
        sd="$(df -h | grep '/$' | awk '{ print $4 }' | tr -d '\n' 2>/dev/null)"
        echo "Internal: ${sd} (${sd_free_ratio}%) remaining"
        hdd_free_ratio="$(df  | grep "${install_dir}" | awk '{ print $4/$2*100 }' | tr -d '\n'  2>/dev/null)" 
        hdd="$(df -h | grep "${install_dir}" | awk '{ print $4 }' | tr -d '\n'  2>/dev/null)"
        echo "External: ${hdd} (${hdd_free_ratio}%) remaining"
        # disk space info

        _pause return
        bash -c "${ronin_system_storage}"
        exit
        ;;
    2)
        bash "$HOME"/RoninDojo/Scripts/Install/install-new-backup-data-drive.sh
        bash -c "${ronin_system_storage}"
        exit
        ;;
    *)
        bash -c "${ronin_system_menu}"
        # returns to menu
        ;;
esac
