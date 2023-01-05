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
            cat <<EOF
${red}
***
Mempool Space Visualizer not installed!
***
${nc}
EOF
            _sleep
            cat <<EOF
${red}
***
Install Mempool Space Visualizer using the manage applications menu...
***
${nc}
EOF
            _sleep
            _pause return
            bash -c "${ronin_applications_menu}"
        else
            bash -c "${ronin_mempool_menu}"
        # Mempool Space Visualizer menu
        fi
        ;;
    2)
        cat <<EOF
${red}
***
Checking your RoninDojo's compatibility with Bisq...
***
${nc}
EOF
        _sleep
        if ! _is_bisq ; then
            cat <<EOF
${red}
***
Bisq connections are not enabled...
***
${nc}
EOF
            _sleep
            cat <<EOF
${red}
***
Enable Bisq connections using the applications install menu...
***
${nc}
EOF
            _sleep
            _pause return
            bash -c "$ronin_applications_menu"
        else
            cat <<EOF
${red}
***
Bisq connections are enabled...
***
${nc}
EOF
            _sleep
            cat <<EOF
${red}
***
Enjoy those no-KYC sats...
***
${nc}
EOF
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
            cat <<EOF
${red}
***
Supported devices are Rockpro64 and Rockpi4...
***
${nc}
EOF
            _sleep

            _pause return
            bash -c "$ronin_applications_menu"
            exit
        fi

        # Check for package dependencies
        for pkg in go gcc; do
            _check_pkg "${pkg}"
        done

        _check_pkg "ldd" "glibc"

        if [ ! -f /etc/systemd/system/bbbfancontrol.service ]; then
            cat <<EOF
${red}
***
Installing fan control...
***
${nc}
EOF
            cd "${HOME}" || exit

            _fan_control_install || exit 1

            _pause return

            bash -c "${ronin_applications_menu}"
            # Manage applications menu
        else
            cat <<EOF
${red}
***
Fan control already installed...
***
${nc}
EOF

            _sleep

            cat <<EOF
${red}
***
Checking for Fan Control updates...
***
${nc}
EOF

            if ! _fan_control_install; then
                cat <<EOF
${red}
***
Fan Control already up to date...
***
${nc}
EOF
            fi
        fi

        _pause return

        bash -c "${ronin_applications_menu}"
        ;;
    4)
        bash -c "${ronin_applications_manage_menu}"
        # Manage applications menu
        ;;
    5)
        ronin
        # returns to main menu
        ;;
esac