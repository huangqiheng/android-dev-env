#!/bin/dash

ORIARGS="$0 $*"
export BASIC_SCRIPT=$(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; echo $(readlink -f $f))
export ROOT_DIR=$(dirname $BASIC_SCRIPT)
export EXEC_SCRIPT=$(readlink -f $0)
export EXEC_DIR=$(dirname $EXEC_SCRIPT)
export CACHE_DIR=$ROOT_DIR/cache
export DATA_DIR=$ROOT_DIR/data
export UHOME=$HOME; [ "X$SUDO_USER" != 'X' ] && UHOME="/home/$SUDO_USER"
export RUN_DIR=$UHOME/runCodes
export RUN_USER=$(basename $UHOME)

[ -f $ROOT_DIR/config.sh ] &&  . $ROOT_DIR/config.sh
[ -f $EXEC_DIR/config.sh ] &&  . $EXEC_DIR/config.sh
[ -f $EXEC_DIR/functions.sh ] &&  . $EXEC_DIR/functions.sh

mkdir -p $CACHE_DIR
mkdir -p $RUN_DIR

cd $EXEC_DIR

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

# -- ssh_remote_exec 'apt|repo' (apt apt2 apt3 apt4'|repo1 repo2 repo3)
# -- ssh_remote_exec '^##BEGIN-BLOCK' '^##END-BLOCK' ['/path/to/self/script']
# -- ssh_remote_exec 'ssh@host.name[:22]'
ssh_remote_run()
{
	[ $# -eq 0 ] && return

	if [ "$SSHREMOTE_script" = '' ]; then
		SSHREMOTE_script="#!/bin/dash\n"
	fi

	# install apt or repo

	if echo "$1" | grep -q "apt\|repo"; then
		local opt="$1"
		local arg_begin=$((${#1}+1))
		IFS=' '; set -- $(echo "$*" | cut -c ${arg_begin}- | sed 's/^[ \t]*//;s/[ \t]*$//')

		for package; do
			if [ "$opt" = 'apt' ]; then
				SSHREMOTE_script="${SSHREMOTE_script}apt install -y ${package}\n"
			else
				SSHREMOTE_script="${SSHREMOTE_script}add-apt-repository -y ${package}\n"
			fi
		done

		if [ "$opt" = 'repo' ]; then
			SSHREMOTE_script="${SSHREMOTE_script}apt update -y\n"
		fi

		echo $SSHREMOTE_script
		return 0
	fi

	# exec the script on remote ssh

	if [ $# -eq 1 ]; then
		IFS='@:'; set -- $(echo "$1")
		local sshUser="$1"
		local sshHost="$2"
		local sshPort=${3:-'22'}
		local sshAddr=$(ping -q -c 1 -t 1 $sshHost 2>/dev/null | grep PING | sed -e "s/).*//;s/.*(//")

		if [ "$sshAddr" = '' ]; then
			log_red "ERR: the input ip addr invalid."
			exit 1
		fi

		local end_str="\nrm -- \"\$0\""
		SSHREMOTE_script="${SSHREMOTE_script}\n$end_str"

		#tar cz a/dir | pv | ssh remotehost "cat >outfile.tar.gz"
		return 0
	fi

	# generat dash shell

	local Mark_Begin="$1"; 
	local Mark_End="$2"
	local this_script=$(readlink -f $0)
	local Mark_file="${3:-$this_script}"

	if [ ${Mark_Begin%"${Mark_Begin#?}"} != '#' ] || [ ${Mark_End%"${Mark_End#?}"} != '#' ]; then
		log_red "ERR: the input tag format invalid."
		exit 1
	fi

	local lineBegin=$(awk "/^${Mark_Begin}/{print NR; exit}" $Mark_file)
	local lineEnd=$(awk "/^${Mark_End}/{print NR; exit}" $Mark_file)
	IFS=; script=$(sed -n "${lineBegin},${lineEnd}p" $Mark_file)

	SSHREMOTE_script="${SSHREMOTE_script}\n${script}\n"
}

cacheit()
{
	CacheitName=$(basename "$1")
	cd $CACHE_DIR

	if [ ! -f "$CacheitName" ]; then
		wget "$1"
	fi

	if [ ! -f "$CacheitName" ]; then
		log_r "cacheit Error: $1"
		exit 1
	fi
}

is_range()
{
	[ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null
	if [ $? -ne 0 ]; then
		return 1
	fi

	if [ "$1" -lt "$2" ] || [ "$1" -gt "$3" ]; then
		return 2
	fi
	return 0
}

is_apmode()
{
	local PHY=$(cat /sys/class/net/${1}/phy80211/name)
	$(iw phy "$PHY" info | grep -qE "^\s+\* AP$")
}

check_apmode()
{
	local PHY=$(cat /sys/class/net/${1}/phy80211/name)
	if ! iw phy "$PHY" info | grep -qE "^\s+\* AP$"; then
		log_r "Wireless card doesn't support AP mode."
		exit 1
	fi
}

daily_exec() 
{
	check_sudo
	set_cmdline dailyexec
	set_cmdline "$@" 

	handle_rc '/etc/crontab' dailyexec "44 4 * * * /usr/local/bin/dailyexec"
}


waitfor_die()
{
	sleep infinity &
	CHILD=$!

	if [ ! "X$1" = 'X' ]; then
		trap "${1}; kill -TERM $CHILD 2> /dev/null" INT TERM KILL
	fi

	wait "$CHILD"
}

__cmdline_file=''
__cmdline_name=''

set_cmdline()
{
	local num_param=$#
	if [ -z $__cmdline_file ]; then
		if [ $num_param -eq 1 ]; then
			__cmdline_name="$1"
			__cmdline_file="/usr/local/bin/$1"
			return
		else
			log_r 'set_cmdline(): Please set ini file first.'
			exit
		fi
	fi

	if ! cmd_exists "$__cmdline_name"; then
		make_cmdline "$__cmdline_name" <<-EOF
		#!/bin/dash
EOF
	fi

	stuffed_line "$__cmdline_file" "$@" 
}

check_cmdline()
{
	if cmd_exists "$1"; then
		return
	fi
	cat /dev/stdin | make_cmdline "$1"
}

make_cmdline()
{
	local inputScript="$(cat /dev/stdin)"
	rm -f "/usr/local/bin/$1"
	echo "$inputScript" > "/usr/local/bin/$1"
	chmod a+x "/usr/local/bin/$1"
	log_y "Extracts script \"$1\" to /usr/local/bin, for easy run."
}

sshhost_parse()
{
	SSH_sshHost="$1"
	IFS='@:'; set -- $(echo "$SSH_sshHost")

	SSH_username="$1"
	SSH_hostname="$2"
	SSH_portnumb="$3"
	SSH_hostip=$(ping -q -c 1 -t 1 $SSH_hostname | grep PING | sed -e "s/).*//" | sed -e "s/.*(//")
}

get_wifi_ifaces()
{
	lshw -quiet -c network | grep -i 'Wireless interface' -A 12 | grep -i 'configuration' -B 12 | grep 'logical name:' | cut -d: -f2 | sed -e 's/ //g'
}

iface_to_driver()
{
	lshw -quiet -c network 2>/dev/null \
		| grep -i 'wireless interface' -A 12 \
		| grep -i 'configuration' -B 12 \
	       	| grep "$1" -A 12 \
		| grep -i 'configuration' -B 12 \
		| grep -P 'driver=(\w+)' -o \
		| cut -d= -f2
}

iface_to_mac()
{
	ifconfig "$1" | awk '/ether/{print $2}'
}

iface_list()
{
	ifconfig -s | tail -n +2 | awk '{print $1}' | grep -v 'lo'
}

ipaddr_list()
{
	for iface in $(iface_list); do
		arp-scan --interface=$iface --localnet 2>/dev/null | awk '{print $1}' | tail -n +3 | head -n -2
	done
}


ipaddr_to_iface()
{
	ifconfig | grep -B1 "$1" | grep -o "^\w*"
}

iface_to_ipaddr()
{
	ifconfig | grep -A1 "$1" | grep "inet " | head -1 | awk -F' ' '{print $2}'
}

wlan_ip()
{
	local wan_iface=$(route | grep '^default' | grep -o '[^ ]*$')
	ifconfig | grep -A1 "$wan_iface" | grep "inet " | head -1 | awk -F' ' '{print $2}'
}

runUser()
{
	runuser -l $RUN_USER -c "$1"
}

chownUser()
{
	chown -R $RUN_USER:$RUN_USER $1
}

chownHome()
{
	chown -R $RUN_USER:$RUN_USER $UHOME
}

public_ip()
{
	curl -4 icanhazip.com
}

# $1="creationix/nvm"
get_latest_release()  {
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
}

stuffed_line()
{
	local echo_file="$1"; shift
	mkdir -p $(dirname "$echo_file")
	params=$(echo "$@")

	if grep -iq "$params" $echo_file; then
		return 1
	fi
	echo "$params" >> $echo_file
}

handle_rc_h()
{
	local echo_file="$1"; shift
	mkdir -p $(dirname "$echo_file")
	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo -e "$2\n$(cat "$echo_file")" > "$echo_file"
}

handle_rc()
{
	local echo_file="$1"; shift
	mkdir -p $(dirname "$echo_file")
	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo "$2" >> $echo_file
}

xinitrc() { handle_rc "$UHOME/.xinitrc" "$1" "$2"; }
bashrc()  { handle_rc "$UHOME/.bashrc" "$1" "$2"; }

ratpoisonrc_done()
{
	chownUser $UHOME/.ratpoisonrc
}

ratpoisonrc()
{
	echo_file=$UHOME/.ratpoisonrc

	if [ ! -f $echo_file ]; then
		touch $echo_file
	fi

	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo "$1" >> $echo_file
}

__crudini_file=''

set_ini()
{
	if [ $# -eq 1 ]; then
		__crudini_file="$1"
		ensure_apt crudini
		return
	fi

	if [ "X$__crudini_file" = 'X' ]; then
		log_r 'set_ini(): Please set ini file first.'
		exit
	fi

	empty_exit "$1" 'session'
	empty_exit "$2" 'key'
	empty_exit "$3" 'value'

	crudini --set "$__crudini_file" "$1" "$2" "$3"
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
		log_r 'toggle_comment(): Please set ini file first.'
		exit
	fi

	if [ "$1" = "on" ]; then
		if grep -q "$3" $__comment_file; then
			sed -ri "s|\s*${2}*(\s*${3}.*)|\1|" $__comment_file
		else
			echo "$3" >> $__comment_file
		fi
	else
		sed -ri "s|(^\s*${3}.*)|${2}\1|" $__comment_file
	fi
}


__ini_file=''

set_conf()
{
	local num_param=$#
	if [ $num_param -eq 1 ]; then
		__ini_file=$1
		return
	fi

	if [ -z $__ini_file ]; then
		log_r 'set_conf(): Please set ini file first.'
		exit
	fi

	if [ $num_param -eq 2 ]; then
		if grep -q "${1}\s*=\s*" $__ini_file; then
			sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" $__ini_file
		else
			echo "${1}=${2}" >> $__ini_file
		fi
	else
		if grep -q "${1}\s*${3}\s*" $__ini_file; then
			sed -ri "s|^[;# ]*${1}[ ]*${3}.*|${1}${3}${2}|" $__ini_file
		else
			echo "${1}${3}${2}" >> $__ini_file
		fi
	fi
}

__get_ini_file=''

get_conf()
{
	local num_param=$#

	if [ -z $__get_ini_file ]; then
		local input_path="$1"

		if [ ! -f $input_path ]; then
			log_r 'get_conf(): Please set ini file first.'
			exit
		fi

		__get_ini_file=$input_path
		return
	fi

	local inputKey=$1
	local sep='='
	if [ $num_param -eq 2 ]; then
		sep="$2"
	fi

	sed -n "s/^${inputKey}\s*${sep}\s*\([^; ]*\).*$/\1/p" $__get_ini_file
}

__insert_file=''

insert_line()
{
	local num_param=$#
	if [ $num_param -eq 1 ]; then
		__insert_file=$1
		return
	fi

	if [ -z $__insert_file ]; then
		log_r 'insert_line(): Please set ini file first.'
		exit
	fi

	sed -i "/$1/a $2" $__insert_file
}

__cat_file=''

append_file()
{
	if [ -f "$1" ]; then
		__cat_file=$1
		return
	fi

	if [ -z $__cat_file ]; then
		log_r 'append_file(): Please set file first.'
		exit
	fi

	echo "$1" >> $__cat_file
}

nocmd_exit()
{
	empty_exit $1 'command name'
	empty_exit $2 'command descripts'
	if ! cmd_exists "$1"; then
		log_y "$2"
		exit 1
	fi
}

ufw_active()
{
	if ! cmd_exists ufw; then
		return 1
	fi

	if ufw status | grep 'inactive'; then
		return 1
	fi
	return 0
}

empty_exit()
{
	if [ "X$1" = 'X' ]; then
		log_r "ERROR. the $2 is invalid."
		exit 1
	fi
}

cmd_exists() 
{
	type "$(which "$1")" > /dev/null 2>&1
}

fun_exists()  
{ 
	type "$1" 2>/dev/null | grep -q 'function'
}

check_bash()
{
	[ -z "$BASH_VERSION" ] && log_y "Change to: bash $0" && setsid bash $0 $@ && exit
}

check_sudo()
{
	if [ $(whoami) != 'root' ]; then
	    log_r "This script should be executed as root or with sudo:"
	    log_r "	sudo sh $ORIARGS "
	    exit 1
	fi
}

check_privil()
{
	if [ ! -w '/sys' ]; then
		log_r 'Not running in privileged mode.'
		exit 1
	fi
}

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

exec_upgrade()
{
	if [ $# -gt 0 ]; then
		for package in "$@"; do
			apt upgrade -y $package
		done
	else
		apt upgrade -y
	fi 
}

nocmd_udpate()
{
	for cmd in "$@"; do
		if ! cmd_exists $cmd; then
			check_update_once
			return 0
		fi
	done
}

nocmd_update()
{ 
	for cmd in "$@"; do 
		if ! cmd_exists $cmd; then 
			check_update
			return 0
		fi 
	done 
}

check_update()
{
	check_sudo

	if [ "$1" = 'f' ]; then
		apt update -y
		return 0
	fi

	local repo_changed=0

	if [ -f /var/cache/apt/pkgcache.bin ]; then
		local last_update=`stat -c %Y  /var/cache/apt/pkgcache.bin`
		local nowtime=`date +%s`
		local diff_time=$(($nowtime-$last_update))
	else 
		repo_changed=1
	fi

	if [ $# -gt 0 ]; then
		for the_param in "$@"; do
			the_ppa=$(echo $the_param | sed 's/ppa:\(.*\)/\1/')

			if [ ! -z $the_ppa ]; then 
				if ! grep -q "^deb .*$the_ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
					add-apt-repository -y $the_param
					repo_changed=1
					break
				else
					log_y "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi
}

__is_update_checked=0

check_update_once()
{
	if [ $__is_update_checked -eq 1 ]; then
		return 0
	fi 

	check_update $1
	__is_update_checked=1
}


is_devblk()
{
	[ $(lsblk -np --output KNAME | grep -c "$1") -gt 0 ]
}

has_substr()
{
	[ "${1%$2*}" != "$1" ]
}

apt_exists()
{
	[ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]
}

user_exists()
{
	$(id -u "$1" > /dev/null 2>&1)
}

ufw_actived()
{
	[ $(ufw status | grep inactive) -eq 0 ]
}

check_npm_g()
{
	if ! cmd_exists npm; then
		check_apt npm
	fi

	if [ -f "$NODE_PATH/$1/package.json" ]; then
		log_g "$1 module is exists"
		return
	fi

	if npm list -g "$1" >/dev/null; then
		log_g "$1 has been installed"
	else 
		npm install -g "$1"
	fi
}

check_service()
{
	empty_exit "$1" 'service name'

	procName="$2"
	if [ "X$procName" = 'X' ]; then
		procName="$1"
	fi

	if ! find /etc/systemd/system/ -name $1.service; then
		systemctl enable "$1"
	fi
	if ! pgrep -x "$procName" >/dev/null; then
		systemctl start "$1"
	fi
}

clean_apt()
{
	for package in "$@"; do
		if apt_exists $package; then
			apt remove -y "$package"
			log_y "${package} has been removed."
		fi
	done
	apt autoremove -y
}

ensure_apt()
{
	for package in "$@"; do
		if ! apt_exists $package; then
			apt install -y "$package"
		fi
	done
}

check_apt()
{
	for package in "$@"; do
		if apt_exists $package; then
			log_g "${package} has been installed."
		else
			apt install -y "$package"
		fi
	done
}

select_apt()
{
	empty_exit "$1" 'select_apt need at least two parameter'
	empty_exit "$2" 'select_apt need at least two parameter'

	for package in "$@"; do
		if apt search --names-only "^$package$" 2>/dev/null >/dev/null; then
			check_apt "$package"
			return 0
		fi
	done
	return 1
}

check_docker()
{
	if cmd_exists docker; then
		log_g 'docker is ready.'
		return 
	fi
	check_apt curl
	sh -c "$(curl -fsSL get.docker.com|sed "/shouldWarn=0/i exit 0")" --mirror Aliyun
	usermod -aG docker "$RUN_USER"
	check_service docker
}

image_exists()
{
	check_docker
	docker images --all | grep -Eq "^$1\s+"
}

check_image()
{
	for imageName in "$@"; do
		if image_exists "$imageName"; then
			log_g "image is ready ($imageName)"
		else
			docker pull "$imageName"
		fi
	done
}

build_image()
{ 
	export DOCKER_IMAGE="$1"
	if image_exists "$1"; then
		log_g "image is exists ($1)"
		return
	fi
	dockfile=$CACHE_DIR/$1.docker
	cat >&1 > $dockfile
	docker build -f $dockfile -t $1 $DATA_DIR
}

cont_running() 
{
	[ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = 'true' ]
}

cont_id()
{
	docker ps -aq --filter=name="$1"
}

check_cont()
{
	! cont_running "$1" && docker start -ai "$1"
}


log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

log_y()
{
    echo "${Yellow}$*${Color_Off}"
}

log_g()
{
    echo "${Green}$*${Color_Off}"
}

log_r()
{
    echo "${Red}$*${Color_Off}"
}

login_root_exec()
{
	check_sudo
	set_cmdline loginexec
	set_cmdline "$@" 

	auto_login root
	handle_rc '/root/.bashrc' loginexec "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then loginexec; fi"
}

auto_login_startx()
{
	auto_login $1
	auto_startx
}

auto_login()
{
	local loginUser=${RUN_USER}
	if [ ! -z $1 ]; then
		loginUser="$1"
	fi

	local serviceDir=/etc/systemd/system/getty@tty1.service.d/
	mkdir -p "${serviceDir}"
	cat > ${serviceDir}/override.conf <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${loginUser} --noclear %I \$TERM
EOL
	return 0
}

auto_startx()
{
	bashrc startx "if [ \"\$(tty)\" = \"/dev/tty1\" ]; then startx $1; fi"
	return 0
}

full_sources()
{
	cat >/etc/apt/sources.list <<EOL
deb http://cn.archive.ubuntu.com/ubuntu bionic main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu bionic-security main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu bionic-updates main restricted universe multiverse
deb http://cn.archive.ubuntu.com/ubuntu bionic-backports main restricted universe multiverse
deb http://security.archive.ubuntu.com/ubuntu bionic-security main restricted universe multiverse
EOL
}

cmd_exists_exit()
{
	if cmd_exists "$1"; then
		log_y "$1 is exists."
		exit	
	fi
}

init_colors()
{
	[ ! -z $Color_Off ] && return

	# Reset
	Color_Off='\033[0m'       # Text Reset

	# Regular Colors
	Black='\033[0;30m'        # Black
	Red='\033[0;31m'          # Red
	Green='\033[0;32m'        # Green
	Yellow='\033[0;33m'       # Yellow
	Blue='\033[0;34m'         # Blue
	Purple='\033[0;35m'       # Purple
	Cyan='\033[0;36m'         # Cyan
	White='\033[0;37m'        # White

	# Bold
	BBlack='\033[1;30m'       # Black
	BRed='\033[1;31m'         # Red
	BGreen='\033[1;32m'       # Green
	BYellow='\033[1;33m'      # Yellow
	BBlue='\033[1;34m'        # Blue
	BPurple='\033[1;35m'      # Purple
	BCyan='\033[1;36m'        # Cyan
	BWhite='\033[1;37m'       # White

	# Underline
	UBlack='\033[4;30m'       # Black
	URed='\033[4;31m'         # Red
	UGreen='\033[4;32m'       # Green
	UYellow='\033[4;33m'      # Yellow
	UBlue='\033[4;34m'        # Blue
	UPurple='\033[4;35m'      # Purple
	UCyan='\033[4;36m'        # Cyan
	UWhite='\033[4;37m'       # White

	# Background
	On_Black='\033[40m'       # Black
	On_Red='\033[41m'         # Red
	On_Green='\033[42m'       # Green
	On_Yellow='\033[43m'      # Yellow
	On_Blue='\033[44m'        # Blue
	On_Purple='\033[45m'      # Purple
	On_Cyan='\033[46m'        # Cyan
	On_White='\033[47m'       # White

	# High Intensity
	IBlack='\033[0;90m'       # Black
	IRed='\033[0;91m'         # Red
	IGreen='\033[0;92m'       # Green
	IYellow='\033[0;93m'      # Yellow
	IBlue='\033[0;94m'        # Blue
	IPurple='\033[0;95m'      # Purple
	ICyan='\033[0;96m'        # Cyan
	IWhite='\033[0;97m'       # White

	# Bold High Intensity
	BIBlack='\033[1;90m'      # Black
	BIRed='\033[1;91m'        # Red
	BIGreen='\033[1;92m'      # Green
	BIYellow='\033[1;93m'     # Yellow
	BIBlue='\033[1;94m'       # Blue
	BIPurple='\033[1;95m'     # Purple
	BICyan='\033[1;96m'       # Cyan
	BIWhite='\033[1;97m'      # White

	# High Intensity backgrounds
	On_IBlack='\033[0;100m'   # Black
	On_IRed='\033[0;101m'     # Red
	On_IGreen='\033[0;102m'   # Green
	On_IYellow='\033[0;103m'  # Yellow
	On_IBlue='\033[0;104m'    # Blue
	On_IPurple='\033[0;105m'  # Purple
	On_ICyan='\033[0;106m'    # Cyan
	On_IWhite='\033[0;107m'   # White
}; init_colors


git_get()
{
	git config --global --get "$1"
}

git_set()
{
	git config --global --add "$1" "$2"
}

read_exit()
{
	read -p "$1 : " JUST_READ
	[ -z "$JUST_READ" ] &&  echo "Input is empty, EXIT" && exit 1;
}

git_read()
{
	read_exit "$2" 
	git_set "$1" "$JUST_READ"
}

check_git()
{
	[ "X$2" != 'X' ] && git_set "$1" "$2" && return
	[ "X$(git_get $1)" != 'X' ] && return
	git_read "$1" "Please input git config of \"$1\": " 
}


repo_update()
{
	GIT_PUSH_DEFAULT=simple

	#---------------------------------------------------------------------
	# pull

	ROOT_DIR=`dirname $(readlink -f $0)`

	cd $ROOT_DIR
	IFS=; pull_result=$(git pull)

	if echo $pull_result | grep -q 'insufficient permission for adding an object'; then
		sudo chown -R $(id -u):$(id -g) "$(git rev-parse --show-toplevel)/.git"
	fi

	if echo $pull_result | grep -q 'use "git push" to publish your local commits'; then
		git push
		exit
	fi

	log_g ${pull_result}

	#---------------------------------------------------------------------
	# config

	user=$(git config --global --get user.name)
	if [ -z $user ]; then
		[ -z $GIT_USER_NAME ] && read -p 'Input your name: ' GIT_USER_NAME
		git config --global --add user.name $GIT_USER_NAME
	fi

	email=$(git config --global --get user.email)
	if [ -z $email ]; then
		[ -z $GIT_USER_EMAIL ] && read -p 'Input your email: ' GIT_USER_EMAIL
	       	git config --global --add user.email $GIT_USER_EMAIL
	fi

	push=$(git config --global --get push.default)
	if [ -z $push ]; then
		[ -z $GIT_PUSH_DEFAULT ] && read -p 'Input push branch( simple/matching ): ' GIT_PUSH_DEFAULT
		git config --global --add push.default $GIT_PUSH_DEFAULT
	fi

	gituser=$(git config --global --get user.gituser)
	if [ -z $gituser ]; then
		[ -z $GIT_PUSH_USER ] && read -p 'Input your GitHub username: ' GIT_PUSH_USER
		[ -z $GIT_PUSH_USER ] && exit 1
	       	git config --global --add user.gituser $GIT_PUSH_USER
		gituser=$GIT_PUSH_USER
	fi

	push_url=$(git remote get-url --push origin)

	if ! echo $push_url | grep -q "${gituser}@"; then
		new_url=$(echo $push_url | sed -e "s/\/\//\/\/${gituser}@/g")
		git remote set-url origin $new_url
		echo "${Green}Update remote url: $new_url.${Color_Off}"
	fi

	#---------------------------------------------------------------------
	# add 

	cd $ROOT_DIR
	IFS=; add_result=$(git add .)

	if echo $add_result | grep -q 'insufficient permission'; then
		echo "${Green}Permission error.${Color_Off}"
		chownUser $ROOT_DIR
		git add .
	fi

	#---------------------------------------------------------------------
	# commit

	input_msg=$1
	input_msg=${input_msg:="update"}
	IFS=; commit_result=$(git commit -m "${input_msg}")

	if echo $commit_result | grep -q 'nothing to commit'; then
		echo "${Green}Nothing to commit.${Color_Off}"
		exit
	fi

	log_g ${commit_result}

	#---------------------------------------------------------------------
	# push

	git config --global credential.helper 'cache --timeout 21600'
	git push
}
