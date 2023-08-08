#!/bin/bash

CONFIG_PATH=/data/options.json

read_config() {
    ZONE=$(jq --raw-output ".zone" $CONFIG_PATH)
    HOST=$(jq --raw-output ".host" $CONFIG_PATH)
    EMAIL=$(jq --raw-output ".email" $CONFIG_PATH)
    API=$(jq --raw-output ".api" $CONFIG_PATH)

    # Enforces required env variables
    for required_var in ZONE HOST EMAIL API; do
        if [[ -z ${!required_var} ]]; then
            echo >&2 "Error: $required_var config variable not set."
            exit 1
        fi
    done
}

validate_environment() {
    # PROXY defaults to true
    PROXY=${PROXY:-true}

    # TTL defaults to 1 (automatic), and is validated
    TTL=${TTL:-1}
    if [[ $TTL != 1 ]] && [[ $TTL -lt 120 || $TTL -gt 2147483647 ]]; then
        echo >&2 "Error: Invalid TTL value $TTL; must be either 1 (automatic) or between 120 and 2147483647 inclusive."
        exit 1
    fi
}

get_current_ip() {
    local ip_curl="curl -4s"
    [[ -n $IPV6 ]] && ip_curl="curl -6s"
    
    local services=("https://davidramosweb.com/miip.php" "http://whatismyip.akamai.com" "http://icanhazip.com/" "https://tnx.nl/ip")
    for service in "${services[@]}"; do
        local ip=$($ip_curl $service)
        [[ -n $ip ]] && echo $ip && return 0
    done
    
    echo >&2 "Error: Unable to reach any service to determine the IP address."
    exit 1
}

update_dns_record() {
    local ip=$1

    # Fetches the zone information for the account
    # ... the rest of your logic here ...

    # Check success
    if [[ $(jq <<<"$dns_record_response" -r '.success') = "true" ]]; then
        echo "IP changed to: $ip"
        echo "$ip" > /data/ip.dat
    else
        local messages=$(jq <<<"$dns_record_response" -r '[.errors[] | .error.message] |join(" - ")')
        echo >&2 "Error: $messages"
        exit 1
    fi
}

main() {
    read_config
    validate_environment

    while true; do
        echo "Current time: $(date "+%Y-%m-%d %H:%M:%S")"
        local new_ip=$(get_current_ip)

        local ip_file="/data/ip.dat"
        [[ -f $ip_file && $(<$ip_file) == "$new_ip" ]] && echo "IP is unchanged : $new_ip. Exiting." && exit 0

        update_dns_record $new_ip

        sleep 300
    done
}

main


