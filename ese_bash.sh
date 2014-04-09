#!/bin/bash


USER="root"
PORT=22
INTERFACE="eth0"

while getopts ":p:u:i:" opt; do
	case $opt in
		p)
		PORT=${OPTARG}		
		;;
		u)
		USER=${OPTARG}
		;;
		i)
		INTERFACE=${OPTARG}
		;;
	esac
done




MY_IP=$(ifconfig $INTERFACE | grep inet | grep -v inet6 | cut -d':' -f2 | tr -d [:alpha:] | tr -d [:blank:])
MY_SUBMASK=$(ifconfig $INTERFACE | grep inet | grep -v inet6 | cut -d':' -f4 | tr -d [:alpha:])
MY_SUBMASK_SLASH=$(for i in $(echo ${MY_SUBMASK} | tr '.' ' '); do echo "obase=2 ; $i" | bc ; done | awk '{printf "%08d", $1}' |cut -c2- | grep -o "1" | wc -l)

echo "Personal info"
echo "My Ip: "$MY_IP
echo "My submask: "$MY_SUBMASK
echo "Slash notation: /"$MY_SUBMASK_SLASH

echo "Scanning request"
echo "User: "$USER
echo "Port: "$PORT 
echo "Interface: "$INTERFACE

touch available_hosts
echo "Performing scan..."
echo "namp -p $PORT $MY_IP/$MY_SUBMASK_SLASH --open --exclude $MY_IP"
nmap -p $PORT $MY_IP/$MY_SUBMASK_SLASH --open --exclude $MY_IP | grep "Nmap scan report" > available_hosts

NUM_HOSTS=$(wc -l available_hosts | cut -d' ' -f1 )


COUNT=1
RES=255

if [ $NUM_HOSTS -ne 0 ]; then
	echo $NUM_HOSTS "available host/s"
	cat available_hosts  | sed s/'Nmap scan report for '//g 
	while [ $COUNT -le $NUM_HOSTS ] && [ $RES -ne 0 ]
	do
		TARGET_IP=$(sed -n $COUNT'p' available_hosts | sed -e 's/\(^.*(\)\(.*\)\().*$\)/\2/')
		echo "Connecting to the "$COUNT": "$TARGET_IP
		echo "trying ssh  $USER@$TARGET_IP:$PORT"
		ssh -p  $PORT $USER@$TARGET_IP
		RES=$?
		if [ $RES -ne 0] && [ $COUNT -ne $NUM_HOSTS ]; then
			echo "Trying the next one"
		fi	
		echo "RES" $RES
		COUNT=$(( $COUNT + 1 ))
	done;
	if [ $RES -ne 0 ]; then
		echo "It was not possible to establish a connection!"
	fi
else
	echo "No host founded"
fi


