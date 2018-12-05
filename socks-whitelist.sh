#!/bin/dash

THIS_SCRIPT=$(readlink -f $0)
THIS_DIR=$(dirname $THIS_SCRIPT)

main () 
{
	[ "$1" != 'daemon' ] && install_routine		
	run_nodejs node_socks5_server
}

node_socks5_server()
{
	cat <<-EOL
	const socks = require('socksv5');
	const Redis = require('ioredis');
	const redis = new Redis();

	var srv = socks.createServer((info, accept, deny)=> {
	  console.log(info);
	  accept();
	});

	srv.useAuth(socks.auth.UserPassword((user, pass, cb)=> {
	  redis.hget('userpass',user,(err,res)=>{cb(pass===res);});
	}));

	srv.listen(1080, '0.0.0.0', ()=> {
	  console.log('SOCKS server listening on port 1080');
	});
	EOL
}

run_nodejs()
{
	export NODE_PATH=$(npm list -g 2>/dev/null | head -1)/node_modules

	local node_code="$($1)"
	shift

	echo "$node_code" | node $@
}

install_routine()
{
	local nodeModuls=$(npm list -g 2>/dev/null | head -1)/node_modules

	check_update
	setup_nodejs
	
	check_apt redis-server
	if ! pgrep -x redis-server >/dev/null; then
		systemctl enable redis-server 
		systemctl start redis-server 
	fi

	check_npm_g ioredis
	check_npm_g socksv5
	local authFile=${nodeModuls}/socksv5/lib/auth/UserPassword.js
	if ! grep -q "stream.user=user;" $authFile; then
		sed -i '/stream.write(BUF_FAILURE);/a stream.user=user;' $authFile
	fi

	local serverFile=${nodeModuls}/socksv5/lib/server.js
	if ! grep -q "reqInfo.user=socket.user;" $serverFile; then
		sed -i '/reqInfo.srcPort = socket.remotePort;/a reqInfo.user=socket.user;' $serverFile
	fi
}

apps_handler()
{
	local cmd="$1"; shift
	local username="$1"; shift

	empty_exit "$username" 'user name'
	local setkey=$(echo "usersapps-$username" | tr -d " \t")

	if [ "$cmd" = 'add' ]; then
		empty_exit "$1" 'app name'
		redis-cli sadd $setkey $@
	elif [ "$cmd" = 'remove' ]; then
		if [ -z $1 ]; then
			redis-cli del $setkey
		else
			redis-cli srem $setkey $@
		fi
	fi
}

user_handler()
{
	local cmd="$1"; shift
	local username="$1"; shift

	empty_exit "$username" 'user name'

	if [ "$cmd" = 'add' ]; then
		local password="$1"
		empty_exit "$password" 'user password'
		redis-cli hset userpass "$username" "$password"
	elif [ "$cmd" = 'remove' ]; then
		redis-cli hdel userpass "$username"
		apps_handler remove "$username"
	fi
}

ips_handler()
{
	local cmd="$1"; shift
	local appName="$1"; shift
	empty_exit "$appName" 'app name'

	local setkey=$(echo "appIpaddrs-$appName" | tr -d " \t")

	local ipList=''
	while [ "$1" != '' ]; do
		ipList="$ipList $1"
		shift
	done
	ipList=$(echo "$ipList" | tr -d " \t")

	if [ "$cmd" = 'add' ]; then
		empty_exit "$ipList" 'ip address'
		redis-cli sadd $setkey $ipList

	elif [ "$cmd" = 'remove' ]; then
		if [ -z $ipList ]; then
			redis-cli del $setkey
		else
			redis-cli srem $setkey $ipList
		fi
	fi

	restructure_dist_hash
}

restructure_dist_hash()
{
	IFS=','; set -- $(redis-cli --csv hkeys userpass | tr -d '"')

	while [ "$1" != '' ]; do
		local user="$1"; shift
		local count=$(redis-cli --csv scard "usersapps-$user")

		if [ $count -lt 2 ]; then
			continue
		fi

		IFS=; apps=$(redis-cli --csv smembers "usersapps-$user" |tr -d '"' |tr ',' "\n" |sort|tr -d "\n")
		echo apps-key: $apps
	done


}

maintain()
{
	local cmd="$1"; shift

	[ "$cmd" = 'ipmaps' ]  && restructure_dist_hash $@ && exit 0

	[ "$cmd" = 'ipsadd' ]  && ips_handler add $@ && exit 0
	[ "$cmd" = 'ipsdel' ]  && ips_handler remove $@ && exit 0

	[ "$cmd" = 'appadd' ]  && apps_handler add $@ && exit 0
	[ "$cmd" = 'appdel' ]  && apps_handler remove $@ && exit 0

	[ "$cmd" = 'useradd' ] && user_handler add $@ && exit 0
	[ "$cmd" = 'userdel' ] && user_handler remove $@ && exit 0

	[ "$cmd" = 'install' ] && this_network_service daemon && exit 0
	[ "$cmd" = 'help' ] && show_help_exit
}


#-------------------------------------------------------------------
#--------------------  basic code below  ---------------------------
#-------------------------------------------------------------------

check_update()
{
	check_sudo

	if [ "$1" = 'f' ]; then
		apt update -y
		return 0
	fi

	local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
	local nowtime=`date +%s`
	local diff_time=$(($nowtime-$last_update))
	local repo_changed=0

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log_yellow "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi
}

install_service_exit()
{
	install_routine
	this_network_service daemon
	exit 0
}

show_help_exit()
{
	local this_file=$(basename $THIS_SCRIPT)
	cat <<- EOL
	  sh ${this_file} install	; install as systemd service
	  sh ${this_file} help  	; show this print
	EOL
	exit 0
}

setup_nodejs()
{
	if cmd_exists node; then
		log_green "node has been installed"
		return
	fi

	local version=${1:-'10'}

	curl -sL https://deb.nodesource.com/setup_${version}.x | sudo -E bash -
	check_apt nodejs
}

log()  	     { echo "$@"; }
log_red()    { echo "\033[0;31m$*\033[0m"; }
log_green()  { echo "\033[0;32m$*\033[0m"; }
log_yellow() { echo "\033[0;33m$*\033[0m"; }
cmd_exists() { type "$(which "$1")" > /dev/null 2>&1; }
apt_exists() { [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]; }
check_sudo() { [ $(whoami) != 'root' ] && log_red "Must be run as root" && exit 1; }
check_apt()  { for p in "$@";do if apt_exists $p;then log_green "$p installed.";else apt install -y $p;fi done; }
check_bash() { [ -z "$BASH_VERSION" ] && log_yellow "Change to: bash $0" && setsid bash $0 $@ && exit; }
check_npm_g(){ if npm list -g "$1" >/dev/null;then log_green "$1 installed.";else npm install -g "$1"; fi; }
empty_exit() { [ -z $1 ] && log_red "ERROR. the $2 is invalid." && exit 1; }

this_network_service()
{
	check_sudo

	local this_param="$1"
	local this_script=$(readlink -f $0)
	local this_file=$(basename $this_script)
	local this_name=${this_file%.*}

	cat > /lib/systemd/system/${this_name}.service <<- EOL
	[Unit]
	Description=Service For ${this_file}
	After=network.target

	[Service]
	ExecStart=/bin/dash ${this_script} ${this_param}
	Restart=always

	[Install]
	WantedBy=multi-user.target
	EOL

	systemctl enable ${this_name}
	systemctl start ${this_name}
}

maintain "$@"; main "$@"; exit $?
