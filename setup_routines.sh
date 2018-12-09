#!/bin/bash

x11_forward_server()
{
	log_g 'setting ssh server'
	check_update_once
	check_apt xauth

	set_conf /etc/ssh/sshd_config
	set_conf X11Forwarding yes ' '
	set_conf X11DisplayOffset 10 ' '
	set_conf X11UseLocalhost no ' '

	cat /var/run/sshd.pid | xargs kill -1
}

x11_forward_client()
{
	log_g 'setting ssh client'
	cat > $HOME/.ssh/config <<EOL
Host *
  ForwardAgent yes
  ForwardX11 yes
EOL
}

install_wps()
{
	if cmd_exists wps; then
		log_g "wps has been installed."
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

setup_objconv()
{
	if cmd_exists objconv; then
		log_g "objconv has been installed"
		return
	fi

	cd $CACHE_DIR
	if [ ! -d objconv ]; then
		git clone https://github.com/vertis/objconv.git
	fi

	cd objconv

	g++ -o objconv -O2 src/*.cpp  -Wno-narrowing -Wno-format-overflow

	cp objconv /usr/local/bin
}

cloudinit_remove()
{
	if [ ! -d /etc/cloud/ ]; then
		log_y 'cloud-init isnt exists'
		return
	fi

	log_g 'datasource_list: [ None ]' | sudo -s tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
	apt-get purge -y cloud-init
	rm -rf /etc/cloud/
	rm -rf /var/lib/cloud/
}

install_astrill()
{
	if cmd_exists /usr/local/Astrill/astrill; then
		log_g "astrill has been installed."
		return
	fi

	cd $CACHE_DIR


	# check_apt 
	check_apt libgtk2.0-0
	apt --fix-broken install
	check_apt gtk2-engines-pixbuf gtk2-engines-murrine gnome-themes-extra
	
	if [ -f "$DATA_DIR/astrill-setup-linux64.deb" ]; then
		dpkg -i "$DATA_DIR/astrill-setup-linux64.deb"
		ratpoisonrc "bind C-a exec /usr/local/Astrill/astrill"
		return 0
	else
		log_y 'FIXME: download astrill-setup-linux64.deb please'
		return 1
	fi
}

setup_gotty()
{
	if cmd_exists gotty; then
		log_g 'gotty is installed'
		return 0
	fi

	setup_golang
	go get github.com/yudai/gotty

	gopath=$(go env GOPATH)
	cp $gopath/bin/gotty /usr/local/bin
}

setup_golang()
{
	if cmd_exists go; then
		log_g 'golang is installed'
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
	if cmd_exists node; then
		log_g "node has been installed"
		return
	fi

	version=${1:-'10'}

	curl -sL https://deb.nodesource.com/setup_${version}.x | sudo -E bash -
	check_apt nodejs
}

setup_ffmpeg3()
{
	if need_ffmpeg 3.3.0; then
		log_y 'need to update ffmpeg'
		apt purge -y ffmpeg 
		check_update ppa:jonathonf/ffmpeg-3
	fi

	check_apt ffmpeg libav-tools x264 x265

	log_g "Now ffmpeg version is: $(ffmpeg_version)"
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

