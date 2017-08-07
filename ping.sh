#!/bin/bash


#address=192.168.1.99 # forced bad address
address=23.208.224.170 # www.cisco.com
internet=1 # default to internet is up
pingarr=(0 0 0)
arrindex=0

sabip=10.0.0.100
sabport=8080

#curl -s "http://$sabip:$sabport/sabnzbd/api?output=json&apikey=$sabkey&mode=config&name=speedlimit&value=300K"

while true;
do

    
    sabstatus=$(curl -s "http://$sabip:$sabport/sabnzbd/api?output=json&apikey=$sabkey&mode=queue&start=START&limit=LIMIT&search=SEARCH" | grep -oP "(?<=status\": \")[^\"]+")

    if [[ $sabstatus == "Downloading" || $sabstatus == "Paused" ]]; then
        sabspeed=$(curl -s "http://$sabip:$sabport/sabnzbd/api?output=json&apikey=$sabkey&mode=queue&start=START&limit=LIMIT&search=SEARCH" | grep -oP "(?<=speedlimit_abs\": \")[^\"]+")
        timeleft=$(curl -s "http://$sabip:$sabport/sabnzbd/api?output=json&apikey=$sabkey&mode=queue&start=START&limit=LIMIT&search=SEARCH" | grep -oP "(?<=timeleft\": \")[^\:]+")
        rdmcase=$((1 + RANDOM % 5))
        case $rdmcase in
            
            1)  #echo "208.67.220.220 # openDNS.org"
                address=208.67.220.220 # openDNS.org
                ;;
            2)  #echo  "address=8.8.8.8 #Google DNS"
                address=8.8.8.8 #Google DNS
                ;;
            3)  #echo  "address=216.58.205.227 # google.de"
                address=216.58.205.227 # google.de
                ;;
            4) #echo  "address=204.79.197.200 #bing.com"
            address=204.79.197.200 #bing.com
            ;;
            *) #echo "address=216.58.208.46 #google.com"
            address=216.58.208.46 #google.com
            ;;
        esac
        
        # %a Day of Week, textual
        # %b Month, textual, abbreviated
        # %d Day, numeric
        # %r Timestamp AM/PM
        # echo -n $(date +"%a, %b %d, %r") "-- "
        ping -c 1 ${address} > /tmp/ping.$
        if [[ $? -ne 0 ]]; then
            if [[ ${internet} -eq 1 ]]; then # edge trigger -- was up now down
                #echo -n $(say "Internet down") # OSX Text-to-Speech
                echo -n "Internet DOWN"
            else
                echo -n "... still down"
            fi
            internet=0
        else
            if [[ ${internet} -eq 0 ]]; then # edge trigger -- was down now up
                echo "Internet BACK UP"
            fi
            internet=1
        fi
        #cat /tmp/ping.$ | head -2 | tail -1
        ping=$(cat /tmp/ping.$ | head -2 | tail -1 | grep -oP "(?<=time=)[0-9.]+")
        #echo "single ping:  $ping"
        pingarr[arrindex]=$ping
        arrindex=$(((arrindex+1)%3))
        
        average=$(echo "${pingarr[0]}+${pingarr[1]}+${pingarr[2]}" | bc) 
        #echo "average: $average"
        
        if (( $(echo "$average < 200" | bc -l) )); then
            newspeed=$(echo "($sabspeed/1024)+50" | bc)
            echo "Speed ++ $newspeed kB/s"
            if (( $(echo "$timeleft < 250" | bc -l) )); then
                curl -s "http://${sabip}:${sabport}/sabnzbd/api?output=json&apikey=${sabkey}&mode=config&name=speedlimit&value=${newspeed}K" > /dev/null
            fi
        elif (( $(echo "$average > 600" | bc -l) )); then
            
            newspeed=$(echo "($sabspeed/1024)-150" | bc)
            echo "Speed -- $newspeed kB/s"
            if (( $(echo "$newspeed > 0" | bc -l) )); then
                curl -s "http://${sabip}:${sabport}/sabnzbd/api?output=json&apikey=${sabkey}&mode=config&name=speedlimit&value=${newspeed}K" > /dev/null
            fi
        else
            echo "Speed OK ($sabspeed bytes/s)" 
        fi
        
        
        sleep 3 ; # sleep: 60 seconds = 1 min
    else
        echo "No Downloadd in progress..."
        sleep 30 ; # sleep: 60 seconds = 1 min
    fi
done
