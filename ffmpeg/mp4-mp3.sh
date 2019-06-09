#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`

main() 
{
	check_update ppa:jonathonf/ffmpeg-3
	update_ffmpeg 3.3.0

	[ -z $1 ] && return 0

	cd $ROOT_DIR/temp

	ffmpeg -i "$1" -ss 3 -i "$2" -c:v copy -map 0:v:0 -map 1:a:0 -shortest /home/and/Videos/out.mp4
}

update_ffmpeg()
{
	if cmd_exists ffmpeg; then 
		local need_ver=$1

		IFS=' -'; set -- $(ffmpeg -version | grep "ffmpeg version");  
		local current_version=$3
		
		cmp_version $current_version $need_ver

		if [ ! $? -eq 2 ]; then
			log "ffmpeg $current_version >= $need_ver"
			return
		fi

		apt purge -y ffmpeg 
	fi

	check_apt ffmpeg libav-tools x264 x265
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
