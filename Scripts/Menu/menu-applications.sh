#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Mempool Space Visualizer"
         2 "Bisq Connection Status"
         3 "Fan Control"
         4 "Manage Applications"
         5 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear

case $CHOICE in
    1)
        if ! _is_mempool ; then
            _print_message "Mempool Space Visualizer not installed!"
            _sleep
            _print_message "Install Mempool Space Visualizer using the manage applications menu..."
            _sleep
            _pause return
            bash -c "${ronin_applications_menu}"
        else
            bash -c "${ronin_mempool_menu}"
        # Mempool Space Visualizer menu
        fi
        ;;
    2)
        _print_message "Checking your RoninDojo's compatibility with Bisq..."
        _sleep
        if ! _is_bisq ; then
            _print_message "Bisq connections are not enabled..."
            _sleep
            _print_message "Enable Bisq connections using the applications install menu..."
            _sleep
            _pause return
            bash -c "$ronin_applications_menu"
        else
            _print_message "Bisq connections are enabled..."
            _sleep
            _print_message "Enjoy those no-KYC sats..."
            _sleep
            _pause return
            bash -c "$ronin_applications_menu"
        fi
        # Bisq check
        ;;
    3)
        if ! _has_fan_control; then
            _print_message "No supported single-board computer detected for fan control..."
            _sleep
            _print_message "Supported devices are Rockpro64 and Rockpi4..."
            _sleep
            _pause return
            bash -c "$ronin_applications_menu"
            exit
        fi

        # Check for package dependencies
        for pkg in golang gcc; do
            _install_pkg_if_missing "${pkg}"
        done

        _install_pkg_if_missing "libc-bin" "glibc-source"

        if [ ! -f /etc/systemd/system/bbbfancontrol.service ]; then
            _print_message "Installing fan control..."
            cd "${HOME}" || exit

            _fan_control_install || exit 1

            _pause return

            bash -c "${ronin_applications_menu}"
            # Manage applications menu
        else
            _print_message "Fan control already installed..."
            _sleep

            _print_message "Checking for Fan Control updates..."

            if ! _fan_control_install; then
                _print_message "Fan Control already up to date..."
            fi
        fi

        _pause return

        bash -c "${ronin_applications_menu}"
        ;;
    4)
        bash -c "${ronin_applications_manage_menu}"
        # Manage applications menu
        ;;
    *)
        ronin
        # returns to main menu
        ;;
esac