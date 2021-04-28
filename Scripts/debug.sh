#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "${HOME}"/RoninDojo/Scripts/defaults.sh
. "${HOME}"/RoninDojo/Scripts/dojo-defaults.sh
. "${HOME}"/RoninDojo/Scripts/functions.sh

# Check for package dependencies
for pkg in sysstat bc gnu-netcat; do
    _check_pkg "${pkg}"
done

cat << EOF > "${HOME}"/pgp.txt
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBF7JSOsBCACfFrpQ3nuw2U2sJm1sXckEhK3JFx8ihWevw6PApMFw57H1JfL8
X5RcN8rtwjcpTvsHLzYi3/YF8x03ZC8jJIqIvT78XbVwDr/RnbXNf3IQDMBkpEni
5o8xoxE/0tVhhzb8ggdiJfYX5YKgtsw2EDalb4ZmTA7/x1/a6/PKpO+N7I9ZGnVq
htKgv9SWviU+XBFqmrzGCwYtRovN6VXU6YOUgUad2wdPatBYuK5Tv1gvlO5W/Z+Y
TUrHsKuPWj0GpN08j1BOO5n+/vEmDGA51Q8dbWhQ8iwvlaAM5qaX43df91MuFRRO
WN/O1VQNgT8Q8sWrUrpmSlZIqGhJyvLXc+kLABEBAAG0JEJUQ3haZWxrbyA8YnRj
eHplbGtvQHByb3Rvbm1haWwuY29tPokBVAQTAQgAPhYhBHgF+YeaXUA08rLS+ZgY
83nB5LJfBQJeyUjrAhsDBQkDwmcABQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJ
EJgY83nB5LJfYJcIAIjzLkNoM5HyWtHn6zgGNBGcvgNS+J1ZdUeTUITidZnw5dzv
eRU1v3bMk/LZnfeEdBCGWRkKuJ6yOuTNiOP0Z5kUWdRMBLDtBbg98y+7EoyKB+Ip
Fqp8S38oaQK3zprMzv7AQPgATIyfZ4porTji/znaFwOwIbsDglG9RAUhaEtb4hY9
4d7dJCSK8TNn30EVJzOjZIGOpEik9WqzkgAsqmLuDKr+haY158X2Ha+WIoe99Ggi
X2DqirGK599LAIcDjvmCsjiIQNIu1eP79R9mFa+thlGngy+zwle3MtKN/XEVIOM6
865bIqACsOpdqmhc3P+LldllaVX/Twf8q8jHIl25AQ0EXslI6wEIAM3O5nx2U5db
D3Q6RbM9bIzgBp1ZUvBiyhW3PviryxnU6NwrtkmgrjoAPT34ykMTOWO1B7ha1Y9A
UMkeifpohfuBKSlTEIS0/CPOb+ClKC8erJq3pwPZzMBPyY8xN35oIhCtJH1sxWDB
bheXqJYRpiuq/RSg/YnxA9KKVN53rOgkxju87t7K85lkWpPKLvlu7bst09CEcP3A
znolREjontW0RQrEVqitMX1hXLD9jf9EYvb+/zZbql4klHTgp/vbobIRmEiqolJU
3h1SZWGpmcwHnmyvVKnzCRriiD3mkCYL6eNBfssw2+raSpI23lXXobS0liookhxk
NlrFiUX4Z4UAEQEAAYkBPAQYAQgAJhYhBHgF+YeaXUA08rLS+ZgY83nB5LJfBQJe
yUjrAhsMBQkDwmcAAAoJEJgY83nB5LJfCk4H/j9xlv5MsLjV8qHNKZGs0OvVsbXa
M0W/Zi3wMMs2zccKLkPyqm9RuCh4WwtKO4lDNLdMLYMipL7mgRVWLA5BwSUsUxZB
g/bwX0+miRVcFpOGWqdF7sFj0OIczOYO/W7x47I/xuDdpbEDgqV0XnGHNCWBFtPK
imtjCdTWyiIrL2pNfUyrgVOU0sk+2uAPSjHKgUSzXlfO3KKY5uIKg9ML2v7G2rfj
bAc5hSmzEgDIY+ynq0enC8ykcynKSDsITvQuaDfKpXFSnuW4UUoZTKJuElBO6mne
QzczrwV7MM/b7/fIRrDVXnqZJ9BebfjaVoX8kNGvZPf3CNuI7gk7gHw5+PY=
=0VxA
-----END PGP PUBLIC KEY BLOCK-----

-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=LWMY
-----END PGP PUBLIC KEY BLOCK-----

-----BEGIN PGP PUBLIC KEY BLOCK-----

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
6raj
=R8LV
-----END PGP PUBLIC KEY BLOCK-----

-----BEGIN PGP PUBLIC KEY BLOCK-----

mQENBF7jkHABCADLyRaMQ2zNlwO5J2kjIf9e4PgjE7zUAlpqMuzlWd3r1aDcC9fx
I294Ic0Q/t77e8cd+D48ikkZOl01RQrOK/ueB9GV9Zebdlgsggh9kunynV33BdPO
l5QL9+teNmJ/Aa427hF3aPOaFV4GF7zZSZmi/oig7msPo937MvCybPR52koEf7R9
RYZ2o3IaIllrMYW2gfYcCjDlca6YeFE2cK69+EFYNV+R33ZvWNHelV6NJNRQ/Qjt
oUq4oSia4/71KNSXuJzHnJ5Zai5YkKy/TE5xSmK+FooBtOAL+n2AaOt+NWImyGHy
gcM21b7kLeQ25nfBeG0MhVQNBcfoGp2vWAEDABEBAAG0JGxpa2V3aG9hIDxsaWtl
d2hvYUB3ZWJvcGVyYXRpdmUuY29tPokBVAQTAQgAPhYhBBhX4CyHtvu8nLQ4B0/P
Mu/zXKXVBQJe45BwAhsDBQkDwmcABQsJCAcCBhUKCQgLAgQWAgMBAh4BAheAAAoJ
EE/PMu/zXKXVVlYH/iaCz7N9eiXpsk9AQW0KDhas6RsdvAcJkl8zn7HZ5DR4cQ22
VgudeeMTU8EOh5tMzBL71Ej0SyA18IWwOXMyIgxHWH3zn3t2JcVUxF56OyAhjvVU
2ZCe0FwWht2JU6O+N/BvhLl+HHo31RDE3upHhmOnesxN6TIybNhvYPFXjfh69fWw
Ffz/AtaoaDyGWiVYcloEj41FEBUYZCm5I4Yfp6bL3FzwKziyVppKOOPabwYtgiet
9bb7Pnck0z4rYPOqC8f+zRkk69moTp2iJH+N/UbFq302AAchunz+cFD1Whay0ehT
PIgMKqDP304ChN7It9VvNJXdCBaYA1od6Iil38W5AQ0EXuOQcAEIAMJywOONHlTe
URD/wXAeVLwUABh7Pa7ULJ8U+WbLk0NmXVYM+PEMFgr+gltg58NIM7msvQAkyCyc
vRvyAa2vx+DL93gpyfsDYaW54f9N33bAEErA7Z/3kE1xTtMj0XxmaELoMr03ghGB
enak++vnp+mmgqEOj1Em9fcSvwrEdu0Hcd7qAcVZfu00/vmwRJ8S6ENF8CS2cqMF
DIXGsFKOKME0BPaEg9ZQjy+hAcCoWemJ1M+YXBM/sF3QDb7yJiRQIzfeTNdH2MyF
/yEvUx/mTtk8FQvJozPYosqUzqvqViY80mUMF44vodN2u7wClGu/60aoxnEBCSoa
/oYjurs0CNUAEQEAAYkBPAQYAQgAJhYhBBhX4CyHtvu8nLQ4B0/PMu/zXKXVBQJe
45BwAhsMBQkDwmcAAAoJEE/PMu/zXKXV7jYH/220D5lley3dkSFJ4wPQLPBiGc1z
uC3I+3n0YhXCNgEkZY4AjgX4XxtX/bDhYC/tYIqDkDa1HkhOYbXNwXFJmDdgJhkp
exaFLN0rdmvS35bp7xa4f09eWkvzxYyibvb7tbasGN2M/OU6lw491l1u3ymr9Yru
ZsOEINoBNNwgrSctfis1pcaQlsC87Yru1w45vz4CRGzfeWi59qMtGW8b1ZNvpChE
C9uNV4U1mVY6L/wvUr7wZd3vmTQs9aTUibDLBt9S2TWsNigClYZ692x3H1bLHEse
M9esgzvL7erVHKmEsDALzAN59IjawC7SKXmmpUpw4WRbscsVN6kr+5uBHaU=
=OvRY
-----END PGP PUBLIC KEY BLOCK-----
EOF

# Import team pgp keys
if gpg --list-keys | grep -e 'btcxzelko\|s2l1\|Pavel\|likewhoa' &>/dev/null ; then
gpg --refresh-keys &>/dev/null && rm -f "${HOME}"/pgp.txt
else 
gpg --refresh-keys &>/dev/null && gpg --import "${HOME}"/pgp.txt &>/dev/null
rm -f "${HOME}"/pgp.txt
fi

function ronindebug {

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
fi

printf "\n"

# Get general system info
osdescrip=$(grep DESCRIPTION /etc/lsb-release | sed 's/DISTRIB_DESCRIPTION=//g')
osversion=$(grep RELEASE /etc/lsb-release | sed 's/DISTRIB_RELEASE=//g')
kernelversion=$(uname -r)
systemuptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
backendstatus=$(if [ -d "${ronin_ui_backend_dir}" ] && cd "${ronin_ui_backend_dir}" && pm2 status | grep "online" &>/dev/null; then echo "Online"; else echo "Offline"; fi)
torstatus=$(if ! _is_active tor; then echo "Online"; else echo "Offline"; fi)
dockerstatus=$(if ! _is_active docker; then echo "Online"; else echo "Offline"; fi)
cpu=$(cat /sys/class/thermal/thermal_zone0/temp)
tempC=$((cpu/1000))
tempoutput=$(echo $tempC $'\xc2\xb0'C)

cat <<EOF
#####################################################################
                     General System Information
#####################################################################
OS Description   :  $osdescrip
OS Version       :  $osversion
Kernel Version   :  $kernelversion
CPU Temperature  :  $tempoutput
Uptime           :  $systemuptime
UI Backend       :  $backendstatus
External Tor     :  $torstatus
Docker           :  $dockerstatus
EOF

printf "\n"

# Get Total Memory, Used Memory, Free Memory, Used Swap and Free Swap values
# All variables like this are used to store values as float 
# Using bc to do all math operations, without bc all values will be integers 
# Also we use if to add zero before value if value less than 1024, and result of dividing will be less than 1
totalmem=$(free -m | head -2 | tail -1| awk '{print $2}')
totalbc=$(echo "scale=2;if("$totalmem"<1024 && "$totalmem" > 0) print 0;"$totalmem"/1024"| bc -l)
usedmem=$(free -m | head -2 | tail -1| awk '{print $3}')
usedbc=$(echo "scale=2;if("$usedmem"<1024 && "$usedmem" > 0) print 0;"$usedmem"/1024"|bc -l)
freemem=$(free -m | head -2 | tail -1| awk '{print $4}')
freebc=$(echo "scale=2;if("$freemem"<1024 && "$freemem" > 0) print 0;"$freemem"/1024"|bc -l)
totalswap=$(free -m | tail -1| awk '{print $2}')
totalsbc=$(echo "scale=2;if("$totalswap"<1024 && "$totalswap" > 0) print 0;"$totalswap"/1024"| bc -l)
usedswap=$(free -m | tail -1| awk '{print $3}')
usedsbc=$(echo "scale=2;if("$usedswap"<1024 && "$usedswap" > 0) print 0;"$usedswap"/1024"|bc -l)
freeswap=$(free -m |  tail -1| awk '{print $4}')
freesbc=$(echo "scale=2;if("$freeswap"<1024 && "$freeswap" > 0) print 0;"$freeswap"/1024"|bc -l)

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
#${totalbc}GB\t${usedbc}GB \t${freebc}GB\t$(($freemem * 100 / $totalmem ))%

#=> Swap Memory
#Total\tUsed\tFree\t%Free
#Same as above – values in GB, and in same way we get % of usage
#${totalsbc}GB\t${usedsbc}GB\t${freesbc}GB\t$(($freeswap * 100 / $totalswap ))%
#"

# List of processes that are using most RAM
printf "=> Top memory using processes\n"
printf "PID %%MEM RSS COMMAND\n"
ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10

printf "\n"

cat <<EOF
#####################################################################
Disk Usage:      Normal <90%, Caution >90%, Unhealthy >95%
#####################################################################
EOF

# Display drive info
df -Pkh | grep -v 'Filesystem' > /tmp/df.status
while read disk
do
	line=$(echo $disk | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," freespace"}')
	echo -e $line 
done < /tmp/df.status

printf "\n"

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

while read disk
do
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

printf "\n"

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

printf "\n"

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
dmesg > "${HOME}"/debug.txt && gpg --encrypt --armor --recipient s2l1@pm.me --trust-model always "${HOME}"/debug.txt
cat "${HOME}"/debug.txt.asc | nc termbin.com 9999
rm -f "${HOME}"/debug*

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
ronindebug  > "${HOME}/$filename"
cat "${HOME}"/health-*.txt | nc termbin.com 9999

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
          cat "${HOME}"/health-*.txt
          # Make debug directory if one does not exist and move ronindebug script output there
          test ! -d "${ronin_debug_dir}" && mkdir "${ronin_debug_dir}"
          mv "${HOME}"/health-*.txt "${ronin_debug_dir}"
          _pause return
          bash -c "${ronin_system_monitoring}"
          exit
          ;;
        [nN][oO]|[Nn])
          test ! -d "${ronin_debug_dir}" && mkdir "${ronin_debug_dir}"
          mv "${HOME}"/health-*.txt "${ronin_debug_dir}"
          _pause return
          bash -c "${ronin_system_monitoring}"
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

exit