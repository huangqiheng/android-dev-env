#!/bin/dash

ROOT_DIR=`dirname $(readlink -f $0)`

main() 
{
	check_update ppa:jonathonf/ffmpeg-3
	update_ffmpeg 3.3.0

	cd $ROOT_DIR &&  mkdir -p temp && cd temp

	if [ "$1" = "alsa" ]; then
		ffmpeg -s 1024x768 -r 25 -f x11grab -i :0.0+100,200 -f pulse -ac 2 -i default output.mkv
	elif [ "$1" = "pluse" ]; then
		ffmpeg -s 1024x768 -r 25 -f x11grab -i :0.0+100,200 -f alsa -ac 2 -i hw:0 output.mkv
	else
		ffmpeg -s 1024x768 -r 25 -f x11grab -i :0.0+100,200 output.mp4
	fi
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

cmp_version() 
{
	[ $1 = $2 ] && return 0

	A_ver=$1; B_ver=$2; IFS=.
	set -- $A_ver; A1=$1; A2=$2; A3=$3
	set -- $B_ver; B1=$1; B2=$2; B3=$3

	[ $A1 -gt $B1 ] && return 1
	[ $A1 -lt $B1 ] && return 2
	[ $A2 -gt $B2 ] && return 1
	[ $A2 -lt $B2 ] && return 2
	[ $A3 -gt $B3 ] && return 1
	[ $A3 -lt $B3 ] && return 2
	return 0
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
