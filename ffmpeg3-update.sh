#!/bin/bash

[ -z "$BASH_VERSION" ] && echo "Change to: bash $0" && setsid bash $0 && exit
THIS_DIR=`dirname $(readlink -f $0)`

main () 
{
	setup_ffmpeg3
}

setup_ffmpeg3()
{
	if need_ffmpeg 3.3.0; then
		log 'need to update ffmpeg'
		apt purge -y ffmpeg 
		check_update ppa:jonathonf/ffmpeg-3
	fi

	check_apt ffmpeg libav-tools x264 x265

	log "Now ffmpeg version is: $(ffmpeg_version)"
}

need_ffmpeg()
{
	local current_version=$(ffmpeg_version)
	[ ! $? ] && return 0
	version_compare $current_version $1
	[ ! $? -eq 1 ] && return 0
	return 1
}


version_compare () 
{
	if [[ $1 == $2 ]]; then
		return 0
	fi

	local IFS=.
	local i ver1=($1) ver2=($2)
	for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
		ver1[i]=0
	done

	for ((i=0; i<${#ver1[@]}; i++)); do
		if [[ -z ${ver2[i]} ]]; then
			ver2[i]=0
		fi
		if ((10#${ver1[i]} > 10#${ver2[i]})); then
			return 1
		fi
		if ((10#${ver1[i]} < 10#${ver2[i]})); then
			return 2
		fi
	done
	return 0
}

ffmpeg_version()
{
	! cmd_exists ffmpeg && return 1
	IFS=' -'; set -- $(ffmpeg -version | grep "ffmpeg version"); echo $3
	[ ! -z $3 ]
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
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

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
