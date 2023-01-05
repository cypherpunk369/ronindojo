#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

_load_user_conf

OPTIONS=(1 "Update Mirrors"
         2 "Check for RoninDojo Update"
         3 "Update RoninDojo"
         4 "Go Back")

CHOICE=$(dialog --clear \
                --title "$TITLE" \
                --menu "$MENU" \
                "$HEIGHT" "$WIDTH" "$CHOICE_HEIGHT" \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
    1)
        _pacman_update_mirrors
        # Update Mirrors and continue.

        _pause return
        bash -c "${ronin_system_update}"
        ;;
    2)
        if [ -f "${ronin_data_dir}"/ronin-latest.txt ] ; then
            rm "${ronin_data_dir}"/ronin-latest.txt
        fi

        wget -q https://ronindojo.io/downloads/ronindojo-version.txt -O "${ronin_data_dir}"/ronindojo-latest.txt 2>/dev/null

        version=$(<"${ronin_data_dir}"/ronindojo-latest.txt)

        if [[ "${ronindojo_version}" != "${version}" ]] ; then
            cat <<EOF
${red}
***
RoninDojo update is available!
***
${nc}
EOF
            _sleep
        else
            cat <<EOF
${red}
***
No update is available!
***
${nc}
EOF
            _sleep
        fi
        # check for Ronin update from site

        _pause return
        bash -c "${ronin_system_update}"
        ;;

    3)
        if [ ! -d "${dojo_path}" ]; then
            cat <<EOF
${red}
***
Missing ${dojo_path} directory, aborting update...
***
${nc}
EOF
            _sleep

            _pause return

            bash -c "${ronin_system_update}"
            exit 1
        fi
    # is dojo installed?

        cat <<EOF
${red}
***
Updating Arch OS Mirrors, Please wait...
***
${nc}
EOF
        # Update Mirrors
        _pacman_update_mirrors

        cat <<EOF
${red}
***
Updating PNPM, Please wait...
***
${nc}
EOF
        # Update PNPM
        sudo npm i -g pnpm@7 &>/dev/null

        cat <<EOF
${red}
***
Updating RoninDojo...
***
${nc}
EOF
        _sleep

        cat <<EOF
${red}
***
Use Ctrl+C to exit if needed!
***
${nc}
EOF

        _sleep 10 --msg "Updating in"

        _ronindojo_update

        # re-source these scripts before calling functions from them, since they've possible been updated
        . "$HOME"/RoninDojo/Scripts/defaults.sh
        . "$HOME"/RoninDojo/Scripts/functions.sh
        _load_user_conf

        bash "$HOME"/RoninDojo/Scripts/Menu/menu-dojo-upgrade.sh

        _call_update_scripts
        
        bash -c "${ronin_updates_menu}"
        ;;
    4)
        bash -c "${ronin_system_menu}"
        ;;
esac
