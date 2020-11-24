#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $ROOT_DIR/setup_routines.sh

main () 
{
	if [ "$1" != 'daemon' ]; then
		setup_nodejs
		check_npm_g proxy-pac-proxy
		check_npm_g http-server

		cd $DATA_DIR 
		if [ ! -f gfwlist.pac ]; then
			#wget https://github.com/MatcherAny/whitelist.pac/raw/master/whitelist.pac
			wget https://raw.githubusercontent.com/petronny/gfwlist2pac/master/gfwlist.pac
		fi
	fi

	if [ "$1" = 'install' ]; then
		cat > /lib/systemd/system/pacproxy.service <<- EOL
		[Unit]
		Description=Pac Http Proxy Server
		After=network.target

		[Service]
		ExecStart=/bin/dash ${ROOT_DIR}/pac-proxy.sh daemon
		Restart=always

		[Install]
		WantedBy=multi-user.target
EOL
		systemctl enable pacproxy
		systemctl start pacproxy
		exit 0
	fi

	hostIpAddr='127.0.0.1'
	hostPort='3213'
	if [ ! -z $1 ]; then 
		foundIP=$(ping -q -c 1 -t 1 $1 | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
		if [ ! -z $foundIP ]; then
			hostIpAddr=$foundIP
			if [ ! -z $2 ]; then
				hostPort="$2"
			fi
		fi
	fi

	unixSocket=/var/run/pac-proxy.socket
	unlink $unixSocket 2>/dev/null

	export NODE_PATH=$(npm list -g 2>/dev/null | head -1)/node_modules
	echo "$(genNodeCode $unixSocket)" | node &

	export PROXYPACPROXY_URL="http://unix:${unixSocket}:/wlist.pac?proxy=${hostIpAddr}&port=${hostPort}"
	proxy-pac-proxy start --address 0.0.0.0 --port 8080 --foreground true
}

genNodeCode()
{
	cat <<EOL
const fs = require('fs');
const url = require('url');
require('http-server').createServer({
  root: '${DATA_DIR}',
  before: [ (req, res)=>{
    if (url.parse(req.url).pathname === '/wlist.pac') {
	console.log('req.url = '+req.url);
	var proxy = req.headers.host+':3128';
	req.query.proxy && (proxy = req.query.proxy+':'+req.query.port);
	fs.readFile('${DATA_DIR}/gfwlist.pac', 'utf8', (err,data)=> {
	  res.setHeader('Content-Type', 'application/javascript');
	  return res.end(data.replace(/127.0.0.1:1080/, proxy));
	});
	return;
    }
    res.emit('next');
}]}).listen('${1}');
EOL
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
