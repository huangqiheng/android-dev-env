#!/bin/dash

THIS_SCRIPT=$(readlink -f $0)
THIS_DIR=$(dirname $THIS_SCRIPT)

main () 
{
	[ "$1" != 'daemon' ] && install_routine		

	export NODE_PATH=$(npm list -g 2>/dev/null | head -1)/node_modules
	echo "$(genNodeCode)" | node
}

genNodeCode()
{
	cat <<EOL
var socks = require('socksv5');
var Redis = require('ioredis');
var redis = new Redis();

var srv = socks.createServer(function(info, accept, deny) {
  accept();
});
srv.listen(1080, 'localhost', function() {
  console.log('SOCKS server listening on port 1080');
});

srv.useAuth(socks.auth.None());
EOL
}

install_routine()
{
	check_update
	setup_nodejs
	check_apt redis-server
	check_npm_g socksv5 ioredis
}

#-------------------------------------------------------------------
#-------------------- basic code below -----------------------------
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

maintain()
{
	[ "$1" = 'install' ] && this_network_service daemon
	[ "$1" = 'help' ] && show_help_exit $2
}

show_help_exit()
{
	local this_file=$(basename $THIS_SCRIPT)
	cat << EOL
  sh ${this_file} install	; install as systemd service
  sh ${this_file} help		; show this print
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

this_network_service()
{
	check_sudo

	local this_param="$1"
	local this_script=$(readlink -f $0)
	local this_file=$(basename $this_script)
	local this_name=${this_file%.*}

	cat > /lib/systemd/system/${this_name}.service <<EOL
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
