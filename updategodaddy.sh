#/bin/bash

# This script is used to check and update your GoDaddy DNS server to the IP address of your current internet connection.
#
# Original PowerShell script by mfox: https://github.com/markafox/GoDaddy_Powershell_DDNS
# Ported to bash by sanctus
# Added AAAA record by Binny Chan
#
# Improved to take command line arguments and output information for log files by pollito
#
# First go to GoDaddy developer site to create a developer account and get your key and secret
#
# https://developer.godaddy.com/getstarted
#
# Be aware that there are 2 types of key and secret - one for the test server and one for the production server
# Get a key and secret for the production server

# Check an A record and a domain are both specified on the command line.

if [ $# -ne 3 ]; then
    echo "usage: $0 type a_record domain_name"
    echo "usage: $0 AAAA www my_domain"
    exit 1
fi

# Set A record and domain to values specified by user

type=$1     # name of A record to update
name=$2     # name of A record to update
domain=$3   # name of domain to update

# Modify the next two lines with your key and secret

key=""      # key for godaddy developer API
secret=""   # secret for godaddy developer API

headers="Authorization: sso-key $key:$secret"

#echo $headers

result=$(curl -s -k -X GET -H "$headers" \
 "https://api.godaddy.com/v1/domains/$domain/records/$type/$name")

if [ $type = "AAAA" ]; then
        dnsIp=$(echo $result | grep -oE "\b([0-9a-fA-F]{0,4}|0)(\:([0-9a-fA-F]{0,4}|0)){7}\b")
else
        dnsIp=$(echo $result | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
fi
echo $name"."$domain": $(date): dnsIp:" $dnsIp

# Check for A or AAAA record to get different ip address
if [ $type = "AAAA" ]; then
        # Get IPv6 address
        currentIp=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)
else
        # Get public ip address there are several websites that can do this.
        ret=$(curl -s GET "http://ipinfo.io/json")
        currentIp=$(echo $ret | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")
fi
echo $name"."$domain": $(date): currentIp:" $currentIp

# ip not match
if [ $dnsIp != $currentIp ];
 then
        echo $name"."$domain": $(date): IPs not equal. Updating."
        request='{"data":"'$currentIp'","ttl":3600}'
        #echo $request
        nresult=$(curl -i -k -s -X PUT \
 -H "$headers" \
 -H "Content-Type: application/json" \
 -d $request "https://api.godaddy.com/v1/domains/$domain/records/$type/$name")
        #echo $nresult
fi