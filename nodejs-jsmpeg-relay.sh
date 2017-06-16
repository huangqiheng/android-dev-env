#!/bin/bash

THIS_DIR=`dirname $(readlink -f $0)`
#IN_VIDEO=$THIS_DIR/codes/001.mp4
IN_VIDEO=/var/www/vodsrv/mp4/333.mp4

main () 
{
	check_update
	check_apt build-essential git ffmpeg v4l-utils daemon
	setup_nodejs
	setup_jsmpeg
	runs "$@"
}

runs()
{
	if [ "$1" = "stop" ]; then
		daemon --name=httpserver --stop
		daemon --name=wsockrelay --stop
		daemon --name=ffmpegpush --stop
		exit
	fi

	www_root=${THIS_DIR}/temp/jsmpeg
	cd $www_root

	daemon --name=httpserver --respawn --chdir=$www_root --command=http-server
	pid_web=$!

	daemon --name=wsockrelay --respawn --chdir=$www_root --command="node $www_root/websocket-relay.js supersecret 8081 8082"
	pid_wsock=$!

	v4l2-ctl --device=/dev/video0 --set-fmt-video=width=1280,height=720
	ffmpeg_cmd="ffmpeg -re -r 24  -f v4l2 -i /dev/video0 -f mpegts -s 1280x720 -c:v mpeg1video -q:v 10 -c:a mp2 http://localhost:8081/supersecret"
	#ffmpeg_cmd="ffmpeg -re -f v4l2 -i /dev/video0 -f mpegts -r 30 -s 600x480 -c:v mpeg1video -q:v 6 -c:a mp2 http://localhost:8081/supersecret -f flv rtmp://localhost/live/stream"
	#ffmpeg_cmd="ffmpeg -re -i ${IN_VIDEO} -f mpegts -r 30 -s 960x540 -c:v mpeg1video -q:v 6 -c:a mp2 http://localhost:8081/supersecret"
	pid_ffmpeg=$!

	daemon --name=ffmpegpush --respawn --chdir=$www_root --command="${ffmpeg_cmd}"
}


setup_jsmpeg()
{
	if command_exists /usr/bin/node; then
		log "http-server has been installed"
	else
		npm -g install http-server
	fi

	
	cd $THIS_DIR &&  mkdir -p temp && cd temp

	if [ ! -d "jsmpeg" ]; then
		git clone https://github.com/phoboslab/jsmpeg.git
	fi
	
	cd jsmpeg

	if [ ! -d "node_modules/ws" ]; then
		npm install ws
	else 
		log "jsmpeg relay is ready"
	fi
}

setup_nodejs()
{
	if command_exists /usr/bin/node; then
		log "node has been installed"
		return
	fi

	curl -sL https://deb.nodesource.com/setup_7.x | sudo -E bash -
	check_apt nodejs
}

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

check_update()
{
	if [ $(whoami) != 'root' ]; then
	    echo "
	This script should be executed as root or with sudo:
	    sudo $0
	"
	    exit 1
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))

	if [ $diff_time -gt 604800 ]; then
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

command_exists() 
{
    type "$1" > /dev/null 2>&1
}

main "$@"; exit $?
