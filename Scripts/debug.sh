#!/bin/bash
# shellcheck source=/dev/null disable=SC2154

. "$HOME"/RoninDojo/Scripts/defaults.sh
. "$HOME"/RoninDojo/Scripts/dojo-defaults.sh
. "$HOME"/RoninDojo/Scripts/functions.sh

# Check for package dependencies
for pkg in sysstat bc; do
    _check_pkg "${pkg}"
done

    _check_pkg "sysstat" "bc"

cat <<EOF
     _____           _____  _____   ______    ____  _____   ______   
 ___|\    \     ____|\    \|\    \ |\     \  |    ||\    \ |\     \  
|    |\    \   /     /\    \\\    \|  \     \ |    |  \\    \| \     \ 
|    | |    | /     /  \    \\|    \   \     ||    |  \|    \  \     |
|    |/____/ |     |    |    ||     \  |    ||    |   |     \  |    |
|    |\    \ |     |    |    ||      \ |    ||    |   |      \ |    |
|    | |    ||\     \  /    /||    |\ \|    ||    |   |    |\ \|    |
|____| |____|| \_____\/____/ ||____||\_____/||____|   |____||\_____/|
|    | |    | \ |    ||    | /|    |/ \|   |||    |   |    |/ \|   ||
|____| |____|  \|____||____|/ |____|   |___|/|____|   |____|   |___|/
  \(     )/       \(    )/      \(       )/    \(       \(       )/  
   '     '         '    '        '       '      '        '       '                                                                                                                            
     _____        ______         _____    ____   ____       _____    
 ___|\    \   ___|\     \   ___|\     \  |    | |    |  ___|\    \  .  .  
|    |\    \ |     \     \ |    |\     \ |    | |    | /    /\    \  \/             ,  
|    | |    ||     ,_____/||    | |     ||    | |    ||    |  |____|@'"@_.-"':_.-"': 
|    | |    ||     \--'\_|/|    | /_ _ / |    | |    ||    |    ____ 4'  ',.,'"',.,'
|    | |    ||     /___/|  |    |\    \  |    | |    ||    |   |    |     |||   |||
|    | |    ||     \____|\ |    | |    | |    | |    ||    |   |_,  |    "'"'" ""''"
|____|/____/||____ '     /||____|/____/| |\___\_|____||\ ___\___/  /|
|    /    | ||    /_____/ ||    /     || | |    |    || |   /____ / |
|____|____|/ |____|     | /|____|_____|/  \|____|____| \|___|    | / 
  \(    )/     \( |_____|/   \(    )/        \(   )/     \( |____|/  
   '    '       '    )/       '    '  .---. \/'   '       '   )/     
 .---. \/                     '      (._.' \()                '                                 
(._.' \()                             ^"""^"
 ^"""^"
EOF

printf "\n" # Add new line

function systemstats {

cat <<EOF
#####################################################################
        System Stats (CPU, Process, Disk Usage, Memory)
#####################################################################
OS Description   : `grep DESCRIPTION /etc/lsb-release | sed 's/DISTRIB_DESCRIPTION=//g'`
OS Version       : `grep RELEASE /etc/lsb-release | sed 's/DISTRIB_RELEASE=//g'`
Kernel Version   : `uname -r`
Uptime           : `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
#####################################################################
CPU Load:       <1 Normal,  >1 Caution,  >2 Unhealthy 
#####################################################################
EOF

MPSTAT=`which mpstat`
MPSTAT=$?
if [ $MPSTAT != 0 ] ; then
	    printf "\nPlease install mpstat...\n"
	    printf "\nOn Manjaro based systems:\n"
	    printf "\nsudo pacman -S sysstat\n"
    else
        LSCPU=`which lscpu`
        LSCPU=$?
        if [ $LSCPU != 0 ] ; then
	            RESULT=$RESULT" lscpu required to obtain proper results"
            else
                cpus=`lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}'`
                i=0
            while [ $i -lt $cpus ] ; do
	            echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($3 == var ) print $4 }' `"
	            let i=$i+1
            done
        fi
        cat <<EOF
Load Average : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,`
Heath Status : `uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`
EOF
fi

printf "\n" # Add new line

cat <<EOF
#####################################################################
Disk Usage:      Normal <90%, Caution >90%, Unhealthy >95%
#####################################################################
EOF

df -Pkh | grep -v 'Filesystem' > /tmp/df.status
while read DISK
do
	LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
	echo -e $LINE 
done < /tmp/df.status

printf "\n" # Add new line

cat <<EOF
#####################################################################
Disk Heath Status:
#####################################################################
EOF

while read DISK
do
	USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`
	if [ $USAGE -ge 95 ] 
	then
		STATUS='Unhealthy'
	elif [ $USAGE -ge 90 ]
	then
		STATUS='Caution'
	else
		STATUS='Normal'
	fi
        LINE=`echo $DISK | awk '{print $1,"\t",$6}'`
        echo -ne $LINE "\t\t" $STATUS
        printf "\n" # Add new line
done < /tmp/df.status
rm /tmp/df.status

TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
TOTALBC=`echo "scale=2;if($TOTALMEM<1024 && $TOTALMEM > 0) print 0;$TOTALMEM/1024"| bc -l`
USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
USEDBC=`echo "scale=2;if($USEDMEM<1024 && $USEDMEM > 0) print 0;$USEDMEM/1024"|bc -l`
FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`
FREEBC=`echo "scale=2;if($FREEMEM<1024 && $FREEMEM > 0) print 0;$FREEMEM/1024"|bc -l`
TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
TOTALSBC=`echo "scale=2;if($TOTALSWAP<1024 && $TOTALSWAP > 0) print 0;$TOTALSWAP/1024"| bc -l`
USEDSWAP=`free -m | tail -1| awk '{print $3}'`
USEDSBC=`echo "scale=2;if($USEDSWAP<1024 && $USEDSWAP > 0) print 0;$USEDSWAP/1024"|bc -l`
FREESWAP=`free -m |  tail -1| awk '{print $4}'`
FREESBC=`echo "scale=2;if($FREESWAP<1024 && $FREESWAP > 0) print 0;$FREESWAP/1024"|bc -l`

printf "\n" # Add new line

cat <<EOF
#####################################################################
Memory Usage:
#####################################################################
EOF

echo -e "
=> Physical Memory
Total\tUsed\tFree\t%Free
${TOTALBC}GB\t${USEDBC}GB \t${FREEBC}GB\t$(($FREEMEM * 100 / $TOTALMEM  ))%

=> Swap Memory
Total\tUsed\tFree\t%Free
${TOTALSBC}GB\t${USEDSBC}GB\t${FREESBC}GB\t$(($FREESWAP * 100 / $TOTALSWAP  ))%
"

printf "=> Top memory using processes\n"
printf "PID %%MEM RSS COMMAND\n"
ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10
}

systemstats | cat

#FILENAME="health-`date +%y%m%d`-`date +%H%M`.txt"
#echo -e "Reported file $FILENAME generated in current directory." $RESULT

# termbin.com is powered by Fiche - open source command line pastebin server. 
# Link to termbin github repository: https://github.com/solusipse/fiche.
# Life span of single paste is one month. Older pastes are deleted.