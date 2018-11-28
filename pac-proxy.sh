#!/bin/dash

. $(dirname $(readlink -f $0))/basic_functions.sh
. $THIS_DIR/setup_routines.sh

main () 
{
	setup_nodejs
	check_npm_g proxy-pac-proxy
	check_npm_g http-server

	cd $DATA_DIR 
	if [ ! -f whitelist.pac ]; then
		wget https://github.com/MatcherAny/whitelist.pac/raw/master/whitelist.pac
	fi

	unixSocket='/var/run/pac-proxy.socket'

	#/* Pattern */ 'http://unix:SOCKET:PATH'
	#/* Example */ request.get('http://unix:/absolute/path/to/unix.socket:/request/path')

	export NODE_PATH=/usr/local/lib/node_modules
       	node <<EOL
const fs = require('fs');
const url = require('url');
require('http-server').createServer({
  root: '${DATA_DIR}',
  before: [ (req, res)=>{
    if (url.parse(req.url).pathname === '/wlist.pac') {
	console.log('req.url = '+req.url);
	var proxy = req.headers.host+'3128';
	req.query.proxy && (proxy = req.query.proxy);
	fs.readFile('${DATA_DIR}/whitelist.pac', 'utf8', (err,data)=> {
	  res.setHeader('Content-Type', 'application/javascript');
	  return res.end(data.replace(/127.0.0.1:1080/, proxy));
	});
	return;
    }
    res.emit('next');
}]}).listen(${unixSocket});
EOL 

	export PROXYPACPROXY_URL="http://unix:${unixSocket}:/wlist.pac?proxy=192.168.1.20:3128"
	export PROXYPACPROXY_URL=http://localhost/wlist.pac?proxy=192.168.1.20:3128
	proxy-pac-proxy start --address 0.0.0.0 --port 8080 --foreground true
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
