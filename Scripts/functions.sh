#!/bin/bash
# shellcheck disable=SC2221,SC2222,1004,SC2154,SC2120 source=/dev/null

. "${HOME}"/RoninDojo/Scripts/defaults.sh

#
# Main function runs at beginning of script execution
#
_main() {
    # Create RoninDojo config directory
    test ! -d "$HOME"/.config/RoninDojo && mkdir -p "$HOME"/.config/RoninDojo

    # Create Updates history directory
    test ! -d "$HOME"/.config/RoninDojo/data/updates && mkdir -p "$HOME"/.config/RoninDojo/data/updates

    if [ ! -f "$HOME/.config/RoninDojo/.run" ]; then
        _sleep 5 --msg "Welcome to RoninDojo. Loading in"
        touch "$HOME/.config/RoninDojo/.run"

        # Copy user.conf
        test -f "$HOME"/.config/RoninDojo/user.conf || cp "$HOME"/RoninDojo/user.conf.example "$HOME"/.config/RoninDojo/user.conf
    fi

    # Execute the update scripts (this call here is to be removed in the next release after 1.14)
    _call_update_scripts

    # Create symbolic link for main ronin script
    if [ ! -h /usr/local/bin/ronin ]; then
        sudo ln -sf "$HOME"/RoninDojo/ronin /usr/local/bin/ronin
    fi

    if ! grep RoninDojo "$HOME"/.bashrc 1>/dev/null; then
        cat << EOF >> "$HOME"/.bashrc
if [ -d $HOME/RoninDojo ]; then
$HOME/RoninDojo/Scripts/.logo
ronin
fi
EOF
    fi
    # place main ronin menu script symbolic link at /usr/local/bin folder
    # because most likely that will be path already added to your $PATH variable
    # place logo and ronin main menu script "$HOME"/.bashrc to run at each login

    # Adding user to docker group if needed
    if ! id | grep -q "docker"; then
        if ! id "${ronindojo_user}" | grep -q "docker"; then
            _print_message "Adding user to the docker group and loading RoninDojo CLI..."
        else
            newgrp docker
        fi

        # Create the docker group if not available
        if ! getent group docker 1>/dev/null; then
            sudo groupadd docker 1>/dev/null
        fi

        sudo gpasswd -a "${ronindojo_user}" docker
        _sleep 5 --msg "Reloading RoninDojo in" && newgrp docker
    fi

    # Remove any old legacy fstab entries when systemd.mount is enabled
    if [ -f /etc/systemd/system/mnt-usb.mount ] || [ -f /etc/systemd/system/mnt-backup.mount ]; then
        if [ "$(systemctl is-enabled mnt-usb.mount 2>/dev/null)" = "enabled" ] || [ "$(systemctl is-enabled mnt-backup.mount 2>/dev/null)" = "enabled" ]; then
            if ! _remove_fstab; then
                _print_message "Removing legacy fstab entries and replacing with systemd mount service..."
                _sleep 4 --msg "Starting RoninDojo in"
            fi
        fi
    fi

    # Remove any legacy ipv6.disable entries from kernel line
    if ! _remove_ipv6; then
        _print_message "Removing ipv6 disable setting in kernel line favor of sysctl..."
    fi

    # Check for sudoers file for password prompt timeout
    _set_sudo_timeout

    # Force dependency on docker and tor unit files to depend on
    # external drive mount
    _systemd_unit_drop_in_check
}

_call_update_scripts() {
    . "$HOME"/RoninDojo/Scripts/update.sh

    if [ -f "${ronin_data_dir}"/system-install ]; then

        _update_05 # Check on tor unit service
        test -f "$HOME"/.config/RoninDojo/data/updates/15-* || _update_15 # Remove duplicate bisq integration changes
        test -f "$HOME"/.config/RoninDojo/data/updates/17-* || _update_17 # Uninstall legacy Ronin UI
        test -f "$HOME"/.config/RoninDojo/data/updates/19-* || _update_19 # Uninstall bleeding edge Node.js and install LTS Node.js
        test -f "$HOME"/.config/RoninDojo/data/updates/22-* || _update_22 # Remove any existing docker-mempool.conf in favor of new tpl for v2
        _update_24 # Fix hosts file, rerun always in case OS update reverts it
        test -f "$HOME"/.config/RoninDojo/data/updates/25-* || _update_25 # Remove specter
        test -f "$HOME"/.config/RoninDojo/data/updates/26-* || _update_26 # Fix for 1.13.1 users that salvaged and thus miss the gpio setup
        test -f "$HOME"/.config/RoninDojo/data/updates/27-* || _update_27 # Updated the mempool and db_cache size settings for bitcoind
        test -f "$HOME"/.config/RoninDojo/data/updates/28-* || _update_28 # Fix for users getting locked-out of their Ronin UI
        test -f "$HOME"/.config/RoninDojo/data/updates/29-* || _update_29 # Update Node.js and pnpm if necessary
        test -f "$HOME"/.config/RoninDojo/data/updates/31-* || _update_31 # Add service to auto detect network change, overwrite previous version if exists, of ronin.network.service
        test -f "$HOME"/.config/RoninDojo/data/updates/32-* || _update_32 # Modify pacman to Ignore specific packages
        # _update_33 is executred as part of dojo upgrade script
        test -f "$HOME"/.config/RoninDojo/data/updates/34-* || _update_34 # Call _setup_storage_config to set the files
    else
        # make sure the upper bound of this for loop here, stays up-to-date with the update numbering
        for i in $(seq 1 9); do
            echo "skipped" > "$HOME"/.config/RoninDojo/data/updates/0${i}-"$(date +%m-%d-%Y)"
        done
        for i in $(seq 10 34); do
            echo "skipped" > "$HOME"/.config/RoninDojo/data/updates/${i}-"$(date +%m-%d-%Y)"
        done
    fi
}

#
# Prints a message in the RoninDojo human messaging format
# Usage: _print_message "The billboard message here" ["extra lines below the billboard here" [..]]
#
_print_message() {
    cat <<EOF
${red}
***
$1
***
${nc}
EOF
    while [ $# -gt 1 ]; do
        echo $2
        shift 1
    done
}

#
# Prints an error message in the RoninDojo human messaging format
#
_print_error_message() {
    cat >&2 <<EOF
${red}
***
ERROR: $1
***
${nc}
EOF
}


#
# Update pacman mirrors
#
_pacman_update_mirrors() {
    sudo pacman --quiet -Syy &>/dev/null
    return 0
}

#create a directory at the given path argument
_create_dir() {
    if test ! -d "${1}"; then
        mkdir -p "${1}"
    fi
}

#
# Random Password
#
_rand_passwd() {
    local _length
    _length="${1:-16}"

    tr -dc 'a-zA-Z0-9' </dev/urandom | head -c"${_length}"
}

#
# Load user defined variables
#
_load_user_conf() {
    if [ -f "${HOME}/.config/RoninDojo/user.conf" ]; then
      . "${HOME}/.config/RoninDojo/user.conf"
    fi
}

#
# Set systemd unit dependencies for docker and tor unit files
# to depend on ${install_dir} mount point
#
_systemd_unit_drop_in_check() {
    _load_user_conf

    local tmp systemd_mountpoint

    tmp=${install_dir:1}               # Remove leading '/'
    systemd_mountpoint=${tmp////-}     # Replace / with -

    for x in docker tor; do
        if [ -f "/etc/systemd/system/${x}.service.d/override.conf" ]; then
            continue
        fi

        test -d "/etc/systemd/system/${x}.service.d" || sudo mkdir "/etc/systemd/system/${x}.service.d"

        if [ -f "/etc/systemd/system/${systemd_mountpoint}.mount" ]; then
            sudo tee "/etc/systemd/system/${x}.service.d/override.conf" <<EOF >/dev/null
[Unit]
RequiresMountsFor=${install_dir}
EOF
        fi

        sudo systemctl daemon-reload
    done
}

#
# Sets timeout for sudo prompt to 15mins
#
_set_sudo_timeout() {
    if [ ! -f /etc/sudoers.d/21-ronindojo ]; then
        sudo tee "/etc/sudoers.d/21-ronindojo" <<EOF >/dev/null
Defaults env_reset,timestamp_timeout=15
EOF
    fi
}

#
# DEPRECATED, USE _install_pkg_if_missing
# Check if package is installed or not
#
_check_pkg() {
    local pkg_bin pkg_name update
    pkg_bin="${1}"
    pkg_name="${2:-$1}"
    update=false

    # Parse Arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --update-mirrors)
                update=true
                break
                ;;
            *)
                shift 1
                ;;
        esac
    done

    [ "${pkg_name}" = "--update-mirrors" ] && pkg_name="${pkg_bin}"

    "${update}" && _pacman_update_mirrors

    if ! hash "${pkg_bin}" 2>/dev/null; then
        _print_message "Installing ${pkg_name}..."
        if ! sudo pacman --quiet -S --noconfirm "${pkg_name}" &>/dev/null; then
            _print_error_message "${pkg_name} failed to install!"
            return 1
        else
            return 0
        fi
    fi

    return 1
}

#
# Installs a package if not yet installed, return false if an install failed.
# Usage: _install_pkg_if_missing [--update-mirrors] package1 [pacakge2[..]]
#
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
        if ! pacman -Q "${pkg}" 1>/dev/null 2>/dev/null; then

            if [ $update_keyring = true ]; then
                update_keyring=false
                _print_message "Updating keyring..."

                if ! sudo pacman --quiet -S --noconfirm archlinux-keyring &>/dev/null; then
                    _print_error_message "Keyring failed to update!"
                    return 1
                fi
            fi

            _print_message "Installing ${pkg}..."

            if ! sudo pacman --quiet -S --noconfirm "${pkg}" &>/dev/null; then
                _print_error_message "${pkg} failed to install!"
                return 1
            fi
        fi
    done

    return 0
}


#
# Package version match
#
_check_pkg_ver() {
    local pkgver pkg

    pkgver="${2}"
    pkg="${1}"

    if pacman -Q "${pkg}" &>/dev/null && [[ $(pacman -Q "${pkg}" | awk '{print$2}') < "${pkgver}" ]]; then
        return 1
    fi

    return 0
}

#
# Countdown timer
# Usage: _sleep <seconds> --msg "your message"
#
_sleep() {
    local secs msg verbose
    secs=1 verbose=false

    # Parse Arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            (*[0-9]*)
                secs="$1"
                shift
                ;;
            --msg)
                msg="$2"
                verbose=true
                shift 2
                ;;
        esac
    done

    while [ "$secs" -gt 0 ]; do
        if $verbose; then
            printf "%s%s %s\033[0K seconds...%s\r" "${red}" "${msg}" "${secs}" "${nc}"
        fi
        sleep 1
        : $((secs--))
    done
    printf "\n" # Add new line
}

#
# Pause & return or continue
#
_pause() {
    _print_message "Press any key to ${1}..."
    read -n 1 -r -s
}

#
# Check if unit file exist
#
_systemd_unit_exist() {
    local service
    service="$1"

    if systemctl cat -- "$service" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

#
# Returns whether systemd unit service is active
#
_is_active() {
    local service
    service="$1"

    if systemctl is-active --quiet "$service"; then
        return 0
    else
        return 1
    fi
}

#
# Starts systemd unit service
#
_start_service() {
    local service
    service="$1"

    sudo systemctl start --quiet "$service"
}

#
# Starts systemd unit service if inactive
#
_start_service_if_inactive() {
    local service
    service="$1"

    if ! _is_active "$service"; then
        _start_service "$service"
    fi
}

#
# Setup torrc
#
_setup_tor() {
    _load_user_conf

    # If the setting is already active, assume user has configured it already
    if ! grep -E "^\s*DataDirectory\s+.+$" /etc/tor/torrc 1>/dev/null; then
        _print_message "Initial Tor Configuration..."

        # Default config file has example value #DataDirectory /var/lib/tor,
        if grep -E "^#DataDirectory" /etc/tor/torrc 1>/dev/null; then
            sudo sed -i "s:^#DataDirectory .*$:DataDirectory ${install_dir_tor}:" /etc/tor/torrc
        fi

    else
        sudo sed -i "s:^DataDirectory .*$:DataDirectory ${install_dir_tor}:" /etc/tor/torrc
    fi

    # Setup directory
    if [ ! -d "${install_dir_tor}" ]; then
        _print_message "Creating Tor directory..."
        sudo mkdir "${install_dir_tor}"
    fi

    # Check for ownership
    if ! [ "$(stat -c "%U" "${install_dir_tor}")" = "tor" ]; then
        sudo chown -R tor:tor "${install_dir_tor}"
    fi

    if ! systemctl is-active --quiet tor; then
        sudo sed -i 's:^ReadWriteDirectories=-/var/lib/tor.*$:ReadWriteDirectories=-/var/lib/tor /mnt/usb/tor:' /usr/lib/systemd/system/tor.service
        sudo systemctl daemon-reload
        sudo systemctl restart --quiet tor
    fi

    _print_message "Setting up the Tor service..."

    # Enable service on startup
    if ! systemctl is-enabled --quiet tor; then
        sudo systemctl enable --quiet tor
    fi

    _start_service_if_inactive tor
}

#
# Is Fulcrum Server Installed
#
_is_fulcrum() {
    if ! grep "INDEXER_TYPE=fulcrum" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 1
    fi

    return 0
}

#
# Is Electrs Server Installed
#
_is_electrs() {
    if ! grep "INDEXER_TYPE=electrs" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 1
    fi

    return 0
}

#
# Ronin UI torrc
#
_ronin_ui_setup_tor() {
    if ! grep hidden_service_ronin_backend /etc/tor/torrc 1>/dev/null; then
        _print_message "Configuring RoninDojo Backend Tor Address..."

        sudo sed -i "/################ This section is just for relays/i\
HiddenServiceDir ${install_dir_tor}/hidden_service_ronin_backend/\n\
HiddenServiceVersion 3\n\
HiddenServicePort 80 127.0.0.1:8470\n\
" /etc/tor/torrc

        # restart tor service
        sudo systemctl restart --quiet tor
    fi

    # Populate or update "${ronin_data_dir}"/ronin-ui-tor-hostname with tor address
    if [ ! -f "${ronin_data_dir}"/ronin-ui-tor-hostname ]; then
        sudo bash -c "cat ${install_dir_tor}/hidden_service_ronin_backend/hostname >${ronin_data_dir}/ronin-ui-tor-hostname"
    elif ! sudo grep -q "$(sudo cat "${install_dir_tor}"/hidden_service_ronin_backend/hostname)" "${ronin_data_dir}"/ronin-ui-tor-hostname; then
        sudo bash -c "cat ${install_dir_tor}/hidden_service_ronin_backend/hostname >${ronin_data_dir}/ronin-ui-tor-hostname"
    fi
}

#
# Check Ronin UI Installation
#
_is_ronin_ui() {
    _load_user_conf

    if [ ! -d "${ronin_ui_path}" ]; then
        return 1
    fi

    return 0
}

#
# Install Ronin UI
#
_ronin_ui_install() {
    . "${HOME}"/RoninDojo/Scripts/generated-credentials.sh

    _load_user_conf

    cd "$HOME" || exit

    _print_message "Checking package dependencies for Ronin UI..."
    _sleep

    _check_pkg "nginx"
    _check_pkg "pm2"
    _check_pkg "avahi-daemon" "avahi"

    sudo npm i -g pnpm@7 &>/dev/null

    test -d "${ronin_ui_path}" || mkdir "${ronin_ui_path}"
    cd "${ronin_ui_path}" || exit

    wget -q "${roninui_version_file}" -O /tmp/version.json 2>/dev/null

    _file=$(jq -r .file /tmp/version.json)
    _shasum=$(jq -r .sha256 /tmp/version.json)

    wget -q https://ronindojo.io/downloads/RoninUI/"$_file" 2>/dev/null

    if ! echo "${_shasum} ${_file}" | sha256sum --check --status; then
        _bad_shasum=$(sha256sum ${_file})
        _print_error_message "Ronin UI archive verification failed! Valid sum is ${_shasum}, got ${_bad_shasum} instead..."
    fi
      
    tar xzf "$_file"

    rm "$_file" /tmp/version.json

        # Mark Ronin UI initialized if necessary
        if [ "${1}" = "--initialized" ]; then
          echo -e "{\"initialized\": true}\n" > ronin-ui.dat
        fi

        # Generate .env file
        echo "JWT_SECRET=$gui_jwt" > .env
        echo "NEXT_TELEMETRY_DISABLED=1" >> .env

    if [ "${roninui_version_staging}" = true ] ; then
        echo -e "VERSION_CHECK=staging\n" >> .env
    fi

    _print_message "Performing pnpm install, please wait..."

    pnpm install --prod &>/dev/null || { printf "\n%s***\nRonin UI pnpm install failed...\n***%s\n" "${red}" "${nc}";exit; }

    _print_message "Performing Next start, please wait..."

    pm2 start pm2.config.js &>/dev/null
    pm2 save &>/dev/null
    pm2 startup &>/dev/null

    sudo env PATH="$PATH:/usr/bin" /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u "${ronindojo_user}" --hp "$HOME" &>/dev/null

    _ronin_ui_setup_tor

    _ronin_ui_vhost

    _ronin_ui_avahi_service
    
}

#
# Setup avahi service for ronindojo.local access
#
_ronin_ui_avahi_service() {
    if [ ! -f /etc/avahi/services/http.service ]; then
        sudo tee "/etc/avahi/services/http.service" <<EOF >/dev/null
<?xml version="1.0" standalone='no'?><!--*-nxml-*-->
<!DOCTYPE service-group SYSTEM "avahi-service.dtd">
<!-- This advertises the RoninDojo vhost -->
<service-group>
 <name replace-wildcards="yes">%h Web Application</name>
  <service>
   <type>_http._tcp</type>
   <port>80</port>
  </service>
</service-group>
EOF

    fi

    sudo sed -i 's/hosts: .*$/hosts: files mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns/' /etc/nsswitch.conf

    if ! grep -q "host-name=ronindojo" /etc/avahi/avahi-daemon.conf; then
        sudo sed -i 's/.*host-name=.*$/host-name=ronindojo/' /etc/avahi/avahi-daemon.conf
    fi

    sudo systemctl restart avahi-daemon

    if ! systemctl is-enabled --quiet avahi-daemon; then
        sudo systemctl enable --quiet avahi-daemon
    fi

    return 0
}

#
# Setup nginx reverse proxy for Ronin UI
#
_ronin_ui_vhost() {
    if [ ! -f /etc/nginx/sites-enabled/001-roninui ]; then
        local _tor_hostname
        _tor_hostname=$(sudo cat "${install_dir_tor}"/hidden_service_ronin_backend/hostname)

        test -d /etc/nginx/sites-enabled || sudo mkdir /etc/nginx/sites-enabled
        test -d /var/log/nginx || sudo mkdir /var/log/nginx
        test -d /etc/nginx/logs || sudo mkdir /etc/nginx/logs

        # Generate nginx.conf
        sudo tee "/etc/nginx/nginx.conf" <<EOF >/dev/null
worker_processes  2;
worker_rlimit_nofile 65535;

error_log  logs/error.log;
error_log  logs/error.log  notice;
error_log  logs/error.log  info;

events {
    worker_connections  8192;
    use epoll;

    multi_accept on;
}

http {
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    client_header_timeout 10m;
    client_body_timeout 10m;
    client_max_body_size 0;
    client_header_buffer_size 1k;

    keepalive_timeout  10 10;

    gzip  on;
    gzip_buffers 16 8k;
    gzip_comp_level 1;
    gzip_http_version 1.1;
    gzip_min_length 10;
    gzip_types text/plain text/css application/x-javascript text/xml application/xml application/xlm+rss text/javascript image/x-icon application/vnd.ms-fontobject font/opentype application/x-font-ttf;
    gzip_vary off;
    gzip_proxied any;
    gzip_disable "msie6";
    gzip_static off;

    server_tokens off;
    limit_conn_zone \$binary_remote_addr zone=arbeit:10m;
    connection_pool_size 256;
    reset_timedout_connection on;
    ignore_invalid_headers on;

    include /etc/nginx/sites-enabled/*;
}
EOF

        # Generate default server vhost
        sudo tee "/etc/nginx/sites-enabled/000-default" <<EOF >/dev/null
server {
    listen 80 default_server;

    server_name_in_redirect off;
    return 444;
}
EOF

        # Generate Ronin UI reverse proxy server vhost
        sudo tee "/etc/nginx/sites-enabled/001-roninui" <<EOF >/dev/null
server {
    listen ${ip_current}:80;
    server_name ronindojo ${_tor_hostname};

    ## Access and error logs.
    access_log /var/log/nginx/ronindojo_access.log;
    error_log /var/log/nginx/ronindojo_error.log;

    # Prevent iframe jacking
    add_header X-Frame-Options "SAMEORIGIN";

    # Prevent clickjacking attacks
    add_header X-Frame-Options DENY;

    # Prevent "mime" based attacks
    add_header X-Content-Type-Options nosniff;

    # Prevent XSS attacks
    add_header X-XSS-Protection "1; mode=block";

    location / {
        proxy_http_version      1.1;
        proxy_set_header        Upgrade \$http_upgrade;
        proxy_set_header        Connection "upgrade";
        proxy_set_header        Host \$http_host;
        proxy_cache_bypass      \$http_upgrade;
        proxy_next_upstream     error timeout http_502 http_503 http_504;
        proxy_pass              http://127.0.0.1:8470;
        send_timeout            180s;
    }
}
EOF
    elif ! sudo grep -q "${ip_current}" /etc/nginx/sites-enabled/001-roninui; then
        # Updates the ip in vhost
        sudo sed -i "s/listen .*$/listen ${ip_current}:80;/" /etc/nginx/sites-enabled/001-roninui

        # Reload nginx server
        sudo systemctl reload --quiet nginx
    fi

    # Enable nginx on boot
    if ! systemctl is-enabled --quiet nginx; then
        sudo systemctl enable --quiet nginx
    fi

    # Start nginx service
    _start_service_if_inactive nginx

    return 0
}

#
# Ronin UI Uninstall
#
_ronin_ui_uninstall() {
    cd "${ronin_ui_path}" || exit

    _print_message "Uninstalling Ronin UI..."
    _sleep

    # Delete app from process list
    pm2 delete "RoninUI" &>/dev/null

    # dump all processes for resurrecting them later
    pm2 save 1>/dev/null

    # Remove ${ronin_ui_path}
    cd "${HOME}" || exit

    rm -rf "${ronin_ui_path}" || exit

    # Remove nginx vhost and disable nginx on boot
    sudo rm /etc/nginx/sites-enabled/001-roninui
    sudo systemctl disable --now nginx

    # Disable avahi host and disable avahi-daemon on boot
    sudo rm /etc/avahi/services/http.service
    sudo systemctl disable --now avahi-daemon

    return 0
}

#
# Returns whether this system has fan control.
# For only support Rockpro64 boards.
#
_has_fan_control() {
    if grep 'rockpro64' /etc/manjaro-arm-version &>/dev/null; then
        # Find fan control file
        cd /sys/class/hwmon || exit

        for dir in *; do
            if [ -f "${dir}/pwm1" ]; then
                hwmon_dir="${dir}"
                return 0
            fi
        done
    fi

    return 1
}

#
# Is fan control installed
#
_is_fan_control_installed() {
    if [ -d "${HOME}"/bitbox-base ]; then
        return 0
    fi

    return 1
}

#
# Install fan control for rockchip boards
#
_fan_control_install() {
    local upgrade
    upgrade=false

    if ! _is_fan_control_installed; then
        git clone -q https://github.com/digitalbitbox/bitbox-base.git &>/dev/null || return 1
        cd bitbox-base/tools/bbbfancontrol || return 1
    else
        sudo systemctl stop --quiet bbbfancontrol

        if ! _fan_control_upgrade; then
            return 1
        fi

        upgrade=true
    fi

    _fan_control_compile || return 1

    _fan_control_unit_file || return 1

    _start_service_if_inactive bbbfancontrol

    if "${upgrade}"; then
        _print_message "Fan control upgraded..."
    else
        _print_message "Fan control installed..."
    fi

    return 0
}

#
# Install fan control for rockchip boards
#
_fan_control_uninstall() {
    if _is_fan_control_installed && [ -f /etc/systemd/system/bbbfancontrol.service ]; then

        sudo systemctl stop --quiet bbbfancontrol

        sudo systemctl disable --quiet bbbfancontrol

        sudo rm /etc/systemd/system/bbbfancontrol.service

        rm -rf "${HOME}"/bitbox-base || exit

        _print_message "Fan control Uninstalled..."
    fi

    return 0
}

#
# Fan Control systemd unit file
#
_fan_control_unit_file() {
    if [ ! -f /etc/systemd/system/bbbfancontrol.service ]; then
        sudo tee "/etc/systemd/system/bbbfancontrol.service" <<EOF >/dev/null
[Unit]
Description=BitBoxBase fancontrol
After=local-fs.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/bbbfancontrol --tmin 60 --tmax 75 --cooldown 55 -fan /sys/class/hwmon/${hwmon_dir}/pwm1
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl enable --quiet bbbfancontrol
        sudo systemctl start --quiet bbbfancontrol
    else # Previous unit file found
        # Update unit file if hwmon directory location changed
        if ! grep "${hwmon_dir}" /etc/systemd/system/bbbfancontrol.service 1>/dev/null; then
            sudo sed -i "s:/sys/class/hwmon/hwmon[0-9]/pwm1:/sys/class/hwmon/${hwmon_dir}/pwm1:" /etc/systemd/system/bbbfancontrol.service

            # Reload systemd unit file & restart daemon
            sudo systemctl daemon-reload
            sudo systemctl restart --quiet bbbfancontrol.service
        fi
    fi

    return 0
}

#
# Fan Control build package
#
_fan_control_compile() {
    # Build package
    go build || return 1

    sudo cp bbbfancontrol /usr/local/sbin/

    return 0
}

#
# Update fan control for rockchip boards
#
_fan_control_upgrade() {
    cd "${HOME}"/bitbox-base || exit

    if (($(git pull --rebase|wc -l)>1)); then
        cd tools/bbbfancontrol || return 1
        return 0
    else
        return 1
    fi
}

_set_addrindexrs() {
    sudo sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/INDEXER_TYPE=.*$/INDEXER_TYPE=addrindexrs/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

_set_fulcrum() {
    sudo sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/INDEXER_TYPE=.*$/INDEXER_TYPE=fulcrum/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

_set_electrs() {
    sudo sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=on/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/INDEXER_TYPE=.*$/INDEXER_TYPE=electrs/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_indexer/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

_set_no_indexer() {
    sudo sed -i 's/INDEXER_INSTALL=.*$/INDEXER_INSTALL=off/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/INDEXER_TYPE=.*$/INDEXER_TYPE=electrs/' "${dojo_path_my_dojo}"/conf/docker-indexer.conf
    sudo sed -i 's/NODE_ACTIVE_INDEXER=.*$/NODE_ACTIVE_INDEXER=local_bitcoind/' "${dojo_path_my_dojo}"/conf/docker-node.conf

    return 0
}

#
# Checks what indexer is set if any
#
_fetch_configured_indexer_type() {
    if ! grep "NODE_ACTIVE_INDEXER=local_indexer" "${dojo_path_my_dojo}"/conf/docker-node.conf 1>/dev/null; then
        return 3
        # No indexer      
    elif ! grep "INDEXER_INSTALL=on" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 3
        # No indexer
    elif grep "INDEXER_TYPE=electrs" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 0
        # Found electrs
    elif grep "INDEXER_TYPE=addrindexrs" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 1
        # Found SW indexer
    elif grep "INDEXER_TYPE=fulcrum" "${dojo_path_my_dojo}"/conf/docker-indexer.conf 1>/dev/null; then
        return 2
        # Found fulcrum
    fi
}

#
# Offer user choice of indexer
#
_indexer_prompt() {
    . "$HOME"/RoninDojo/Scripts/defaults.sh
    
    _print_message "Preparing the Indexer Prompt..."
    _sleep 3

    _print_message "Samourai Indexer is only recommended for light wallet use. Do not use if you have been a long time user of Whirlpool..."
    _sleep 3

    _print_message "Fulcrum Server is recommended for Wallets with heavy use, Hardware Wallets, Multisig, and other Electrum features..."
    _sleep 1
    _print_message "Fulcrum has a longer indexer time than Electrs, but much more robust for heavier wallets..."
    _sleep 3

    _print_message "Electrs is recommended for Hardware Wallets, Multisig, and other Electrum features..."
    _sleep 1
    _print_message "Electrs has a faster indexer time than Fulcrum, but less reliable for heavier wallets..."
    _sleep 3

    _print_message "Choose one of the following options for your Indexer..."
    _sleep

    while true; do
        select indexer in "Samourai Indexer" "Fulcrum" "Electrs" "No Indexer"; do
            case $indexer in
                "Samourai Indexer")
                    _print_message "Selected Samourai Indexer..."
                    _sleep
                    _set_addrindexrs
                    return
                    ;;
                "Fulcrum")
                    _print_message "Selected Fulcrum..."
                    _sleep
                    _set_fulcrum
                    return
                    ;;
                "Electrs")
                    _print_message "Selected Electrs..."
                    _sleep
                    _set_electrs
                    return
                    ;;
                "No Indexer")
                    _print_message "Selected No Indexer...Removing any other indexer data"
                    _sleep
                    _set_no_indexer
                    return
                    ;;
                *)
                    _print_message "Invalid Entry! Valid values are 1, 2, or 3..."
                    _sleep
                    break
                    ;;
            esac
        done
    done
    exit 1
}

#
# Check if dojo directory is missing
#
_is_dojo() {
    local menu
    menu="$1"

    if [ ! -d "${dojo_path}" ]; then
        _print_message "Missing ${dojo_path} directory!"
        _pause return
        bash -c "$menu"
        exit 1
fi
}

#
# Check if mempool enabled
#
_is_mempool() {
    if grep "MEMPOOL_INSTALL=off" "${dojo_path_my_dojo}"/conf/docker-mempool.conf 1>/dev/null; then
        return 1
    else
        return 0
    fi
}

#
# Uninstall Mempool Space Visualizer
#
_mempool_uninstall() {
    . "${HOME}"/RoninDojo/Scripts/dojo-defaults.sh

    _print_message "Uninstalling Mempool Space Visualizer ${_mempool_version}..."
    sed -i 's/MEMPOOL_INSTALL=.*$/MEMPOOL_INSTALL=off/' "$dojo_path_my_dojo"/conf/docker-mempool.conf
    # Turns mempool install set to off

    _print_message "Mempool Space Visualizer ${_mempool_version} Uninstalled..."
    return 0
}

#
# Setup mempool docker variables
#
_mempool_conf() {
    if ! grep -q 'MYSQL_USER=mempool' "${dojo_path_my_dojo}"/conf/docker-mempool.conf; then # Existing install
        MEMPOOL_MYSQL_USER=$(grep MYSQL_USER "${dojo_path_my_dojo}"/conf/docker-mempool.conf | cut -d '=' -f2)
        MEMPOOL_MYSQL_PASS=$(grep MYSQL_PASS "${dojo_path_my_dojo}"/conf/docker-mempool.conf | cut -d '=' -f2)
        MEMPOOL_MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD "${dojo_path_my_dojo}"/conf/docker-mempool.conf | cut -d '=' -f2)
    else
        # Generate mempool MySQL credentials for a fresh install
        . "${HOME}"/RoninDojo/Scripts/generated-credentials.sh
    fi

    # source values for docker-bitcoind.conf
    . "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf

    _load_user_conf

    # Enable mempool and set MySQL credentials
    sed -i -e 's/MEMPOOL_INSTALL=.*$/MEMPOOL_INSTALL=on/' \
    -e "s/MEMPOOL_MYSQL_USER=.*$/MEMPOOL_MYSQL_USER=${MEMPOOL_MYSQL_USER}/" \
    -e "s/MEMPOOL_MYSQL_PASS=.*$/MEMPOOL_MYSQL_PASS=${MEMPOOL_MYSQL_PASS}/" \
    -e "s/MEMPOOL_MYSQL_ROOT_PASSWORD=.*$/MEMPOOL_MYSQL_ROOT_PASSWORD=${MEMPOOL_MYSQL_ROOT_PASSWORD}/" "${dojo_path_my_dojo}"/conf/docker-mempool.conf
}

#
# Update Samourai Dojo Repository
#
_dojo_update() {
    _load_user_conf

    if [ ! -d "${dojo_path}" ]; then
        _print_error_message "Missing git repo data folder in dojo!"
        _pause "to exit"
        exit 1
    fi

    cd "${dojo_path}" || exit

    git fetch -q --tags --force
    git checkout -q -f "${samourai_commitish}"

    _print_message "Dojo codebase updated!"
    _sleep
}

#
# Upgrade Samourai Dojo
#
_dojo_upgrade() {
    _print_message "Performing Dojo upgrade"
    _stop_dojo

    . dojo.sh upgrade --nolog --auto

    # get rid of orphan volumes
    if [ "${1}" = "prune" ]; then
        docker volume prune -f &>/dev/null
    fi

    _pause return
}

#
# Asserts dojo to be installed
#
_assert_dojo_is_installed() {
    _load_user_conf

    if ! findmnt "${install_dir}" 1>/dev/null; then
        _print_error_message "Missing drive mount at ${install_dir}!"
        _print_error_message "Please contact support for assistance..."
        _pause exit
        exit
    fi

    if ! _is_active docker; then
        _print_error_message "Expected docker to be running, but it wasn't!"
        _print_error_message "Please contact support for assistance..."
        _pause exit
        exit
    fi

    if [ ! -d "${dojo_path}" ]; then
        _print_error_message "Expected dojo to be installed, but it wasn't!"
        _print_error_message "Please contact support for assistance..."
        _pause exit
        exit
    fi
}

#
# Returns whether or not dojo is running
#
_is_dojo_running() {
    if [ "$(docker inspect --format='{{.State.Running}}' db 2>/dev/null)" = "true" ]; then
        return 0
    fi

    return 1
}

#
# Source DOJO confs
#
_source_dojo_conf() {
    for conf in conf/docker-{whirlpool,indexer,bitcoind,explorer,mempool}.conf .env; do
        test -f "${conf}" && . "${conf}"
    done

    export BITCOIND_RPC_EXTERNAL_IP INDEXER_RPC_PORT BITCOIND_RPC_USER BITCOIND_RPC_PASSWORD BITCOIND_RPC_PORT
}

#
# Stop Samourai Dojo containers
#
_stop_dojo() {
    
    _assert_dojo_is_installed

    _print_message "Shutting down Dojo..."
    _sleep

    cd "${dojo_path_my_dojo}" || exit
    ./dojo.sh stop

    return 0
}

#
# Start Samourai Dojo containers
#
_start_dojo() {

    _assert_dojo_is_installed

    _print_message "Starting Dojo..."
    _sleep

    cd "${dojo_path_my_dojo}" || exit 1
    ./dojo.sh start

    return 0
}


#
# Remove old fstab entries in favor of systemd.mount.
#
_remove_fstab() {
    if grep -E '(^UUID=.* /mnt/(usb1?|backup) ext4)' /etc/fstab 1>/dev/null; then
        sudo sed -i '/\/mnt\/usb\|backup ext4/d' /etc/fstab
        return 1
    fi

    return 0
}

#
# Remove ipv6 from kernel line in favor of sysctl
#
_remove_ipv6() {
    if [ -f /boot/cmdline.txt ]; then
        if grep ipv6.disable /boot/cmdline.txt 1>/dev/null; then
            sudo sed -i 's/ipv6.disable=1//' /boot/cmdline.txt
            return 1
        fi
        # for RPI hardware
    elif [ -f /boot/boot.ini ]; then
        if grep ipv6.disable /boot/boot.ini 1>/dev/null; then
            sudo sed -i 's/ipv6.disable=1//' /boot/boot.ini
            return 1
        fi
        # for Odroid or RockPro64 hardware
    fi

    return 0
}

#
# Update RoninDojo
#
_ronindojo_update() {
    _load_user_conf

    if [ ! -d "$HOME"/RoninDojo/.git ]; then
        _print_error_message "Missing git repo data folder in RoninDojo!"
        _pause "to exit"
        exit 1
    fi

    cd "$HOME/RoninDojo" || exit

    # Fetch remotes
    git fetch -q --tags --force
    git checkout -q -f "${ronin_dojo_branch}"

    _print_message "RoninDojo updated!"
    _sleep
}

#
# Docker Data Directory
#
_docker_datadir_setup() {
    _print_message "Now configuring docker to use the external SSD..."
    test -d "${install_dir_docker}" || sudo mkdir "${install_dir_docker}"
    # makes directory to store docker/dojo data

    if [ -d /etc/docker ]; then
        _print_message "The /etc/docker directory already exists..."
    else
        _print_message "Creating /etc/docker directory."
        sudo mkdir /etc/docker
        # makes docker directory
    fi

    # We can skip this if daemon.json was previous created
    if [ ! -f /etc/docker/daemon.json ]; then
        sudo bash -c "cat << EOF > /etc/docker/daemon.json
{ \"data-root\": \"${install_dir_docker}\" }
EOF"
        _print_message "Starting docker daemon."
    fi

    _start_service_if_inactive docker

    # Enable service on startup
    if ! sudo systemctl is-enabled --quiet docker; then
        sudo systemctl enable --quiet docker
    fi

    return 0
}

#
# Check dojo directory and file permissions
# to make sure that there are no root owned files
# from legacy use of `sudo ./dojo.sh`
#
_check_dojo_perms() {
    local dojo_path_my_dojo="${1}"

    if find "${dojo_path}" -user root | grep -q '.'; then
        _stop_dojo

        # Change ownership so that we don't
        # need to use sudo ./dojo.sh
        sudo chown -R "${ronindojo_user}:${ronindojo_user}" "${dojo_path}"
    else
        _stop_dojo
    fi

    return 0
}

#
# Disable ipv6
#
_disable_ipv6() {
    # Add sysctl setting to prevent any network devices
    # from being assigned any IPV6 addresses
    if [ ! -f /etc/sysctl.d/40-ipv6.conf ]; then
        sudo bash -c 'cat <<EOF >/etc/sysctl.d/40-ipv6.conf
# Disable IPV6
net.ipv6.conf.all.disable_ipv6 = 1
EOF'
    else
        return 1
    fi

    # Check to see if ipv6 stack available and if so
    # restart sysctl service
    if [ -d /proc/sys/net/ipv6 ]; then
        sudo systemctl restart --quiet systemd-sysctl
    fi

    return 0
}

#
# Disable Bluetooth
#
_disable_bluetooth() {
    _systemd_unit_exist bluetooth || return 1

    if _is_active bluetooth; then
        sudo systemctl --quiet disable bluetooth
        sudo systemctl stop --quiet bluetooth
        return 0
    fi
}

#
# Makes sure we don't already have swapfile enabled
#
check_swap() {
    local swapfile
    swapfile="$1"

    if ! grep "$swapfile" /proc/swaps 1>/dev/null; then # no swap currently
        return 1
    fi

    return 0
}

#
# Returns RAM total or a percentage of it
#
_mem_total() {
    local t
    t=false

    _load_user_conf

    # Parse Arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --total|-t)
                t=true
                shift 1
                ;;
            [0-9].[0-9])
                num=$1
                shift
                ;;
        esac
    done

    if "${t}"; then
        # returns total
        awk '/MemTotal/ {printf("%d\n", $2 / 1024)}' /proc/meminfo
    else
        # returns percentage
        awk -vn="$num" '/MemTotal/ {printf("%d\n", $2 / 1024 * n )}' /proc/meminfo
    fi
}

#
# Calculate swapfile size based on available RAM
#
_swap_size() {
    # Calculate swap file size when swapfile_size variable is not set
    _size="${swapfile_size:-$(_mem_total -t)}"

    for num in 1024 2096; do
        if [ -z "${swapfile_size}" ]; then
            # < 2GB set twice RAM total for swapfile
            if (( num >= 0 && _size <= num )); then
                _size=$((_size * 2))
                break
            fi

            # > 2GB, use same amount for swapfile
            if (( num >= 2096 && num <= _size )); then
                break
            fi
        fi
    done
}

#
# Creates a swap
# TODO enable multiple swapfiles/partitions
#
create_swap() {
    # Parse Arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --file|-f)
                file=${2}
                shift 2
                ;;
            --count|-c)
                count=${2}
                shift 2
                ;;
            -*|--*=) # unsupported flags
                echo "Error: Unsupported flag $1" >&2
                exit 1
                ;;
        esac
    done

    if ! check_swap "${file}"; then
        _print_message "Creating swapfile..."

        sudo dd if=/dev/zero of="${file}" bs=1M count="${count}" 2>/dev/null
        sudo chmod 600 "${file}"
        sudo mkswap -p 0 "${file}" 1>/dev/null
        sudo swapon "${file}"
    else
        _print_message "Swapfile already created..."
    fi

    # Include fstab value
    if ! grep "${file}" /etc/fstab 1>/dev/null; then
        _print_message "Creating swapfile entry in /etc/fstab"
        sudo bash -c "cat <<EOF >>/etc/fstab
${file} swap swap defaults,pri=0 0 0
EOF"
    fi
}

#
# Whirlpool Status Tool
#
_install_wst(){
    cd "$HOME" || exit

    git clone -q "$whirlpool_stats_repo" Whirlpool-Stats-Tool 2>/dev/null
    # Download whirlpool stat tool

    # Check for python-pip and install if not found
    _check_pkg "pipenv" "python-pipenv"

    cd Whirlpool-Stats-Tool || exit

    pip install setuptools &>/dev/null
    pipenv install -r requirements.txt &>/dev/null
    # Change to whirlpool stats directory, otherwise exit
    # install whirlpool stat tool
    # install WST
}

#
# Boltzmann Entropy Calculator
#
_install_boltzmann(){
    cd "$HOME" || exit

    git clone -q "$boltzmann_repo"

    cd boltzmann || exit
    # Pull Boltzmann

    _print_message "Checking package dependencies..."

    # Check for package dependency
    _check_pkg "pipenv" "python-pipenv"

    # Setup a virtual environment to hold boltzmann dependencies. We should use this
    # with all future packages that ship a requirements.txt.
    pip install setuptools &>/dev/null
    pipenv install -r requirements.txt  &>/dev/null
}

_is_bisq(){
    if [ -f "${ronin_data_dir}"/bisq.txt ]; then
        return 0
    else
        return 1
    fi
}

#
# Install Bisq Support
#
_bisq_install(){
    _print_message "Enabling Bisq support..."
    . "${HOME}"/RoninDojo/Scripts/defaults.sh

    _create_dir "${ronin_data_dir}"

    sed -i \
      -e "s/BITCOIND_BLOOM_FILTERS=off$/BITCOIND_BLOOM_FILTERS=on/"\
      "${dojo_path_my_dojo}/conf/docker-bitcoind.conf"

    touch "${ronin_data_dir}"/bisq.txt

    return 0
}

#
# Uninstall Bisq Support
#
_bisq_uninstall() {
    _print_message "Disabling Bisq Support..."

    sed -i \
      -e "s/BITCOIND_BLOOM_FILTERS=on$/BITCOIND_BLOOM_FILTERS=off/"\
      "${dojo_path_my_dojo}/conf/docker-bitcoind.conf"

    rm "${ronin_data_dir}"/bisq.txt

    return 0
}

#
# Indexer data restore
#
_dojo_data_indexer_restore() {
    _load_user_conf

    if sudo test -d "${dojo_backup_electrs}"/_data && sudo test -d "${docker_volume_electrs}"/_data; then
        _print_message "Electrs data restore starting..."

        sudo rm -rf "${docker_volume_electrs}"/_data
        sudo mv "${dojo_backup_electrs}"/_data "${docker_volume_electrs}"/
        sudo rm -rf "${dojo_backup_electrs}"

        _print_message "Electrs data restore completed..."

    elif sudo test -d "${dojo_backup_indexer}"/_data && sudo test -d "${docker_volume_indexer}"/_data; then
        _print_message "Addrindexrs data restore starting..."

        sudo rm -rf "${docker_volume_indexer}"/_data
        sudo mv "${dojo_backup_indexer}"/_data "${docker_volume_indexer}"/
        sudo rm -rf "${dojo_backup_indexer}"

        _print_message "Addrindexrs data restore completed..."

    elif sudo test -d "${dojo_backup_fulcrum}"/_data && sudo test -d "${docker_volume_fulcrum}"/_data; then
        _print_message "Fulcrum data restore starting..."

        sudo rm -rf "${docker_volume_fulcrum}"/_data
        sudo mv "${dojo_backup_fulcrum}"/_data "${docker_volume_fulcrum}"/
        sudo rm -rf "${dojo_backup_fulcrum}"

        _print_message "Fulcrum data restore completed..."

    fi
}

#
# Indexer data backup
#
_dojo_data_indexer_backup() {
    _load_user_conf

    # determine which indexer is in use and backup accordingly
    if sudo test -d "${docker_volume_electrs}"; then
        test ! -d "${dojo_backup_electrs}" && sudo mkdir "${dojo_backup_electrs}"
        sudo mv "${docker_volume_electrs}"/_data "${dojo_backup_electrs}"/
    elif sudo test -d "${docker_volume_indexer}"; then
        test ! -d "${dojo_backup_indexer}" && sudo mkdir "${dojo_backup_indexer}"
        sudo mv "${docker_volume_indexer}"/_data "${dojo_backup_indexer}"/
    elif sudo test -d "${docker_volume_fulcrum}"; then
        test ! -d "${dojo_backup_fulcrum}" && sudo mkdir "${dojo_backup_fulcrum}"
        sudo mv "${docker_volume_electrs}"/_data "${dojo_backup_fulcrum}"/
    fi
}

#
# Bitcoin IBD restore
#
_dojo_data_bitcoind_restore() {
    _load_user_conf

    if sudo test -d "${dojo_backup_bitcoind}/blocks" && sudo test -d "${docker_volume_bitcoind}"; then
        _print_message "Blockchain data restore starting..."

        for dir in blocks chainstate indexes; do
            if sudo test -d "${docker_volume_bitcoind}"/_data/"${dir}"; then
                sudo rm -rf "${docker_volume_bitcoind}"/_data/"${dir}"
            fi
        done

        for dir in blocks chainstate indexes; do
            if sudo test -d "${dojo_backup_bitcoind}"/"${dir}"; then
                sudo mv "${dojo_backup_bitcoind}"/"${dir}" "${docker_volume_bitcoind}"/_data/
            fi
        done

        _print_message "Blockchain data restore completed..."
        sudo rm -rf "${dojo_backup_bitcoind}"
    fi
}

#
# Bitcoin IBD backup
#
_dojo_data_bitcoind_backup() {
    _load_user_conf

    test ! -d "${dojo_backup_bitcoind}" && sudo mkdir "${dojo_backup_bitcoind}"

    for dir in blocks chainstate indexes; do
        if sudo test -d "${docker_volume_bitcoind}"/_data/"${dir}"; then
            sudo mv "${docker_volume_bitcoind}"/_data/"${dir}" "${dojo_backup_bitcoind}"/
        fi
    done
}

#
# Tor credentials backup
#
_tor_backup() {
    test -d "${dojo_backup_tor}" || sudo mkdir -p "${dojo_backup_tor}"

    if sudo test -d "${install_dir}/${tor_data_dir}"/_data/hsv3dojo; then
        sudo rsync -ac --delete-before --quiet "${install_dir}/${tor_data_dir}"/_data/ "${dojo_backup_tor}"
    fi
}

#
# Tor credentials restore
#
_tor_restore() {
    if sudo test -d "${dojo_backup_tor}"/hsv3dojo; then
        _print_message "Tor data restore starting..."

        sudo bash -c "rm -rf ${install_dir}/${tor_data_dir}/_data/*"
        sudo bash -c "mv -v ${dojo_backup_tor}/* ${install_dir}/${tor_data_dir}/_data"

        _print_message "Tor data restore completed..."
        sudo rm -rf "${dojo_backup_tor}"
    fi
}

#
# Yes or No Prompt
#
_yes_or_no() {
    while true; do
        read -rp "$* ${green}[y/n]:${nc} " yn
        case $yn in
            [Yy]*) return 0;;
            [Nn]*) return 1;;
        esac
    done
}

#
# SSH Key Management
#
_ssh_key_authentication() {
    local _add_ssh_key=false _del_ssh_key=false _pub_ssh_key_path=/tmp/pub-ssh-key

    # Parse Arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            add-ssh-key)
                _add_ssh_key=true
                break
                ;;
            del-ssh-key)
                _del_ssh_key=true
                break
                ;;
            enable)
                if sudo grep -q "UsePAM no" /etc/ssh/sshd_config; then
                    printf "%s\n***\nSSH Key Authentication already enabled! Returning to menu...\n***%s\n" "${red}" "${nc}"

                    return 1
                else
                    printf "%s\n***\nThis will enable SSH key authentication ONLY and will disable password authentication...\n***%s\n\n" "${red}" "${nc}"

                    if _yes_or_no "Do you wish to continue?"; then
                        printf "%s\n***\nGenerating sshd configuration file...\n***%s\n" "${red}" "${nc}"

                        # Backup original sshd_config
                        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config_original

                        sudo bash -c "cat <<EOF >/etc/ssh/sshd_config
PasswordAuthentication no
PermitEmptyPasswords no
UsePAM no
AllowUsers $USER
EOF
"
                        printf "%s\n***\nRestarting SSH daemon...\n***%s\n\n" "${red}" "${nc}"
                        sudo systemctl restart --quiet sshd
                    else
                        return 1
                    fi

                    return 0
                fi
                ;;
            disable)
                if sudo grep -q "UsePAM no" /etc/ssh/sshd_config; then
                    printf "%s\n***\nRestoring sshd_config to defaults...\n***%s\n" "${red}" "${nc}"
                    sudo cp /etc/ssh/sshd_config_original /etc/ssh/sshd_config

                    printf "%s\n***\nDeleting $HOME/.ssh directory containing keys...\n***%s\n" "${red}" "${nc}"
                    rm -rf "$HOME"/.ssh || exit

                    # Restart sshd
                    sudo systemctl restart --quiet sshd

                    return 0
                else
                    printf "%s\n***\nSSH Key Authentication not enabled! Returning to menu...\n***%s\n" "${red}" "${nc}"
                    return 1
                fi
                ;;
        esac
    done

    read -rp "${red}Paste a valid SSH public key: ${nc}" _pub_ssh_key

    # Create a temporaly file with pasta contents
    echo "${_pub_ssh_key}">"${_pub_ssh_key_path}"

    # Verify key
    if ssh-keygen -lf "${_pub_ssh_key_path}" 1>/dev/null; then
        test -d "$HOME"/.ssh || mkdir "$HOME"/.ssh

        # Adding to authorized_keys & removing temporaly file
        if [ -f "$HOME"/.ssh/authorized_keys ]; then
            if grep -q "${_pub_ssh_key}" "$HOME"/.ssh/authorized_keys; then
                if ${_add_ssh_key}; then
                    # Key already found
                    printf "%s\n***\nSSH public key already found. Returning to menu...\n***%s\n" "${red}" "${nc}"
                    return 1
                elif ${_del_ssh_key}; then
                    # Delete key
                    sed -i "/${_pub_ssh_key}/d" "$HOME"/.ssh/authorized_keys
                    return 0
                fi
            else
                # Adding new key
                echo "${_pub_ssh_key}" >>"$HOME"/.ssh/authorized_keys

                # Shred temporaly key
                shred -uzfs 42 "${_pub_ssh_key_path}"

                # Unset variable
                unset _pub_ssh_key_path

                return 0
            fi
        else
            if ${_del_ssh_key}; then
                # No key found to delete
                return 1
            elif ${_add_ssh_key}; then
                # Adding new key
                echo "${_pub_ssh_key}" >>"$HOME"/.ssh/authorized_keys

                # Shred temporaly key
                shred -uzfs 42 "${_pub_ssh_key_path}"

                # Unset variable
                unset _pub_ssh_key_path

                return 0
            fi
        fi
    else
        printf "%s\n***\nInvalid SSH public key!\n***\n\n***Example SSH public key below...\n***%s\n" "${red}" "${nc}"

        printf "\nssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuh9yEnlKJT1A/MijVQm2fFxoxlX3Bb1JXSUMwOX9E/ likewhoa@localhost\n"

        printf "%s\n***\nReturning to menu...\n***%s\n" "${red}" "${nc}"

        return 1
    fi
}

#
# returns true/false on whether the host has a gpio system
#
_is_gpio_sytem() {
    if [ -d /sys/class/gpio ]; then
        return 0;
    else
        return 1;
    fi
}

#
# deletes and repopulates the GPIO dir
#
_prepare_GPIO_datadir() {
    _load_user_conf

    _remove_GPIO_datadir

    git clone https://github.com/Angoosh/RockPro64-RP64.GPIO.git "${ronin_gpio_data_dir}"
    cp "${ronin_gpio_dir}/turn.LED.off.py" "${ronin_gpio_data_dir}"
    cp "${ronin_gpio_dir}/turn.LED.on.py" "${ronin_gpio_data_dir}"
}

#
# installs the gpio service file for systemd
#
_install_gpio_service() {
    _load_user_conf

    _uninstall_gpio_service

    sudo bash -c "cat <<EOF > /etc/systemd/system/ronin.gpio.service
[Unit]
Description=GPIO
After=multi-user.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/python ${ronin_gpio_data_dir}/turn.LED.on.py
ExecStop=/bin/python ${ronin_gpio_data_dir}/turn.LED.off.py
WorkingDirectory=${ronin_gpio_data_dir}
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF
"

    sudo systemctl daemon-reload
    sudo systemctl enable --now --quiet ronin.gpio
}

#
# installs the whole gpio setup
#
_install_gpio() {

    _is_gpio_sytem

    if [ $? = 1 ]; then
        return 0
    fi

    _prepare_GPIO_datadir
    _install_gpio_service
}

_remove_GPIO_datadir() {
    _load_user_conf

    if [ -d "${ronin_gpio_data_dir}" ]; then
        sudo rm -rf "${ronin_gpio_data_dir}"
    fi
}

#
# uninstalls the gpio service file for systemd
#
_uninstall_gpio_service() {

    if [ ! -f /etc/systemd/system/ronin.gpio.service ] && ! sudo systemctl is-active ronin.gpio; then
        return 0
    fi

    sudo systemctl stop ronin.gpio
    sudo rm -f /etc/systemd/system/ronin.gpio.service
    sudo systemctl daemon-reload
}

#
# uninstalls the whole gpio setup
#
_uninstall_gpio() {
    _remove_GPIO_datadir
    _uninstall_gpio_service
}

#
# Set storage config in ronin's data folder.
# Current pitfalls:
# - having installed with sda1 as install_dir and then adding an nvme
# - having installed with nvme0n1p1 as install_dir and then adding multiple sd, the supposed backup device not being sda
# - having installed with sda1 as install_dir and then adding multiple sd, the supposed backup device not being sdb
#
_setup_storage_config() {

    local blockdata_storage_partition backup_storage_partition

    if test -b /dev/nvme0n1; then
        blockdata_storage_partition="/dev/nvme0n1p1"
        if test -b /dev/sda; then
            backup_storage_partition="/dev/sda1"
        fi
    elif test -b /dev/sda; then
        blockdata_storage_partition="/dev/sda1"
        if test -b /dev/sdb; then
            backup_storage_partition="/dev/sdb1"
        fi
    else
        return 1
    fi

    rm -f "${ronin_data_dir}"/blockdata_storage_partition
    echo "blockdata_storage_partition=${blockdata_storage_partition}" > "${ronin_data_dir}"/blockdata_storage_partition
    chmod +x "${ronin_data_dir}"/blockdata_storage_partition

    rm -f "${ronin_data_dir}"/backup_storage_partition
    if [ -n "$backup_storage_partition" ]; then
        echo "backup_storage_partition=${backup_storage_partition}" > "${ronin_data_dir}"/backup_storage_partition
        chmod +x "${ronin_data_dir}"/backup_storage_partition
    fi
}

#
# Creating Dojo Config files \
# Usage: Copy the template files to conf files. \
# WARNING: These will have default values until _generate_dojo_credentials is ran.
#
_create_dojo_confs() {
    for file in ${dojo_path_my_dojo}/conf/*.conf.tpl; do
        cp "${file}" "${file:0:-4}"
    done
}

#
# Dojo Credentials Generation \
# Usage: Generates random usernames and passwords for dojo conf
#
_generate_dojo_credentials(){
    _load_user_conf
    . "${HOME}"/RoninDojo/Scripts/generated-credentials.sh

    sed -i -e "s/BITCOIND_RPC_USER=.*$/BITCOIND_RPC_USER=${BITCOIND_RPC_USER}/" \
    -e "s/BITCOIND_RPC_PASSWORD=.*$/BITCOIND_RPC_PASSWORD=${BITCOIND_RPC_PASSWORD}/" \
    "${dojo_path_my_dojo}"/conf/docker-bitcoind.conf

    sed -i -e "s/NODE_API_KEY=.*$/NODE_API_KEY=${NODE_API_KEY}/" \
    -e "s/NODE_ADMIN_KEY=.*$/NODE_ADMIN_KEY=${NODE_ADMIN_KEY}/" \
    -e "s/NODE_JWT_SECRET=.*$/NODE_JWT_SECRET=${NODE_JWT_SECRET}/" \
    "${dojo_path_my_dojo}"/conf/docker-node.conf

    sed -i -e "s/MYSQL_ROOT_PASSWORD=.*$/MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}/" \
    -e "s/MYSQL_USER=.*$/MYSQL_USER=${MYSQL_USER}/" \
    -e "s/MYSQL_PASSWORD=.*$/MYSQL_PASSWORD=${MYSQL_PASSWORD}/" \
    "${dojo_path_my_dojo}"/conf/docker-mysql.conf

    sed -i -e "s/EXPLORER_INSTALL=.*$/EXPLORER_INSTALL=on/" \
    -e "s/EXPLORER_KEY=.*$/EXPLORER_KEY=${EXPLORER_KEY}/" \
    "${dojo_path_my_dojo}"/conf/docker-explorer.conf

    sed -i -e 's/MEMPOOL_INSTALL=.*$/MEMPOOL_INSTALL=off/' \
    -e "s/MEMPOOL_MYSQL_USER=.*$/MEMPOOL_MYSQL_USER=${MEMPOOL_MYSQL_USER}/" \
    -e "s/MEMPOOL_MYSQL_PASS=.*$/MEMPOOL_MYSQL_PASS=${MEMPOOL_MYSQL_PASS}/" \
    -e "s/MEMPOOL_MYSQL_ROOT_PASSWORD=.*$/MEMPOOL_MYSQL_ROOT_PASSWORD=${MEMPOOL_MYSQL_ROOT_PASSWORD}/" \
    "${dojo_path_my_dojo}"/conf/docker-mempool.conf
}

#
# Backup Dojo confs \
# Usage: Copys users dojo confs to SSD for easy restore if necessary
#
_backup_dojo_confs() {
    if [ ! -d ${dojo_backup_dir} ]; then
        sudo mkdir -p ${dojo_backup_dir}
    fi
    if [ ! -w "${dojo_backup_dir}" ]; then
        sudo chown -R "$USER":"$USER" "${dojo_backup_dir}"
    fi
    _create_dir "${dojo_backup_conf}"
    sudo rsync -acp --quiet --delete-before "${dojo_path_my_dojo}"/conf/*.conf "${dojo_backup_conf}"
}

#
# Dojo Conf function \
# Usage: restores/creates and backs up users dojo confs to SSD
#
_restore_or_create_dojo_confs() {
    if [ -d "${dojo_backup_conf}" ] && ! grep "BITCOIND_RPC_USER=dojorpc" "${dojo_backup_conf}"/docker-bitcoind.conf 1>/dev/null; then
        _print_message "Credentials backup detected and restored..."
        sudo chown -R "$USER":"$USER" "${dojo_backup_dir}"
        sudo rsync -acp --quiet --delete-before "${dojo_backup_conf}"/*.conf "${dojo_path_my_dojo}"/conf/

        update_all_config_files

    else
        _print_message "No unique backup credentials detected. Setting newly generated credentials..."
        _create_dojo_confs
        _generate_dojo_credentials
        if "${is_active_dojo_conf_backup}"; then
            _print_message "Backing up newly created credentials..."
            _backup_dojo_confs
        fi
    fi
}

#
# Installs Network Check Service File
# Usage: Creates a service file that will execute the network-check.sh and verify the system is still connected to the same network
# Note: do not edit without taking _update_32 into account.
#
_install_network_check_service() {
    _load_user_conf

    sudo tee "/etc/systemd/system/ronin.network.service" <<EOF >/dev/null
[Unit]
Description=Network Check
After=multi-user.target
After=network.target
Requires=network.target

[Service]
User=root
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash ${ronin_scripts_dir}/network-check.sh ${ronin_data_dir} ${USER}
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now --quiet ronin.network
}

#
# Removes Network Check Service File
#
_uninstall_network_check_service() {
    sudo systemctl disable ronin.network
    sudo systemctl stop ronin.network
    sudo rm -f "/etc/systemd/system/ronin.network.service"
    sudo systemctl daemon-reload
}


#
# Update a configuration file from template
# Function name and body copied from SamouraiWallet's dojo repo, file /docker/my-dojo/install/upgrade-script.sh
#
update_config_file() {
  if [ -f $1 ]; then
    sed "s/^#.*//g;s/=.*//g;/^$/d" $1 > ./original.keys.raw
    grep -f ./original.keys.raw $1 > ./original.lines.raw

    cp -p $1 "$1.save"
    cp -p $2 $1

    while IFS='=' read -r key val ; do
      if [[ $OSTYPE == darwin* ]]; then
        sed -i "" "s~$key=.*~$key=$val~g" "$1"
      else
        sed -i "s~$key=.*~$key=$val~g" "$1"
      fi
    done < ./original.lines.raw

    rm ./original.keys.raw
    rm ./original.lines.raw
  else
    cp $2 $1
  fi
}

update_all_config_files() {
    update_config_file "${dojo_path_my_dojo}/conf/docker-common.conf" "${dojo_path_my_dojo}/conf/docker-common.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-bitcoind.conf" "${dojo_path_my_dojo}/conf/docker-bitcoind.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-mysql.conf" "${dojo_path_my_dojo}/conf/docker-mysql.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-node.conf" "${dojo_path_my_dojo}/conf/docker-node.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-explorer.conf" "${dojo_path_my_dojo}/conf/docker-explorer.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-tor.conf" "${dojo_path_my_dojo}/conf/docker-tor.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-indexer.conf" "${dojo_path_my_dojo}/conf/docker-indexer.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-whirlpool.conf" "${dojo_path_my_dojo}/conf/docker-whirlpool.conf.tpl"
    update_config_file "${dojo_path_my_dojo}/conf/docker-mempool.conf" "${dojo_path_my_dojo}/conf/docker-mempool.conf.tpl"
}
