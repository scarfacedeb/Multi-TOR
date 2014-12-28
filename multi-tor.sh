#!/bin/bash

# Original script from
# http://blog.databigbang.com/distributed-scraping-with-multiple-tor-circuits/

# it starts from 1
base_socks_port=9048
base_control_port=9049
base_privoxy_port=8079

# Create data directory if it doesn't exist
if [ ! -d "tor" ]; then
	mkdir "tor"
fi

TOR_INSTANCES="$1"

if [ ! $TOR_INSTANCES ] || [ $TOR_INSTANCES -lt 1 ]; then
    echo "Please supply an instance count"
    echo "Example: ./multi-tor.sh 5"
    exit 1
fi

for i in $(seq $TOR_INSTANCES)
do
	j=$((i+1))
	socks_port=$((base_socks_port+2*i))
	control_port=$((base_control_port+2*i))
  privoxy_http_port=$((base_privoxy_port+i))
	if [ ! -d "tor/data$i" ]; then
		echo "Creating directory tor/data$i"
		mkdir "tor/data$i"
	fi

	# Take into account that authentication for the control port is disabled. Must be used in secure and controlled environments
	echo "Running: tor --RunAsDaemon 1 --CookieAuthentication 0 --ControlPort $control_port --PidFile tor/tor$i.pid --SocksPort $socks_port --DataDirectory tor/data$i"

	tor --RunAsDaemon 1 --CookieAuthentication 0 --ControlPort $control_port --PidFile tor/tor$i.pid --SocksPort $socks_port --DataDirectory tor/data$i


  if [ ! -f "tor/privoxy$i.conf" ]; then
    echo "Generating privoxy config"

    echo "confdir /usr/local/etc/privoxy" > tor/privoxy$i.conf
    echo "listen-address 127.0.0.1:$privoxy_http_port" >> tor/privoxy$i.conf
    echo "forward-socks5 / 127.0.0.1:$socks_port ." >> tor/privoxy$i.conf
  fi

  echo "Running privoxy tor/privoxy$i.conf"
  privoxy tor/privoxy$i.conf

done
