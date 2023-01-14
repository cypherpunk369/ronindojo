#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Add IP Range for Whirlpool GUI"
         2 "Add Specific IP for Whirlpool GUI"
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
            _print_message "Obtain the IP address you wish to give access to Whirlpool CLI..."
            _sleep

            _print_message "Your IP address on the network may look like 192.168.4.21 or 12.34.56.78 depending on setup..."
            _sleep

            _print_message "Enter the local IP address you wish to give Whirlpool CLI access now..."

            read -rp 'Local IP Address: ' ip_address
            sudo ufw allow from "$ip_address"/24 to any port 8899 comment 'Whirlpool CLI access restricted to local LAN only'

            _print_message "Reloading..."
            sudo ufw reload
            # reload the firewall

            _print_message "Showing status..."
            _sleep
            sudo ufw status
            # show firewall status

            _print_message "Make sure that you see your new rule!"
            _sleep

            _pause return
            bash -c "${ronin_firewall_menu2}"
            # press any key to return to menu
            ;;
        2)
            _print_message "Obtain the IP address you wish to give access to Whirlpool CLI..."
            _sleep
            _print_message "Your IP address on the network may look like 192.168.4.21 or 12.34.56.78 depending on setup..."
            _sleep
            _print_message "Enter the local IP address you wish to give Whirlpool CLI access now..."

            read -rp 'Local IP Address: ' ip_address
            sudo ufw allow from "$ip_address" to any port 8899 comment 'Whirlpool CLI access restricted to local LAN only'

            _print_message "Reloading..."
            sudo ufw reload
            # reload the firewall

            _print_message "Showing status..."
            _sleep
            sudo ufw status
            # show firewall status

            _print_message "Make sure that you see your new rule!"
            _sleep

            _pause return

            bash -c "${ronin_firewall_menu2}"
            # press any key to return to menu
            ;;
        *)
            bash -c "${ronin_firewall_menu}"
            ;;
esac
