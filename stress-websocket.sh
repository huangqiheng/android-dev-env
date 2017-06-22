#!/bin/dash

THIS_DIR=`dirname $(readlink -f $0)`

main() 
{
	check_update
	check_apt curl daemon

	if [ "$1" = "start" ]; then
		for i in $(seq 1 100); do
			curl --include \
			     --no-buffer \
			     --header "Connection: Upgrade" \
			     --header "Upgrade: websocket" \
			     --header "Host: example.com:80" \
			     --header "Origin: http://example.com:80" \
			     --header "Sec-WebSocket-Key: SGVsbG8sIHdvcmxkIQ==" \
			     --header "Sec-WebSocket-Version: 13" \
			     http://localhost:8082/ >/dev/null 2>&1 &
			echo "new pid $!"
		done
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
