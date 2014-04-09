#!/bin/bash


USER="root"
PORT=22
INTERFACE="eth0"

while getopts ":p:u:i:" opt; do
	case $opt in
		p)
			P=${OPTARG}
			re='^[0-9]+$'
			if [[ $P =~ $re ]]; then
				if [ $P -ge 1 ] && [ $P -le 65535 ]; then
					PORT=$P
				else
					echo -e "\e[31mPort range not correct [1-65535]\e[0m"
					exit -1;
				fi
			else
				echo -e "\e[31mThe port value must be a number [1-65535]\e[0m"
				exit -1;
			fi		
			;;
		u)
			USER=${OPTARG}
			;;
		i)
			I=${OPTARG}
			I_EXISTS=$(lshw -class network 2> sample.err | grep logical | grep -w $I | wc -l )
			if [[ $I_EXISTS -ne 1 ]]; then
				echo -e "\e[31mInterface not found\e[0m"
				exit -1;			
			else
				INTERFACE=$I
			fi
			;;
		*)
			echo -e "\e[31mInvalid option: -$OPTARG\e[0m" >&2
			exit -1;
			;;
	esac
done



MY_IP=$(ifconfig $INTERFACE | grep inet | grep -v inet6 | cut -d':' -f2 | tr -d [:alpha:] | tr -d [:blank:])
MY_SUBMASK=$(ifconfig $INTERFACE | grep inet | grep -v inet6 | cut -d':' -f4 | tr -d [:alpha:])
MY_SUBMASK_SLASH=$(for i in $(echo ${MY_SUBMASK} | tr '.' ' '); do echo "obase=2 ; $i" | bc ; done | awk '{printf "%08d", $1}' |cut -c2- | grep -o "1" | wc -l)

echo ""
echo "Personal info"
echo "My Ip: "$MY_IP
echo "My submask: "$MY_SUBMASK
echo "Slash notation: /"$MY_SUBMASK_SLASH


touch available_hosts
echo ""
echo "Performing scan..."
echo -e "\e[32mnamp -p $PORT $MY_IP/$MY_SUBMASK_SLASH --open --exclude $MY_IP\e[0m"
nmap -p $PORT $MY_IP/$MY_SUBMASK_SLASH --open --exclude $MY_IP | grep "Nmap scan report" > available_hosts

NUM_HOSTS=$(wc -l available_hosts | cut -d' ' -f1 )


COUNT=1
RES=255

echo ""
if [ $NUM_HOSTS -ne 0 ]; then
	echo $NUM_HOSTS "available host/s:"
	cat available_hosts  | sed s/'Nmap scan report for '//g 
	
	while [ $COUNT -le $NUM_HOSTS ] && [ $RES -ne 0 ]
	do

		TARGET_IP=$(sed -n $COUNT'p' available_hosts | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
		echo ""
		echo "Connecting to the "$COUNT" available ("$TARGET_IP")"
		echo -e "\e[32mssh -p $PORT $USER@$TARGET_IP:$PORT\e[0m"
		ssh -p $PORT $USER@$TARGET_IP 
		# > ssh_error 2>&1
		#echo -e "\e[31m"$(sed -n '1p' ssh_error)"\e[0m"
		
		RES=$?
		if [ $RES -ne 0 ] && [ $COUNT -ne $NUM_HOSTS ]; then
			echo -e "\e[31mAttempt $COUNT ended: result code" $RES"\e[0m"
			echo "Trying the next one"
		fi	
		COUNT=$(( $COUNT + 1 ))
	done;
	if [ $RES -ne 0 ]; then
		echo ""
		echo -e "\e[31mIt was not possible to establish a connection\e[0m"
	fi
else
	echo -e "\e[31mNo host founded\e[0m"
fi


