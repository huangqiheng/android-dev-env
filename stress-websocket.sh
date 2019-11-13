#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh

main() 
{
	check_update
	check_apt curl daemon

	if [ "$1" = "stress" ]; then
		for i in $(seq 1 100); do
			curl --include \
			     --no-buffer \
			     --header "Connection: Upgrade" \
			     --header "Upgrade: websocket" \
			     --header "Host: ${WSHOST:-example.com:80}" \
			     --header "Origin: ${WSORIGIN:-http://example.com:80}" \
			     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
			     --header "Sec-WebSocket-Version: 13" \
			     "${WSURL:-http://192.168.2.202:8082/}" >/dev/null 2>&1 &
			echo "new pid $!"
		done
	elif [ "$1" = "start" ]; then
		curl --include \
		     --verbose  \
		     --no-buffer \
		     --http2 \
		     --header "Accept-Encoding: gzip, deflate, br" \
		     --header "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7" \
		     --header "Cache-Control: no-cache" \
		     --header "Connection: Upgrade" \
		     --header "Upgrade: websocket" \
		     --header "Host: ${WSHOST:-example.com:80}" \
		     --header "Origin: ${WSORIGIN:-http://example.com:80}" \
		     --header "Pragma: no-cache" \
		     --header "Sec-WebSocket-Extensions: permessage-deflate; client_max_window_bits" \
		     --header "Sec-WebSocket-Key: xvM4uYf9BBa6HnCMWa8sCA==" \
		     --header "Sec-WebSocket-Protocol: mqttv3.1" \
		     --header "Sec-WebSocket-Version: 13" \
		     --header "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/78.0.3904.70 Chrome/78.0.3904.70 Safari/537.36" \
		     "${WSURL:-http://192.168.2.202:8082/}"
	else
		kill -9 $(pidof curl)
	fi
}


#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	sudo $0"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			local the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
	fi 
}

check_apt()
{
	for package in "$@"; do
		if [ $(dpkg-query -W -f='${Status}' ${package} 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt install -y "$package"
		else
			log "${package} has been installed"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

cmd_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
