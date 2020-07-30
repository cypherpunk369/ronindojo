#!/bin/bash
# shellcheck source=/dev/null disable=SC2153

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Status"
        #  5 "Logs"
         5 "Credentials"
         6 "Install"
         7 "Uninstall"
         8 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
	1)
        _isbackend_ui

        # Check if process running, otherwise start it
        if pm2 describe "Ronin Backend" | grep status | grep stopped 1>/dev/null; then
            cat << EOF
${RED}
***
Starting Backend UI Server...
***
${NC}
EOF
            _sleep 2
            cd "${BACKEND_DIR}" || exit

            pm2 start "Ronin Backend"
        else
            cat << EOF
${RED}
***
Backend UI already started...
***
${NC}
EOF
        fi

        bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
        # start backend ui, return to menu
        ;;
    2)
        _isbackend_ui

        # Check if process running before stopping it
        if pm2 describe "Ronin Backend" &>/dev/null; then
            cat << EOF
${RED}
***
Stopping Backend UI Server...
***
${NC}
EOF
            _sleep 2
            cd "${BACKEND_DIR}" || exit

            pm2 stop "Ronin Backend"
        else
            cat << EOF
${RED}
***
Backend UI Server already stopped...
***
${NC}
EOF
        fi

        bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
        # start backend ui, return to menu
        ;;
    3)
        _isbackend_ui

        cat << EOF
${RED}
***
Restarting Backend UI Server...
***
${NC}
EOF
        _sleep 2
        cd "${BACKEND_DIR}" || exit

        # Restart service
        pm2 restart "Ronin Backend"

        bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
        # start backend ui, return to menu
        ;;
    4)
        _isbackend_ui

        cat << EOF
${RED}
***
Press any key to return.
***
${NC}
EOF
        cd "${BACKEND_DIR}" || exit
        pm2 status

        read -n 1 -r -s
        bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
        ;;
#     5)
#         _isbackend_ui

#         cat << EOF
# ${RED}
# ***
# Press Ctrl + C to exit at any time.
# ***
# ${NC}
# EOF
#         cd "${BACKEND_DIR}" || exit
#         pm2 log
#         bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
#         ;;
    5)
        _isbackend_ui

        cd "${BACKEND_DIR}" || exit

        API_KEY=$(grep API_KEY .env|cut -d'=' -f2)
        JWT_SECRET=$(grep JWT_SECRET .env|cut -d'=' -f2)
        BACKEND_PORT=$(grep PORT .env|cut -d'=' -f2)
        BACKEND_TOR=$(sudo cat /var/lib/tor/hidden_service_ronin_backend/hostname)

        cat << EOF
${RED}
***
Showing Backend UI Credentials...
API_KEY     =           ${API_KEY}
JWT_SECRET  =           ${JWT_SECRET}
PORT        =           ${BACKEND_PORT}
TOR_ADDRESS =           http://${BACKEND_TOR}
***
Press any letter to return...
${NC}
EOF
        read -n 1 -r -s
        bash -c "${HOME}"/RoninDojo/Scripts/Menu/menu-backend-ui.sh
        # shows backend ui credentials, returns to menu
        ;;
    6)
        _install_ronin_ui_backend
        ;;
    7)
        _isbackend_ui

        cd "${BACKEND_DIR}" || exit

        cat << EOF
${RED}
***
Uninstalling RoninBackend...
Press Ctrl+C to cancel at anytime
***
${NC}
EOF
        _sleep 10 --msg "Uninstall in"

        # Delete app from process list
        pm2 delete "Ronin Backend" 2>/dev/null

        # dump all processes for resurrecting them later
        pm2 save 1>/dev/null

        # Remove ${BACKEND_DIR}
        cd "${HOME}" || exit
        rm -rf "${BACKEND_DIR}" || exit
        ;;
    8)
        bash -c ronin
        # returns to main menu
        ;;
esac