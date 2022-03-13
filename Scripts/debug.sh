#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "${HOME}"/RoninDojo/Scripts/defaults.sh
. "${HOME}"/RoninDojo/Scripts/dojo-defaults.sh
. "${HOME}"/RoninDojo/Scripts/functions.sh

# Check for package dependencies
_install_pkg_if_missing --update-mirrors sysstat bc gnu-netcat 

# Import team pgp keys
if gpg --list-keys | grep -e 'btcxzelko\|s2l1\|Pavel\|likewhoa' &>/dev/null ; then
gpg --refresh-keys &>/dev/null
else 
gpg --import "${HOME}"/RoninDojo/Keys/pgp.txt &>/dev/null && gpg --refresh-keys &>/dev/null
fi

print_cpu_load() {

	cat <<EOF
#####################################################################
CPU Avg Load:      <1 Normal,  >1 Caution,  >2 Unhealthy 
#####################################################################
EOF

	# Get cpu load values and display to user
	cpus=$(lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}')
	i=0

	while [ $i -lt $cpus ] ; do
		echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($3 == var ) print $4 }' `"
		let i=$i+1
	done

    cat <<EOF
Load Average : $(uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,)
Heath Status : $(uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}')
EOF

}

print_general_info() {

	# Get general system info
	os_descrip=$(grep DESCRIPTION /etc/lsb-release | sed 's/DISTRIB_DESCRIPTION=//g')
	os_version=$(grep RELEASE /etc/lsb-release | sed 's/DISTRIB_RELEASE=//g')
	kernel_version=$(uname -r)
	system_uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
	backend_status=$(if cd "${ronin_ui_backend_dir}" && pm2 status | grep "online" &>/dev/null ; then printf "Online" ; else printf "Offline" ; fi)
	tor_status=$(if systemctl is-active --quiet tor ; then printf "Online" ; else printf "Offline" ; fi)
	docker_version=$(docker --version; docker-compose --version)
	docker_status=$(if systemctl is-active --quiet docker ; then printf "Online" ; else printf "Offline" ; fi)
	cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
	tempC=$((cpu/1000))
	temp_output=$(echo $tempC $'\xc2\xb0'C)

	cat <<EOF
#####################################################################
                     General System Information
#####################################################################
OS Description   :  $os_descrip
OS Version       :  $os_version
Kernel Version   :  $kernel_version
CPU Temperature  :  $temp_output
Uptime           :  $system_uptime
UI Backend       :  $backend_status
External Tor     :  $tor_status
Docker version   :  $docker_version
Docker           :  $docker_status
EOF

}

print_memory_usage() {

	# Get Total Memory, Used Memory, Free Memory, Used Swap and Free Swap values
	# All variables like this are used to store values as float 
	# Using bc to do all math operations, without bc all values will be integers 
	# Also we use if to add zero before value if value less than 1024, and result of dividing will be less than 1
	total_mem=$(free -m | head -2 | tail -1| awk '{print $2}')
	total_bc=$(echo "scale=2;if("$total_mem"<1024 && "$total_mem" > 0) print 0;"$total_mem"/1024"| bc -l)
	used_mem=$(free -m | head -2 | tail -1| awk '{print $3}')
	used_bc=$(echo "scale=2;if("$used_mem"<1024 && "$used_mem" > 0) print 0;"$used_mem"/1024"|bc -l)
	free_mem=$(free -m | head -2 | tail -1| awk '{print $4}')
	free_bc=$(echo "scale=2;if("$free_mem"<1024 && "$free_mem" > 0) print 0;"$free_mem"/1024"|bc -l)
	total_swap=$(free -m | tail -1| awk '{print $2}')
	total_sbc=$(echo "scale=2;if("$total_swap"<1024 && "$total_swap" > 0) print 0;"$total_swap"/1024"| bc -l)
	used_swap=$(free -m | tail -1| awk '{print $3}')
	used_sbc=$(echo "scale=2;if("$used_swap"<1024 && "$used_swap" > 0) print 0;"$used_swap"/1024"|bc -l)
	free_swap=$(free -m |  tail -1| awk '{print $4}')
	free_sbc=$(echo "scale=2;if("$free_swap"<1024 && "$free_swap" > 0) print 0;"$free_swap"/1024"|bc -l)

	cat <<EOF
#####################################################################
                         Memory Usage
#####################################################################
EOF

	# Need to fix output not displaying properly
	#echo -e "
	#=> Physical Memory
	#Total\tUsed\tFree\t%Free
	# as we get values in GB, also we get % of usage dividing Free by Total
	#${total_bc}GB\t${used_bc}GB \t${free_bc}GB\t$(($free_mem * 100 / $total_mem ))%

	#=> Swap Memory
	#Total\tUsed\tFree\t%Free
	#Same as above – values in GB, and in same way we get % of usage
	#${total_sbc}GB\t${used_sbc}GB\t${free_sbc}GB\t$(($free_swap * 100 / $total_swap ))%
	#"

	# List of processes that are using most RAM
	printf "=> Top memory using processes\n"
	printf "PID     %%MEM    RSS     COMMAND\n"
	ps aux | awk '{print $2,"\t"$4,"\t"$6,"\t"$11}' | sort -k3rn | head -n 10

}

print_disk_load() {

	cat <<EOF
#####################################################################
Disk Usage:      Normal <90%, Caution >90%, Unhealthy >95%
#####################################################################
EOF

	# Display drive info
	df -Pkh | grep -v 'Filesystem' > /tmp/df.status
	while read disk ; do
		line=$(echo $disk | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," freespace"}')
		echo -e $line 
	done < /tmp/df.status

}

print_disk_health() {

cat <<EOF
#####################################################################
                        Disk Heath Status
#####################################################################
EOF

	# Check if SSD storage device is found
	if [ -b "${primary_storage}" ] && [ -b "${secondary_storage}" ] ; then
	    cat <<EOF
***
Primary storage and secondary storage /dev/sda1 & /dev/sdb1 found...
***

***
Please unmount and unplug your secondary storage device when not in use!
***
EOF
	elif [ -b "${primary_storage}" ] ; then
	    cat <<EOF
***
Primary storage /dev/sda1 found!
***
EOF
	else
	    cat <<EOF
***
ERROR: Primary storage /dev/sda1 is NOT FOUND, check dmesg below for I/O errors!
***
EOF
	fi

	printf "\n"

	while read disk ; do
		usage=$(echo "$disk" | awk '{print $5}' | cut -f1 -d%)
		if [ "$usage" -ge 95 ] 
		then
			status='Unhealthy'
		elif [ "$usage" -ge 90 ]
		then
			status='Caution'
		else
			status='Normal'
		fi
	        line=$(echo "$disk" | awk '{print $1,"\t",$6}')
	        echo -ne "$line" "\t\t" "$status"
	        printf "\n"
	done < /tmp/df.status
	rm /tmp/df.status

	printf "\n"

	# Show dmesg error logs if found when piped into grep search 
	if dmesg | grep "error" ; then
	    cat <<EOF
***
WARNING - Dmesg Error Logs Detected:
***
EOF
	dmesg | grep "error"
	fi

}

print_docker_status() {

	cat <<EOF
#####################################################################
                      Docker Container Status
#####################################################################
EOF

	docker ps

	printf "\n"

	# checks if dojo is running (check the db container)
	if ! _dojo_check; then
	    break
	else
	    cat <<EOF
#####################################################################
                          Bitcoind Logs
#####################################################################
EOF

	    cd "$dojo_path_my_dojo" || exit
	    ./dojo.sh logs bitcoind -n 25
	fi

	printf "\n"

	if ! _dojo_check; then
	    break
	else
	    cat <<EOF
#####################################################################
                          Tor Logs
#####################################################################
EOF
    
	    cd "$dojo_path_my_dojo" || exit
	    ./dojo.sh logs tor -n 25
	fi

	printf "\n"

	if ! _dojo_check; then
	    break
	else
	    cat <<EOF
#####################################################################
                          MariaDB Logs
#####################################################################
EOF
    
	    cd "$dojo_path_my_dojo" || exit
	    ./dojo.sh logs db -n 25
	fi

	printf "\n"

	if ! _dojo_check; then
	    break
	else
	    cat <<EOF
#####################################################################
                          Indexer Logs
#####################################################################
EOF

	    cd "$dojo_path_my_dojo" || exit
	    ./dojo.sh logs indexer -n 25
	fi

}

upload_logs() {

	# Upload full copy of pgp encrypted dmesg logs to termbin.com
	# Link to termbin github repository: https://github.com/solusipse/fiche.
	# Life span of single paste is one month. Older pastes are deleted.
	cat <<EOF
#####################################################################
                    PGP Encrypted Dmesg Logs
#####################################################################
EOF

	    cat <<EOF
***
PGP Encrypted Dmesg Logs URL:
***
EOF
	_create_dir "${ronin_debug_dir}"
	dmesg > "${ronin_debug_dir}"/dmesg.txt
	gpg -e -r btcxzelko@protonmail.com -r s2l1@pm.me -r likewhoa@weboperative.com -r pajaseviwow@gmail.com \
	  --trust-model always -a "${ronin_debug_dir}"/dmesg.txt
	cat "${ronin_debug_dir}"/dmesg.txt.asc | nc termbin.com 9999
	rm -f "${ronin_debug_dir}"/dmesg*

}

ronindebug() {
	print_cpu_load
	printf "\n"
	print_general_info
	printf "\n"
	print_memory_usage
	printf "\n"
	print_disk_load
	printf "\n"
	print_disk_health
	printf "\n"
	print_docker_status
	printf "\n"
	upload_logs
	printf "\n"
}

    # Upload to termbin
    cat <<EOF
${red}
***
Please wait while URL is generated...
***
${nc}
EOF
_sleep 2

    cat <<EOF
${red}
***
Debugging URL:
***
${nc}
EOF
filename="health-`date +%y%m%d`-`date +%H%M`.txt"
_create_dir "${ronin_debug_dir}"
ronindebug  > "${ronin_debug_dir}/${filename}"
cat "${ronin_debug_dir}"/${filename} | nc termbin.com 9999

    # Ask user to proceed
    cat <<EOF
${red}
***
Do you want to see the debugging script output?
***
${nc}
EOF
while true; do
    read -rp "[${green}Yes${nc}/${red}No${nc}]: " answer
    case $answer in
        [yY][eE][sS]|[yY])
          # Display ronindebug function output to user
          printf "\n"
          cat "${ronin_debug_dir}"/${filename}
          break
          ;;
        [nN][oO]|[Nn])
          exit
          ;;
        *)
          cat <<EOF
${red}
***
Invalid answer! Enter Y or N
***
${nc}
EOF
          ;;
    esac
done


_pause return

exit
