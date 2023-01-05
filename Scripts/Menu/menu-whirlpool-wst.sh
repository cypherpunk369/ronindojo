#!/bin/bash

# shellcheck source=./Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/defaults.sh

# shellcheck source=./Scripts/functions.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

if [ ! -d "$HOME"/Whirlpool-Stats-Tool ]; then
    _print_message "Installing Whirlpool Stat Tool..."
    _sleep

    _install_wst
fi

_sleep
cd "$HOME"/Whirlpool-Stats-Tool/whirlpool_stats || exit

_print_message "Whirlpool Stat Tool INSTRUCTIONS:"
_print_message "Download in the working directory a snaphot for the 0.01BTC pools:" "download 001"
_print_message "Load and compute the statistcs for the snaphot:" "load 001"
_print_message "Display the metrics computed for a transaction stored in the active snapshot:" "score <ENTER TXID OF DESIRED 0.01 BTC transaction>"
_print_message "Sample output..." \
  "Backward-looking metrics for the outputs of this mix:" \
  "    anonset = 92" \
  "    spread = 89%" \
  "" \
  "Forward-looking metrics for the outputs of Tx0s having this transaction as their first mix:" \
  "    anonset = 127" \
  "    spread = 76%"
_print_message "Type: 'quit' at anytime to exit the Whirlpool Statitics Tool."

_pause continue

pipenv run python wst.py -w=/tmp

_pause return
bash -c "${ronin_samourai_toolkit_menu}"