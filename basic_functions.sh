THIS_DIR=`dirname $(readlink -f $0)`

if [ -f $THIS_DIR/config.sh ]; then
	. $THIS_DIR/config.sh
fi

#-------------------------------------------------------
#		basic functions
#-------------------------------------------------------

get_latest_release()  # $1="creationix/nvm"
{
	curl --silent "https://api.github.com/repos/$1/releases/latest" |
	grep '"tag_name":' |
	sed -E 's/.*"([^"]+)".*/\1/'
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
		sed -ri "s|\s*${2}*(\s*${3}.*)|\1|" $__comment_file
	else
		sed -ri "s|(^\s*${3}.*)|${2}\1|" $__comment_file
	fi
}


__ini_file=''

set_conf()
{
	num_param=$#
	if [ $num_param -eq 1 ]; then
		__ini_file=$1
		return
	fi

	if [ -z $__ini_file ]; then
		echo 'set_conf(): Please set ini file first.'
		exit
	fi

	if [ $num_param -eq 2 ]; then
		sed -ri "s|^[;# ]*${1}[ ]*=.*|${1}=${2}|" $__ini_file
	else
		sed -ri "s|^[;# ]*${1}[ ]*${3}.*|${1}${3}${2}|" $__ini_file
	fi
}

check_bash()
{
	[ -z "$BASH_VERSION" ] && echo "Change to: bash $0" && setsid bash $0 $@ && exit
}

check_sudo()
{
	if [ $(whoami) != 'root' ]; then
	    echo "This script should be executed as root or with sudo:"
	    echo "	sudo $0"
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
    type "$1" > /dev/null 2>&1
}
