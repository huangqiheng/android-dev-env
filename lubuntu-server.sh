#!/bin/bash

ROOT_DIR=`dirname $(readlink -f $0)`

main () 
{
	check_update
	lubuntu_desktop
	setup_shadowsocks
	astrill_vpn
	setup_chrome
}

setup_shadowsocks()
{
	if cmd_exists /usr/bin/ss-qt5; then
		echo "shadowsocks-qt5 has been installed."
		return
	fi

	the_ppa=hzwhuang/ss-qt5

	if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
		add-apt-repository -y ppa:$the_ppa
		apt update -y
	fi

	apt install -y shadowsocks-qt5
}

setup_chrome()
{
	if cmd_exists /opt/google/chrome/chrome; then
		echo "chrome has been installed."
		return
	fi

	wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
	sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
	apt update -y
	apt install -y google-chrome-stable
}

astrill_vpn()
{
	if cmd_exists /usr/local/Astrill/astrill; then
		echo "astrill has been installed."
		return
	fi

	cd $ROOT_DIR
	mkdir -p temp && cd temp

	if [ ! -f "astrill-setup-linux64.sh" ]; then
		wget https://astrill4u.com/downloads/astrill-setup-linux64.sh
	fi

	set_comt $ROOT_DIR/temp/astrill-setup-linux64.sh
	set_comt off '#' 'read x'

	bash astrill-setup-linux64.sh
}

lubuntu_desktop()
{
	if $(dpkg -L lubuntu-core 2>&1 | grep -q "not installed"); then
		apt install -y lubuntu-core --no-install-recommends
	else
		echo "lubuntu-core has been installed."
	fi

	systemctl set-default multi-user.target
	# systemctl start/stop lightdm
	# ctrl + alt + f1-f6	to terminal
	# ctrl + alt + f7	to graphics
	
	check_apt lxterminal putty 
	check_apt fonts-wqy-zenhei fcitx-googlepinyin
}


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
			echo "${package} has been installed"
		fi
	done
}

__comment_file=''

set_comt()
{
	num_param=$#
	if [ $num_param -eq 1 ]; then
		__comment_file=$1
		return
	fi

	if [ -z $__comment_file ]; then
		echo 'toggle_comment(): Please set ini file first.'
		exit
	fi

	if [ "$1" = "on" ]; then
		sed -ri "s|^[${2} \t]*(${3}.*)|\1|" $__comment_file
	else
		sed -ri "s|^[ \t]*(${3}.*)|${2}\1|" $__comment_file
	fi
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
