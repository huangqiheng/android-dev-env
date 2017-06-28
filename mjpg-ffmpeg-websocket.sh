#!/bin/dash

. ./config.sh

THIS_DIR=`dirname $(readlink -f $0)`
mjpg_src=$MJPG_SRC
qscale_val=20
src_size='1024x768'
dit_size='640x480'

main() 
{
	check_update ppa:jonathonf/ffmpeg-3
	check_apt build-essential v4l-utils daemon
	build_mjpg_streamer
	update_ffmpeg 3.3.0
	setup_jsmpeg
	runs "$@"
}

runs() {
	local root_dir=${THIS_DIR}/temp/jsmpeg
	local mpegts_url=http://localhost:8081/supersecret

	if [ "$1" = "start" ]; then
		if [ "$2" = "camera" ] || [ -z "$2" ]; then
			if pidof mjpg_streamer >/dev/null; then
				log 'mjpg_streamer is running' 
			else
				local MJPG_WWW=/usr/local/share/mjpg-streamer/www
				export LD_LIBRARY_PATH=/usr/local/lib/mjpg-streamer
				mjpg_streamer -i "input_uvc.so -n -r ${src_size}" -o "output_http.so -p 8083 -w ${MJPG_WWW}" &
				log 'mjpg_streamer was started' 
			fi
			[ ! -z "$2" ] && return 0
		fi

		if [ "$2" = "mpegts" ] || [ -z "$2" ]; then
			local mjpg_url=${3:-"$mjpg_src"}
			daemon -r -n httpserver -D "$root_dir" -- http-server -P 8080
			daemon -r -n wsockrelay -D "$root_dir" -- node $root_dir/websocket-relay.js supersecret 8081 8082
			daemon -r -n ffmpegpush -D "$root_dir" -- ffmpeg -re -r 30 -i "$mjpg_url" -f mpegts -c:v mpeg1video -q:v $qscale_val -bf 0 "$mpegts_url"
			[ ! -z "$2" ] && return 0
		fi
		return 0
	fi

	if [ "$1" = "restart" ]; then
		if [ "$2" = "ffmpeg" ] || [ -z "$2" ]; then
			local mjpg_url=${3:-"$mjpg_src"}
			daemon -n ffmpegpush --stop 2>/dev/null
			daemon -r -n ffmpegpush -D "$root_dir" -- ffmpeg -re -r 30 -i "$mjpg_url" -f mpegts -c:v mpeg1video -q:v $qscale_val -bf 0 "$mpegts_url"
			[ ! -z "$2" ] && return 0
		fi
		return 0
	fi

	if [ "$1" = "stop" ]; then
		if [ "$2" = "camera" ] || [ -z "$2" ]; then
			kill -9 $(pidof mjpg_streamer) 2>/dev/null
			log 'mjpg_streamer was killed' 
			[ ! -z "$2" ] && return 0
		fi

		if [ "$2" = "mpegts" ] || [ -z "$2" ]; then
			daemon -n httpserver --stop 2>/dev/null
			daemon -n wsockrelay --stop 2>/dev/null
			daemon -n ffmpegpush --stop 2>/dev/null
			[ ! -z "$2" ] && return 0
		fi

		if [ "$2" = "ffmpegpush" ]; then
			daemon -n ffmpegpush --stop 2>/dev/null
			[ ! -z "$2" ] && return 0
		fi

		return 0
	fi
}

setup_jsmpeg()
{
	if ! cmd_exists /usr/bin/node; then
		log "installing nodejs"
		curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
		check_apt nodejs
	fi

	if ! cmd_exists /usr/bin/http-server; then
		log "installing http-server"
		npm -g install http-server
	fi
	
	cd $THIS_DIR &&  mkdir -p temp && cd temp

	if [ ! -d "jsmpeg" ]; then
		git clone https://github.com/phoboslab/jsmpeg.git
	fi
	
	cd jsmpeg

	if [ ! -d "node_modules/ws" ]; then
		npm install ws
	fi

	log "jsmpeg relay is ready"
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

build_mjpg_streamer()
{
	if cmd_exists mjpg_streamer; then
		log 'mjpg_streamer has been installed'
		return 0
	fi

	check_apt cmake libjpeg8-dev

	cd $THIS_DIR && mkdir -p temp && cd temp

	if [ ! -d "mjpg-streamer" ]; then
		git clone https://github.com/jacksonliam/mjpg-streamer.git
	fi

	cd mjpg-streamer/mjpg-streamer-experimental
	make
	make install
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
