#!/bin/sh

export_router_config()
{
	check_apt lshw

	if [ -z $WAN_IFACE ]; then
		WAN_IFACE=$(route | grep '^default' | grep -o '[^ ]*$')
	fi

	if [ -z $LAN_IFACE ]; then
		LAN_IFACE=$(lshw -quiet -c network | sed -n -e '/Ethernet interface/,+12 p' | sed -n -e '/bus info:/,+5 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g' | grep -v "$WAN_IFACE" | head -1)
		def_gateway=$(ifconfig | grep -A1 "$LAN_IFACE" | grep "inet " | head -1 | awk -F' ' '{print $2}')
	fi

	if [ -z $GATEWAY ]; then
		GATEWAY="${def_gateway:-192.168.234.1}"
	fi

	export WAN_IFACE="${WAN_IFACE}"
	export LAN_IFACE="${LAN_IFACE}"
	export GATEWAY="${GATEWAY}"
	export SUBNET="${GATEWAY%.*}.0/24"
	log_y "Config: WAN=$WAN_IFACE LAN=$LAN_IFACE GATE=$GATEWAY NET=$SUBNET"
}


setup_resolvconf()
{
	if systemctl is-active systemd-resolved; then
		systemctl stop systemd-resolved
	fi
	if systemctl is-enabled systemd-resolved; then
		systemctl disable systemd-resolved
	fi
	check_apt resolvconf

	cat > /etc/resolv.conf <<-EOF
	nameserver 8.8.8.8
	nameserver 114.114.114.114
EOF
}

check_ssserver_conf()
{
	check_apt jq
	local confile="$1"
	mkdir -p $(dirname $confile)

	if [ ! -f "$confile" ]; then
		make_ssserver_conf $confile
		return 0
	fi

	inputServer=$(cat $confile | jq -c '.server' | tr -d '"')
	if [ "X$inputServer" = 'X' ]; then
		make_ssserver_conf $confile
	fi

	inputPassword=$(cat $confile | jq -c '.password' | tr -d '"')
	if [ "X$inputPassword" = 'X' ]; then
		make_ssserver_conf $confile
	fi
}

make_ssserver_conf()
{
	local confile="$1"
	read -p 'Input Shadowsocks SERVER: ' SSSERVER
	read -p 'Input Shadowsocks PASSWORD: ' SSPASSWORD
	cat > "$confile" <<EOL
{
	"server":"${SSSERVER}",
	"password":"${SSPASSWORD}",
        "mode":"tcp_and_udp",
        "server_port":16666,
        "local_address": "0.0.0.0",
        "local_port":6666,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL
}


install_chinadns()
{
	if  cmd_exists 'chinadns'; then
		log_y 'chinadns is ready'
		return
	fi

	check_apt build-essential

	local chinadns=chinadns-1.3.2
	cd $CACHE_DIR
	if [ ! -f ${chinadns}.tar.gz ]; then
		wget https://github.com/shadowsocks/ChinaDNS/releases/download/1.3.2/${chinadns}.tar.gz
	fi
	tar xf ${chinadns}.tar.gz
	cd ${chinadns}
	./configure
	make && make install
}

install_ssredir()
{
	check_apt haveged rng-tools shadowsocks-libev

	if [ ! -f /etc/shadowsocks-libev/bwghost.json ]; then
		read -p "Please input Shadowsocks server: " inputServer 

		if [ -z "$inputServer" ]; then
			log 'inputed server error'
			exit 1
		fi

		read -p "Input PASSWORD: " inputPass

		if [ -z "$inputPass" ]; then
			log 'pasword must be set'
			exit 2
		fi

		cat > /etc/shadowsocks-libev/bwghost.json <<EOL
{
	"server":"${inputServer}",
	"password":"${inputPass}",
        "mode":"tcp_and_udp",
        "server_port":16666,
        "local_address": "0.0.0.0",
        "local_port":6666,
        "method":"xchacha20-ietf-poly1305",
        "timeout":300,
        "fast_open":false
}
EOL
	else
		inputServer=$(grep '"server":' /etc/shadowsocks-libev/bwghost.json | tr '":,' ' ' | awk -F' ' '{print $2}')
	fi

	log_y "shadowsocks server: $inputServer"

	systemctl enable shadowsocks-libev-redir@bwghost
	systemctl daemon-reload
	systemctl start shadowsocks-libev-redir@bwghost
}


install_terminals()
{
	check_apt xterm 
	check_apt lxterminal
	check_apt tmux

	# xrdb -merge ~/.Xresources
	# Ctrl-Right mouse click for temporary change of font size
	# select to copy, and shift+insert or shift+middleClick to paste
	cat > ${UHOME}/.Xresources <<-EOL
	XTerm*utf8:true
	XTerm*utf8Title:true
	XTerm*cjkWidth:true
	XTerm*faceName:DejaVu Sans Mono:pixelsize=12
	XTerm*faceNameDoublesize:WenQuanYi Zen Hei Mono:pixelsize=13
	XTerm*selectToClipboard:true
	XTerm*inputMethod:fcitx
EOL 
	chownUser ${UHOME}/.Xresources
	xinitrc "xrdb -merge ${UHOME}/.Xresources"
}

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
	cat > $UHOME/.ssh/config <<EOL
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

setup_github_go()
{
	local owner="$1"
	local cmd="$2"

	empty_exit $owner 'github owner' 

	if [ "X$cmd" = 'X' ]; then
		IFS=/; set -- $(echo "$owner"); IFS=
		owner="$1"
		cmd="$2"
	fi

	empty_exit $cmd 'github repo' 

	if cmd_exists "$cmd"; then
		log_g "$cmd has been installed"
		return 0
	fi

	setup_golang
	go get "github.com/$owner/$cmd"

	gopath=$(go env GOPATH)

	local cmdPath="$gopath/bin/$cmd"
	if [ -f "$cmdPath" ]; then
		ln -sf "$cmdPath" /usr/local/bin/
		return 0
	else
		log_r "$cmd install failure"
		return 1
	fi
}

setup_pup()
{
	setup_github_go ericchiang pup
}

setup_gotty()
{
	setup_github_go yudai gotty
}

setup_golang()
{
	if cmd_exists go; then
		log_g 'golang is installed'
		return 0
	fi

	if [ "$1" = "" ]; then
		if ! apt_exists golang-go; then
			check_update ppa:longsleep/golang-backports
		fi
		check_apt golang-go
		return 1
	fi

	cd $CACHE_DIR
	wget https://dl.google.com/go/go${1}.linux-amd64.tar.gz
	tar -C /usr/local -xzf go${1}.linux-amd64.tar.gz
	echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
	echo 'export PATH=$PATH:$UHOME/go/bin' >> /etc/profile

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

