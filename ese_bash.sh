#!/bin/bash


USER=$1
PORT=$2
INTERFACE=$3
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

NUM_HOST=$(wc -l available_hosts)
echo $NUM_HOST "available host/s"
cat available_hosts  | sed s/'Nmap scan report for '//g 

COUNT=1
RES=1
while [  "$COUNT" -le "$NUM_HOST" ]
do
TARGET_IP=$(sed -n $COUNT'p' available_hosts | sed -e 's/\(^.*(\)\(.*\)\().*$\)/\2/')

echo "Connecting to the first available: "$TARGET_IP
echo "trying ssh  $USER@$TARGET_IP:$PORT"
ssh -p  $PORT $USER@$TARGET_IP
RES=$?
echo "RES" $RES
COUNT=$(( $COUNT + 1 ))

done;
