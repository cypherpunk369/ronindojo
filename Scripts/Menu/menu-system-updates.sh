#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Update System"
         2 "Check for RoninDojo Update"
         3 "Update RoninDojo"
         4 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        # Update Mirrors and continue.
        _apt_update
        sudo apt-get -y upgrade

        _pause return
        bash -c "${ronin_system_update}"
        ;;
    2)
        if [ -f "${ronin_data_dir}"/ronin-latest.txt ] ; then
            rm "${ronin_data_dir}"/ronin-latest.txt
        fi

        # check for Ronin update from site
        wget -q https://ronindojo.io/downloads/ronindojo-version.txt -O "${ronin_data_dir}"/ronindojo-latest.txt 2>/dev/null

        version=$(<"${ronin_data_dir}"/ronindojo-latest.txt)

        if [[ "${ronindojo_version}" != "${version}" ]] ; then
            _print_message "RoninDojo update is available!"
            _sleep
        else
            _print_message "No update is available!"
            _sleep
        fi

        _pause return
        bash -c "${ronin_system_update}"
        ;;

    3)
        # is dojo installed?
        if [ ! -d "${dojo_path}" ]; then
            _print_message "Missing ${dojo_path} directory, aborting update..."
            _sleep
            _pause return
            bash -c "${ronin_system_update}"
            exit 1
        fi

        # Update System
        _print_message "Updating Debian OS Mirrors, Please wait..."
        _apt_update
        sudo apt-get -y upgrade

        # Update PNPM
        _print_message "Updating PNPM, Please wait..."
        sudo npm i -g pnpm@7 &>/dev/null

        _print_message "Updating RoninDojo..."
        _sleep

        _print_message "Use Ctrl+C to exit if needed!"
        _sleep 10 --msg "Updating in"

        _ronindojo_update

        # re-source these scripts before calling functions from them, since they've possible been updated
        . "$HOME"/RoninDojo/Scripts/defaults.sh
        . "$HOME"/RoninDojo/Scripts/functions.sh
        _load_user_conf

        bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-upgrade.sh

        _call_update_scripts
        
        bash -c "${ronin_updates_menu}"
        ;;
    4)
        bash -c "${ronin_system_menu}"
        ;;
esac
