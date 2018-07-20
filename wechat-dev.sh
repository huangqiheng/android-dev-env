#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

main () 
{
	cd $DATA_DIR

	wxdtCmd=$DATA_DIR/wechat_web_devtools/bin/wxdt
	if [ ! -f  $wxdtCmd ]; then
		git clone https://github.com/huangqiheng/wechat_web_devtools.git

		if [ ! -f  $wxdtCmd ]; then
			log "get debtools error"
			rm -rf $DATA_DIR/wechat_web_devtools/dist
			rm -rf /tmp/wxdt_xsp
			exit 1
		fi
	fi

	cd $DATA_DIR/wechat_web_devtools

	install_wine
	update-binfmt --import /usr/share/binfmts/wine

	sh bin/wxdt install

	log "run cmd: sh $wxdtCmd"
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
