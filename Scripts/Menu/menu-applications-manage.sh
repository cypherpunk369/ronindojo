#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

upgrade=false
volume_prune=false

# Set mempool install/uninstall status
if ! _is_mempool; then
    is_mempool_installed=false
    mempool_text="Install"
else
    is_mempool_installed=true
    mempool_text="Uninstall"
fi

# Set Bisq install/uninstall status
if ! _is_bisq; then
    is_bisq_installed=false
    bisq_text="Enable"
else
    is_bisq_installed=true
    bisq_text="Disable"
fi

# Set Indexer Install State
_fetch_configured_indexer_type
ret=$?

if ((ret==0)); then
    indexer="Electrs"
    indexer_name="Swap Indexer"
elif ((ret==1)); then
    indexer="SW Addrindexrs"
    indexer_name="Swap Indexer"
elif ((ret==2)); then
    indexer="Fulcrum"
    indexer_name="Swap Indexer"
elif ((ret==3)); then
    indexer="No Indexer"
    indexer_name="Install an Indexer"
fi

cmd=(dialog --title "RoninDojo" --separate-output --checklist "Use Mouse Click or Spacebar to select:" 22 76 16)
options=(1 "${mempool_text} Mempool Space Visualizer" off    # any option can be set to default to "on"
         2 "${bisq_text} Bisq Connection" off
         3 "${indexer_name}" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear
for choice in $choices
do
    case $choice in
        1)
            if ! "${is_mempool_installed}" ; then
                _print_message "Installing Mempool Space Visualizer ${_mempool_version}..."
                _mempool_conf
            else
                _mempool_uninstall || exit
            fi

            upgrade=true
            volume_prune=true
            ;;
        2)
            if ! "${is_bisq_installed}" ; then
                _bisq_install
            else
                _bisq_uninstall
            fi

            upgrade=true
            ;;
        3)
            _print_message "You currently have $indexer installed..."
            _sleep
            _print_message "Select an indexer to use with RoninDojo..."
            _sleep
            _indexer_prompt

            upgrade=true
            ;;
    esac
done

if $upgrade; then
    # Backup any changes made to the confs
    "${is_active_dojo_conf_backup}" && _backup_dojo_confs
    
    if $volume_prune; then
        _dojo_upgrade prune
    else
        _dojo_upgrade
    fi
fi

bash -c "${ronin_applications_menu}"

exit
