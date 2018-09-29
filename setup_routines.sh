#!/bin/bash

install_wps()
{
	if cmd_exists wps; then
		echo "wps has been installed."
		return
	fi

	check_apt unzip

	cd $CACHE_DIR
	wget http://kdl.cc.ksosoft.com/wps-community/download/6757/wps-office_10.1.0.6757_amd64.deb
	dpkg -i wps-office_10.1.0.6757_amd64.deb

	cd $DATA_DIR
	unzip wps_symbol_fonts.zip -d /usr/share/fonts/wps-office

	ratpoisonrc "bind C-p exec /usr/bin/wps"
}

install_astrill()
{
	if cmd_exists /usr/local/Astrill/astrill; then
		echo "astrill has been installed."
		return
	fi

	cd $CACHE_DIR

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		wget https://astrill4u.com/downloads/astrill-setup-linux64.sh
	fi

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		# check_apt 
		check_apt libgtk2.0-0
		apt --fix-broken install
		check_apt gtk2-engines-pixbuf
		if [ -f "$DATA_DIR/astrill-setup-linux64.deb" ]; then
			dpkg -i "$DATA_DIR/astrill-setup-linux64.deb"
			ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
		else
			log 'FIXME: download astrill failure'
		fi
		return
	fi

	set_comt $CACHE_DIR/astrill-setup-linux64.sh
	set_comt off '#' 'read x'

	bash astrill-setup-linux64.sh

	ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
}


setup_golang()
{
	if cmd_exists go; then
		log 'golang is installed'
		return 0
	fi

	if [ "$1" = "" ]; then
		check_update ppa:longsleep/golang-backports
		check_apt golang-go
		return 1
	fi

	cd $CACHE_DIR
	wget https://dl.google.com/go/go${1}.linux-amd64.tar.gz
	tar -C /usr/local -xzf go${1}.linux-amd64.tar.gz
	echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
	echo 'export PATH=$PATH:$HOME/go/bin' >> /etc/profile

	return 2
}

setup_typescript()
{
	setup_nodejs
	check_npm_g typescript
}

setup_nodejs()
{
	if cmd_exists /usr/bin/node; then
		log "node has been installed"
		return
	fi

	curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
	check_apt nodejs
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

version_compare() 
{
	dpkg --compare-version "$1" eq "$2" && return 0
	dpkg --compare-version "$1" lt "$2" && return 1
	return 2
}

ffmpeg_version()
{
	! cmd_exists ffmpeg && return 1
	IFS=' -'; set -- $(ffmpeg -version | grep "ffmpeg version"); echo $3
	[ ! -z $3 ]
}

