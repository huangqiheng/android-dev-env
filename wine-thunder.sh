#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	dpkg --add-architecture i386 
	check_update f
	check_apt wine-stable  wine32
	check_apt winetricks

	if [ $(winetricks apps list-installed | grep -c fakechinese) -eq 0 ]; then
		winetricks fakechinese
	fi

	if [ ! -d $RUN_DIR/wine-thunder-for-linux ]; then
		tar xzvf wine-thunder-for-linux.tar.gz -C $RUN_DIR
		chownUser wine-thunder-for-linux
	fi

	if [ ! -d $UHOME/download ]; then
		mkdir -p $UHOME/download
		chownUser $UHOME/download
	fi

	cd $RUN_DIR/wine-thunder-for-linux

	if cmd_exists wine; then
		extract_bin wine
		return 0
	fi

	if cmd_exists wine32; then
		extract_bin wine32
		return 0
	fi

	log_r 'wine is not installed'
}

extract_bin()
{
	cat > /usr/local/bin/thunder <<-EOF
	#!/bin/bash
	cd $RUN_DIR/wine-thunder-for-linux
	env LANG=zh_CN.GB18030 $1 Thunder.exe
EOF
	chmod a+x /usr/local/bin/thunder
	log_y "Please run \"$thunder\" to open thunder"
}

install_wine()
{
	wget -nc https://dl.winehq.org/wine-builds/Release.key
	apt-key add Release.key
	apt-add-repository https://dl.winehq.org/wine-builds/ubuntu/
	check_update f
	apt-get install --install-recommends winehq-stable
}

maintain()
{
	check_update
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
