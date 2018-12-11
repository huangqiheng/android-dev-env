#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	check_update
	check_apt vim-common
	check_apt git curl build-essential libssl-dev zlib1g-dev

	cd $CACHE_DIR
	if [ ! -d MTProxy ]; then
		git clone https://github.com/TelegramMessenger/MTProxy
	fi
	cd MTProxy

	if [ ! -f objs/bin/mtproto-proxy ]; then
		make 
	fi
	cd objs/bin

	if [ ! -f proxy-secret ]; then
		curl -s https://core.telegram.org/getProxySecret -o proxy-secret
	fi

	if [ ! -f proxy-multi.conf ]; then
		curl -s https://core.telegram.org/getProxyConfig -o proxy-multi.conf
	fi

	if [ ! -f client-secret ]; then
		gen_new_secret
	fi

	run
}

gen_new_secret()
{
	cd $CACHE_DIR/MTProxy/objs/bin
	local secret=$(head -c 16 /dev/urandom | xxd -ps)
	echo "$secret" > client-secret
	chown root:root client-secret
	chmod 600 client-secret
}

run()
{
	cd $CACHE_DIR/MTProxy/objs/bin
	local secret=$(cat client-secret)
	./mtproto-proxy -u nobody -p 8888 -H 443 -S "$secret" --aes-pwd proxy-secret proxy-multi.conf -M 1
	return 0
}

update_secret()
{
	gen_new_secret
	systemctl restart mtproxy
	return 0
}

regist_service()
{
	local sh=$(which sh)
	local serviceFile=/etc/systemd/system/mtproxy.service
	if [ ! -f "$serviceFile" ]; then
		cat > "$serviceFile" <<-EOL
		[Unit]
		Description=MTProxy
		After=network.target

		[Service]
		Type=simple
		ExecStart=${sh} ${THIS_DIR}/mtproxy.sh daemon
		Restart=on-failure

		[Install]
		WantedBy=multi-user.target
EOL
		systemctl enable mtproxy.service
	fi

	systemctl start mtproxy
	return 0
}

share()
{
	local IP=$(curl -4 -s ip.sb)
	cd $CACHE_DIR/MTProxy/objs/bin
	local secret=$(cat client-secret)
	echo "tg://proxy?server=${IP}&port=443&secret=${secret}"
}

maintain()
{
	[ "$1" = 'share' ] && share && exit
	[ "$1" = 'daemon' ] && run && exit
	[ "$1" = 'new' ] && update_secret && exit
	[ "$1" = 'service' ] && regist_service && exit
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	cat << EOL

EOL
	exit 0
}
maintain "$@"; main "$@"; exit $?
