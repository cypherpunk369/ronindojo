#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Onion Address"
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
        if _is_active specter; then
            cat <<EOF
${RED}
***
Starting Specter Service ...
***
${NC}
EOF
        fi

        _sleep

        bash -c "${RONIN_SPECTER_MENU}"
        # Start specter.service and return to same menu
        ;;
    2)
        if ! _is_active specter; then
            cat <<EOF
${RED}
***
Stopping Specter Service ...
***
${NC}
EOF
        sudo systemctl stop specter
        fi

        _sleep

        bash -c "${RONIN_SPECTER_MENU}"
        # Stop specter.service and return to same menu
        ;;
    3)
        cat <<EOF
${RED}
***
Restarting Specter Service ...
***
${NC}
EOF
        sudo systemctl restart specter

        _sleep
        bash -c "${RONIN_SPECTER_MENU}"
        # Restart specter.service and return to same menu
        ;;
    4)
        cat <<EOF
${RED}
***
Attempting to Upgrade Specter...
***
${NC}
EOF
        _upgrade_specter
        cd "${dojo_path_my_dojo}" || exit
        ./dojo.sh upgrade --nolog

        bash -c "${RONIN_SPECTER_MENU}"
        # Display onion and return to same menu
        ;;
    5)
        ronin
        # Return to main menu
        ;;
esac