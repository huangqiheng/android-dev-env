ORIARGS="$0 $*"
THIS_DIR=`dirname $(readlink -f $0)`
CACHE_DIR=$THIS_DIR/cache
DATA_DIR=$THIS_DIR/data
RUN_DIR=$HOME/runCodes
RUN_USER=$(basename $HOME)
WIRELESS_IFACE=${WIRELESS_IFACE:-'wlp2s0'}

mkdir -p $CACHE_DIR
mkdir -p $RUN_DIR

cd $THIS_DIR

if [ -f $THIS_DIR/config.sh ]; then
	. $THIS_DIR/config.sh
fi

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

sshhost_parse()
{
	SSH_sshHost="$1"
	IFS='@:'; set -- "$SSH_sshHost"

	SSH_username="$1"
	SSH_hostname="$2"
	SSH_portnumb="$3"
	SSH_hostip=$(dig +short $SSH_hostname)
}

get_wifi_ifaces()
{
	lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g'
}

get_ifaces()
{
	ifconfig -s | tail -n +2 | awk '{print $1}' | grep -v 'lo'
}

get_localnet_ips()
{
	for iface in $(get_ifaces); do
		arp-scan --interface=$iface --localnet 2>/dev/null | awk '{print $1}' | tail -n +3 | head -n -2
	done
}


ip_to_interface()
{
	ifconfig | grep -B1 "$1" | grep -o "^\w*"
}

extra_wifi_interface()
{
	WIRELESS_IFACE=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
}

runUser()
{
	runuser -l $RUN_USER -c "$1"
}

chownUser()
{
	chown -R $RUN_USER:$RUN_USER $1
}

get_latest_release()  # $1="creationix/nvm"
{
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
}

bashrc()
{
	echo_file=$HOME/.bashrc
	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo "$2" >> $echo_file
}

ratpoisonrc()
{
	echo_file=$HOME/.ratpoisonrc
	if grep -iq "$1" $echo_file; then
		return 1
	fi
	echo "$1" >> $echo_file
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
		echo 'set_conf(): Please set ini file first.'
		exit
	fi

	if [ $num_param -eq 2 ]; then
		if grep "${1}\s*=\s*" $__ini_file; then
			sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" $__ini_file
		else
			echo "${1}=${2}" >> $__ini_file
		fi
	else
		if grep "${1}\s*${3}\s*" $__ini_file; then
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
			echo 'get_conf(): Please set ini file first.'
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
		echo 'insert_line(): Please set ini file first.'
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
		echo 'append_file(): Please set file first.'
		exit
	fi

	echo "$1" >> $__cat_file
}

check_bash()
{
	[ -z "$BASH_VERSION" ] && echo "Change to: bash $0" && setsid bash $0 $@ && exit
}

check_sudo()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	${Red}sudo $ORIARGS ${Color_Off}"
	    exit 1
	fi
}


check_update()
{
	check_sudo

	if [ "$1" = 'f' ]; then
		apt update -y
		apt upgrade -y
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
					log "repo ${the_ppa} has already exists"
				fi
			fi
		done
	fi 

	if [ $repo_changed -eq 1 ] || [ $diff_time -gt 604800 ]; then
		apt update -y
	fi

	if [ $diff_time -gt 6048000 ]; then
		apt upgrade -y
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
	if cmd_exists "$1"; then
		log "$1 has been installed"
	else 
		npm install -g "$2"
	fi
}

check_apt()
{
	for package in "$@"; do
		if apt_exists $package; then
			log "${package} has been installed"
		else
			apt install -y "$package"
		fi
	done
}

log() 
{
	echo "$@"
	#logger -p user.notice -t install-scripts "$@"
}

cmd_exists() 
{
	type "$(which "$1")" > /dev/null 2>&1
}

auto_login()
{
	set_conf /etc/systemd/system/getty.target.wants/getty@tty1.service
	set_conf ExecStart "-/sbin/agetty --autologin ${RUN_USER} --noclear %I \$TERM"
}

auto_startx()
{
	bashrc startx <<EOL
if [ \$(tty) == "/dev/tty1" ]; then
        startx
fi
EOL
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
		log "$1 is available, exit"
		log "$2"
		exit	
	fi
}

init_colors()
{
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
}
