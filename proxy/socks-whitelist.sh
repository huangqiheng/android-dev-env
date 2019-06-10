#!/bin/dash

. $ROOT_DIR/basic_mini.sh

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
	  let isDone=false;
	  redis.smembers('usersapps-'+info.user).then(apps=>{
	    if (apps.length===0) {
	    	deny();
		console.log('DENY for missing apps setting');
		return;
	    }
	    let counter=apps.length;
	    apps.forEach(app=>{
		if (isDone){ 
		  checkDone();
		  return; 
		}
		redis.sismember('appIpaddrs-'+app, info.dstAddr).then(res=>{
		    console.log(' -- check '+info.dstAddr+' in '+app+' : '+res);
		    if (!isDone && (res === 1)) {
		    	console.log('ACCEPT '+info.dstAddr+' by '+app);
		    	accept();
			isDone=true;
		    }
		    checkDone();
	 	});
	    });
	    function checkDone(){
		if (--counter===0) {
		  console.log(' -- all request done');
		  if (!isDone) {
		    deny();
		    console.log('DENY by no matching '+info.dstAddr);
		  }
	    	}
	    }
	  });
	});

	srv.useAuth(socks.auth.UserPassword((user, pass, cb)=> {
	  redis.hget('userpass',user,(err,res)=>{cb(pass===res);});
	}));

	srv.listen(1080, '0.0.0.0', ()=> {
	  console.log('SOCKS server listening on port 1080');
	});
	EOL
}

process_export()
{
	local toFile=
	local isViewUser=false
	local isViewApps=false

	if [ "$1" = 'user' ]; then
		isViewUser=true
	elif [ "$1" = 'apps' ]; then
		isViewApps=true
	elif [ "$1" = 'all' ]; then
		isViewUser=true
		isViewApps=true
	else
		local inputFile="$1"
		if [ -z $inputFile ]; then
			local this_file=$(basename $BASIC_SCRIPT)
			inputFile="$UHOME/${this_file%.*}.json"
		fi
		if touch "$inputFile" 2>/dev/null; then
			toFile="$inputFile"
		else
			return
		fi
	fi

	local redisCmd_apps='del usersapps-union'
	local userList_json=''
	local ipList_json=''

	LOGFLAG=; [ "$isViewUser" != 'true' ] && LOGFLAG='off'
	log 'Show all users:'

	IFS=','; set -- $(redis-cli --csv hgetall userpass | tr -d '"')
	while [ "$1" != '' ]; do
		local user="$1"; shift
		local pass="$1"; shift

		local apps=''
		IFS=','; for app in $(redis-cli --csv smembers "usersapps-$user" | tr -d '"'); do
			redisCmd_apps="$redisCmd_apps\nsadd usersapps-union $app"
			if [ -z "$apps" ]; then apps="\"$app\""; else apps="$apps,\"$app\""; fi
		done; 
		log "  user=$user, pass=$pass, apps=$apps"
		userList_json="$userList_json,{\"id\":\"$user\",\"pass\":\"$pass\",\"apps\":[$apps]}"
	done

	echo "$redisCmd_apps" | redis-cli >/dev/null
	IFS=; local appList=$(redis-cli --csv smembers usersapps-union | tr -d '"' 2>/dev/null)
	redis-cli del usersapps-union >/dev/null

	LOGFLAG=; [ "$isViewApps" != 'true' ] && LOGFLAG='off'
	log 'Show all whitelist ip address:'

	IFS=','; for app in $appList; do
		IFS=; local whitelist=$(redis-cli --csv smembers "appIpaddrs-$app")
		log "  $app: $whitelist"
		ipList_json="$ipList_json,\"$app\":[$whitelist]"
	done

	if test -w "$toFile"; then
		IFS=; 
		local usersItem=$(echo $userList_json | cut -c 2-)
		local whitelistItem=$(echo $ipList_json | cut -c 2-)
		local outputJson="{\"userpass\":[$usersItem],\"whitelist\":{$whitelistItem}}"

		echo $outputJson | jq '.' > "$toFile"
	fi
}

process_import()
{
	local fromFile="$1"
	local redisCmds=''

	IFS='
';	for user in $(cat "$fromFile" | jq -c '.userpass[]'); do
		local id=$(echo $user | jq -r '.id')
		local pass=$(echo $user | jq -r '.pass')
		IFS=; local apps=$(echo $user | jq -r '.apps[]' | tr "\n" ' ')
		echo $id:$pass $apps
		redisCmds="$redisCmds\nhset userpass $id $pass"
		if [ ! -z $apps ]; then
		       redisCmds="$redisCmds\nsadd usersapps-$id $apps"
		fi	 
	done

	IFS='
';	set -- $(cat "$fromFile" | jq -r '.whitelist | to_entries[] | [.key],.value | join(" ")')
	while [ "$1" != '' ]; do
		local app="$1"; shift
		local ips="$1"; shift
		echo $app = $ips
		redisCmds="$redisCmds\nsadd appIpaddrs-$app $ips"
	done

	echo "$redisCmds" | redis-cli >/dev/null 
}

run_nodejs()
{
	export NODE_PATH=$(npm list -g 2>/dev/null | head -1)/node_modules

	local node_code="$($1)"
	shift

	echo "$node_code" | node - $@
}

install_routine()
{
	local nodeModuls=$(npm list -g 2>/dev/null | head -1)/node_modules

	check_update
	setup_nodejs
	check_apt jq
	
	check_apt redis-server
	if ! pgrep -x redis-server >/dev/null; then
		systemctl enable redis-server 
		systemctl start redis-server 
	fi

	check_npm_g ioredis socksv5 

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

	echo $relates

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
}

list_infos()
{
	local target="$1"; 
	[ -z $1 ] || shift

	case $target in
	u|user)
		process_export user
		;;
	a|apps)
		process_export apps
		;;
	*|all)
		process_export all
		;;
	esac
}

maintain()
{
	[ -z $1 ] && return
	local cmd="$1"; shift

	[ "$cmd" = 'flush' ]  && redis-cli flushdb  && exit 0
	[ "$cmd" = 'ls' ]  && list_infos $@ && exit 0

	[ "$cmd" = 'ipsadd' ]  && ips_handler add $@ && exit 0
	[ "$cmd" = 'ipsdel' ]  && ips_handler remove $@ && exit 0

	[ "$cmd" = 'appadd' ]  && apps_handler add $@ && exit 0
	[ "$cmd" = 'appdel' ]  && apps_handler remove $@ && exit 0

	[ "$cmd" = 'useradd' ] && user_handler add $@ && exit 0
	[ "$cmd" = 'userdel' ] && user_handler remove $@ && exit 0

	[ "$cmd" = 'import' ] && process_import $@ && exit 0
	[ "$cmd" = 'export' ] && process_export $@ && exit 0
	[ "$cmd" = 'install' ] && this_network_service daemon && exit 0
	[ "$cmd" = 'help' ] && show_help_exit
}

install_service_exit()
{
	install_routine
	this_network_service daemon
	exit 0
}

show_help_exit()
{
	local this_file=$(basename $BASIC_SCRIPT)
	cat <<- EOL
	  sh ${this_file} install	; install as systemd service
	  sh ${this_file} help  	; show this print
	EOL
	exit 0
}

setup_nodejs()
{
	if cmd_exists node; then
		log_g "node has been installed"
		return
	fi

	local version=${1:-'10'}

	curl -sL https://deb.nodesource.com/setup_${version}.x | sudo -E bash -
	check_apt nodejs
}


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
