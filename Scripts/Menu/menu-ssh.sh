#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Start"
         2 "Stop"
         3 "Restart"
         4 "Enable Public Key Authentication"
         5 "Disable Public Key Authentication"
         6 "Add Public Key"
         7 "Delete Public Key"
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
        _print_message "Starting SSH..."

        if systemctl is-active --quiet sshd; then
            sudo systemctl start --quiet sshd
        else
            _print_message "SSH already started..."
        fi

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    2)
        printf "%s\n***\nStopping SSH...\n***%s\n" "${red}" "${nc}"

        if systemctl is-active --quiet sshd; then
            sudo systemctl stop --quiet sshd
        else
            printf "%s\n***\nSSH already stopped...\n***%s\n" "${red}" "${nc}"
        fi

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    3)
        printf "%s\n***\nRestarting SSH...\n***%s\n" "${red}" "${nc}"

        sudo systemctl reload-or-restart --quiet sshd

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    4)
        # If already enabled, just return to menu
        _ssh_key_authentication enable
        if [ $? -eq 0 ]; then
            _ssh_key_authentication add-ssh-key
            if [ $? -eq 0 ]; then
                printf "%s\n***\nVerify connection now...\n***%s\n" "${red}" "${nc}"

                _pause continue

                _yes_or_no "Did connection work?"
                if [ $? -ne 0 ]; then
                    _ssh_key_authentication disable
                fi

                printf "%s\n***\nReturning to menu...\n***%s\n" "${red}" "${nc}"
            fi
        fi

        _pause continue
        # Return to menu
        bash -c "${ronin_ssh_menu}"
        ;;
    5)
        if ! sudo grep -q "UsePAM no" /etc/ssh/sshd_config; then
            printf "%s\n***\nSSH Key Authentication not enabled! Returning to menu...\n***%s\n" "${red}" "${nc}"
        else
            printf "%s\n***\nDisabling SSH Key Authentication...\n***%s\n\n" "${red}" "${nc}"

            _yes_or_no "${red}Do you wish to continue?${nc}"
            if [ $? -eq 0 ]; then
                _ssh_key_authentication disable
            fi
        fi

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    6)
        if ! sudo grep -q "UsePAM no" /etc/ssh/sshd_config; then
            printf "%s\n***\nSSH Key Authentication not enabled! Returning to menu...\n***%s\n" "${red}" "${nc}"
        else
            _ssh_key_authentication add-ssh-key
            if [ $? -eq 0 ]; then
                printf "%s\n***\nKey successfully added... Returning to menu...\n***%s\n" "${red}" "${nc}"
            else
                printf "%s\n***\nKey already exists... Returning to menu...\n***%s\n" "${red}" "${nc}"
            fi
        fi

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    7)
        if ! sudo grep -q "UsePAM no" /etc/ssh/sshd_config; then
            printf "%s\n***\nSSH Key Authentication not enabled! Returning to menu...\n***%s\n" "${red}" "${nc}"
        else
            _ssh_key_authentication del-ssh-key
            if [ $? -eq 0 ]; then
                printf "%s\n***\nKey has been removed... Returning to menu\n***%s\n" "${red}" "${nc}"
            else
                printf "%s\n***\nKey not available to delete... Returning to menu\n***%s\n" "${red}" "${nc}"
            fi
        fi

        _pause continue
        bash -c "${ronin_ssh_menu}"
        ;;
    8)
        bash -c "${ronin_networking_menu}"
        ;;
    *)
        exit
        ;;
esac
