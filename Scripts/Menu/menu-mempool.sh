#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Logs"
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
            _print_message "Mempool Space Visualizer is not installed..."
            _sleep
            _pause return
            bash -c "${ronin_mempool_menu}"
        else
            _print_message "Starting Mempool Space Visualizer..."
            docker start mempool_api mempool_db mempool_web 1>/dev/null
            _sleep 5
            _pause return
            bash -c "${ronin_mempool_menu}"
            # see defaults.sh
            # start mempool, return to menu
        fi
        ;;
    2)
        if ! _is_mempool ; then
            _print_message "Mempool Space Visualizer is not installed..."
            _sleep
            _pause return
            bash -c "${ronin_mempool_menu}"
        else
            _print_message "Stopping Mempool Space Visualizer..."
            docker stop mempool_api mempool_db mempool_web 1>/dev/null
            _pause return
            bash -c "${ronin_mempool_menu}"
            # stop mempool, return to menu
            # see defaults.sh
        fi
        ;;
    3)
        if ! _is_mempool ; then
            _print_message "Mempool Space Visualizer is not installed..."
            _sleep
            _pause return
            bash -c "${ronin_mempool_menu}"
        else
            _print_message "Restarting Mempool Space Visualizer..."
            docker stop mempool_api mempool_db mempool_web 1>/dev/null
            _sleep 5

            docker start mempool_api mempool_db mempool_web 1>/dev/null
            _sleep

            _pause return
            bash -c "${ronin_mempool_menu}"
            # start mempool, return to menu
            # see defaults.sh
        fi
        ;;
    4)
        if ! _is_mempool ; then
            _print_message "Mempool Space Visualizer is not installed..."
            _sleep
            _pause return
            bash -c "${ronin_mempool_menu}"
        else
            _print_message "Viewing Mempool Space Visualizer Logs..."
            _sleep
            _print_message "Press Ctrl+C to exit at anytime..."

            cd "$dojo_path_my_dojo" || exit
            ./dojo.sh logs mempool_api
            bash -c "${ronin_mempool_menu}"
            # view logs, return to menu
            # see defaults.sh
        fi
        ;;
    *)
        ronin
        # return to menu
        ;;
esac
