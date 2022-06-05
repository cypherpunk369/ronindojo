#!/bin/bash
# shellcheck source=./Scripts/defaults.sh

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

_ronin_ui_credentials() {
    cd "${ronin_ui_path}" || exit

    JWT_SECRET=$(grep JWT_SECRET .env|cut -d'=' -f2)
    BACKEND_TOR=$(sudo cat "${install_dir_tor}"/hidden_service_ronin_backend/hostname)

    export JWT_SECRET BACKEND_TOR
}

display_creds_dojo() {
    _print_message "Samourai Dojo Credentials"
    _print_message "WARNING: Do not share these onion addresses with anyone!" \
        "Maintenance Tool:" \
        "Tor Address             =   http://${tor_addr_dojo_api}/admin" \
        "Admin Key               =   $NODE_ADMIN_KEY" \
        "API Key                 =   $NODE_API_KEY"
}

display_creds_whirlpool() {
    _print_message "Samourai Whirlpool Credentials"
    _print_message "WARNING: Do not share these onion addresses with anyone!" \
        "Tor Address             =   http://${tor_addr_whirlpool}" \
        "Whirlpool API Key       =   ${whirlpool_api_key:-Whirlpool not Initiated yet. Pair wallet with GUI}"
}

display_creds_fulcrum() {
    if _is_fulcrum; then
        _print_message "Fulcrum Credentials" "Tor Address             =   http://${tor_addr_fulcrum}"
        _print_message "Check the RoninDojo Wiki for pairing information at https://wiki.ronindojo.io"
    fi
}

display_creds_electrs() {
    if _is_electrs; then
        _print_message "Electrs Credentials" "Tor Address             =   http://${tor_addr_electrs}"
        _print_message "Check the RoninDojo Wiki for pairing information at https://wiki.ronindojo.io"
    fi
}

display_creds_mempool() {
    if _is_mempool ; then
        _print_message "Mempool Space Visualizer Credentials" "Tor Address             =   http://${tor_addr_mempool}"
    fi
}

display_creds_roninui() {
    _ronin_ui_credentials && cd "$HOME" || exit
    _print_message "Ronin UI Credentials" \
        "Local Access Domain     =   http://ronindojo.local" \
        "Local Access IP         =   http://${ip} # fallback for when ronindojo.local doesn't work for you." \
        "Tor Address             =   http://${BACKEND_TOR}"
}

display_creds_bitcoin() {
    _print_message "Bitcoin Credentials" \
        "Bitcoin Daemon:" \
        "" \
        "Tor Address             =   http://${tor_addr_bitcoind}" \
        "RPC User                =   $BITCOIND_RPC_USER" \
        "RPC Password            =   $BITCOIND_RPC_PASSWORD" \
        "RPC IP                  =   $BITCOIND_IP" \
        "RPC Port                =   $BITCOIND_RPC_PORT" \
        "" \
        "Bitcoin RPC Explorer (No username required):" \
        "Tor Address             =   http://${tor_addr_explorer}" \
        "Password                =   $EXPLORER_KEY"
}

OPTIONS=(1 "Dojo"
         2 "Whirlpool"
         3 "Indexer"
         4 "Mempool"
         5 "Ronin UI"
         6 "Bitcoind"
         7 "All Credentials"
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
            display_creds_dojo
            ;;
        2)
            display_creds_whirlpool
            ;;
        3)
            if _is_fulcrum; then
                display_creds_fulcrum
            elif _is_electrs; then
                display_creds_electrs
            fi
            ;;
        4)
            if _is_mempool ; then
                display_creds_mempool
            else
                _print_message "Mempool Space Visualizer is not installed..."
                _print_message "Install using the manage applications menu..."
            fi
            ;;
        5)
            display_creds_roninui
            ;;
        6)
            display_creds_bitcoin
            ;;
        7)
            _print_message "Displaying list of all available credentials in your RoninDojo..."
            _sleep 5 --msg "Displaying in "

            display_creds_dojo
            display_creds_whirlpool
            display_creds_roninui
            display_creds_bitcoin
            display_creds_mempool
            if _is_fulcrum; then
                display_creds_fulcrum
            elif _is_electrs; then
                display_creds_electrs
            fi
            ;;
        8)
            ronin
            exit
            ;;
esac

_pause return
bash -c "${ronin_credentials_menu}"
exit
