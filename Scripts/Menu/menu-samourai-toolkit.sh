#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

OPTIONS=(1 "Whirlpool"
         2 "Boltzmann Calculator"
         3 "Whirlpool Stat Tool"
	     4 "Mix to External zPub"
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
            bash "$HOME"/RoninDojo/Scripts/Menu/menu-whirlpool.sh
            # runs the whirlpool menu script
            ;;
        2)
            bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-boltzmann.sh
            # sent to Boltzmann Calculator
            ;;
        3)
            bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-whirlpool-wst.sh
            # send to WST menu
            ;;
	    4)
	    bash -c "$HOME"/RoninDojo/Scripts/Menu/menu-whirlpool-mixto.sh
	    # send to mixto menu
	    ;;
        5)
            ronin
            # returns to main menu
            ;;
esac
