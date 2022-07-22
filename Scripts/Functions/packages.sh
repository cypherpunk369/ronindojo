#!/bin/bash
# shellcheck source=Scripts/Functions/packages.sh

_pacman_update_mirrors() {
    sudo pacman --quiet -Syy &>/dev/null
    return 0
}

_install_pkg_if_missing() {
    local update_keyring

    if [ $# -eq 0 ]; then
        echo "No arguments supplied"
    fi

    if [ "$1" = "--update-mirrors" ]; then
        if [ $# -eq 1 ]; then
            echo "No packages supplied as arguments"
        fi
        shift
        _pacman_update_mirrors
    fi

    update_keyring=true

    for pkg in "$@"; do
        if ! pacman -Q "${pkg}"; then

            if [ $update_keyring = true ]; then
                update_keyring=false
                echo "Updating keyring..."
                if ! sudo pacman --quiet -S --noconfirm archlinux-keyring; then
                    echo "Keyring failed to update!"
                    return 1
                fi
            fi

            echo "Installing ${pkg}..."
            if ! sudo pacman --quiet -S --noconfirm "${pkg}"; then
                echo "${pkg} failed to install!"
                return 1
            fi
        fi
    done

    return 0
}
