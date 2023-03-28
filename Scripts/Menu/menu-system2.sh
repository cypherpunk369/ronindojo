#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Networking"
         2 "Change User Password"
         3 "Change Root Password"
         4 "Lock Root User"
         5 "Unlock Root User"
         6 "Uninstall RoninDojo"
         7 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        bash -c "${ronin_networking_menu}"
        exit
        ;;
    2)
        _print_message "Prepare to type new password for ${ronindojo_user} user..."
        _sleep
        sudo passwd "${ronindojo_user}"
        ;;
    3)
        _print_message "Prepare to type new password for root user..."
        _sleep
        sudo passwd
        ;;
    4)
        _print_message "Locking Root User..."
        _sleep
        sudo passwd -l root
        ;;
    5)
        _print_message "Unlocking Root User..."
        _sleep
        sudo passwd -u root
        ;;
    6)
        if [ ! -d "${dojo_path}" ]; then
            _is_dojo "${ronin_system_menu2}"
            exit
        fi

        _print_message "Uninstalling RoninDojo, press Ctrl+C to exit if needed!"
        _sleep 10 --msg "Uninstalling in"

        _stop_dojo

        "${dojo_data_bitcoind_backup}" && _dojo_data_bitcoind_backup

        "${dojo_data_indexer_backup}" && _dojo_data_indexer_backup

        _print_message "Uninstalling RoninDojo..."

        "${tor_backup}" && _tor_backup

        sudo rm -rf "${install_dir}/docker" &>/dev/null

        _is_mempool && _mempool_uninstall

        _is_bisq && _bisq_uninstall

        _uninstall_network_check_service

        _print_message "Removing Samourai Dojo Server..."

        cd "$dojo_path_my_dojo" || exit

        if ./dojo.sh uninstall --auto; then
            _is_ronin_ui && _ronin_ui_uninstall

            _is_fan_control_installed && _fan_control_uninstall

            if [ -d "${HOME}"/Whirlpool-Stats-Tool ]; then
                cd "${HOME}"/Whirlpool-Stats-Tool || exit

                _print_message "Uninstalling Whirlpool Stats Tool..."

                pipenv --rm &>/dev/null
                cd - 1>/dev/null || exit
                rm -rf "${HOME}"/Whirlpool-Stats-Tool
            fi

            if [ -d "${HOME}"/boltzmann ]; then
                cd "${HOME}"/boltzmann || exit

                _print_message "Uninstalling Bolzmann..."

                pipenv --rm &>/dev/null
                cd - 1>/dev/null || exit
                rm -rf "${HOME}"/boltzmann
            fi

            "${is_active_dojo_conf_backup}" && _backup_dojo_confs

            rm -rf "${dojo_path}"

            cd "${HOME}" || exit

            sudo systemctl restart --quiet docker

            _print_message "All RoninDojo features has been Uninstalled..."
            _sleep
        fi


        ;;
    7)
        bash -c "${ronin_system_menu}"
        exit
        ;;
esac

_pause return
bash -c "${ronin_system_menu2}"
