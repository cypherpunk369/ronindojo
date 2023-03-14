#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Enable"
         2 "Disable"
         3 "Status"
         4 "Delete Rule"
         5 "Reload"
         6 "Add IP Range for SSH"
         7 "Add Specific IP for SSH"
         8 "Next Page"
         9 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        1)
            _print_message "Enabling Firewall..."
            _sleep
            sudo ufw enable
            _pause return
            bash -c "${ronin_firewall_menu}"
            # enable firewall, press any key to return to menu
            ;;
        2)
            _print_message "Disabling Firewall..."
            _sleep
            sudo ufw disable
            _pause return
            bash -c "${ronin_firewall_menu}"
            # disable firewall, press any key to return to menu
            ;;
        3)
            _print_message "Showing Status..."
            _sleep
            sudo ufw status
            _pause return
            bash -c "${ronin_firewall_menu}"
            # show ufw status, press any key to return to menu
            ;;
        4)
            _print_message "Find the rule you want to delete, and type its row number to delete it..."
            _sleep
            sudo ufw status
            # show firewall status

            _print_message "Be careful when deleting old firewall rules! Don't lock yourself out from SSH access..."
            _sleep

            _print_message "Example: If you want to delete the 3rd rule listed, press the number 3, and press Enter..."
            _sleep

            read -rp "Please type the rule number to delete now: " ufw_rule_number
            sudo ufw delete "$ufw_rule_number"
            # request user input to delete a ufw rule

            _print_message "Reloading..."
            sudo ufw reload
            # reload firewall

            _print_message "Showing status..."
            _sleep
            sudo ufw status
            # show firewall status

            _pause return
            bash -c "${ronin_firewall_menu}"
            # press any key to return to menu
            ;;
        5)
            _print_message "Reloading..."
            sudo ufw reload
            _pause return
            bash -c "${ronin_firewall_menu}"
            # reload firewall, press any key to return to menu
            ;;
        6)
            _print_message "Obtain the IP address of any machine on the same local network as your RoninDojo..."
            _sleep
            _print_message "The IP address entered will be adapted to end with .0/24 range..."
            _sleep
            _print_message "This will allow any machine on the same network to have SSH access..."
            _sleep
            _print_message "Your IP address on the network may look like 192.168.4.21 or 12.34.56.78 depending on setup..."
            _sleep
            _print_message "Enter the local IP address you wish to give SSH access now..."
            _sleep

            read -rp 'Local IP Address: ' ip_address
            sudo ufw allow from "$ip_address"/24 to any port 22 comment 'SSH access restricted to local network'

            _print_message "Reloading..."
            sudo ufw reload
            
            _print_message "Showing status..."
            _sleep
            sudo ufw status

            _print_message "Make sure that you see your new rule!"
            _sleep

            _pause return
            bash -c "${ronin_firewall_menu}"
            exit
            ;;
        7)
            _print_message "Obtain the specific IP address you wish to give access to SSH..."
            _sleep
            _print_message "SSH access will be restricted to this IP address only..."
            _sleep
            _print_message "Your IP address on the network may look like 192.168.4.21 or 12.34.56.78 depending on setup..."
            _sleep
            _print_message "Enter the local IP address you wish to give SSH access now..."

            read -rp 'Local IP Address: ' ip_address
            sudo ufw allow from "$ip_address" to any port 22 comment 'SSH access restricted to specific IP'

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
            bash -c "${ronin_firewall_menu}"
            # press any key to return to menu
            ;;
        8)
            bash -c "${ronin_firewall_menu2}"
            # go to next menu page
            ;;
        9)
            bash -c "${ronin_system_menu2}"
            # return system menu page 2
            ;;
esac