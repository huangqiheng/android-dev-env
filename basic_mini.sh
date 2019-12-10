export LIBSH='basic_mini.sh'
export BASIC_SCRIPT=$(f=$LIBSH; while [ ! -f $f ]; do f="../$f"; done; echo $(readlink -f $f))
export EXEC_SCRIPT=$(readlink -f $0)
export EXEC_DIR=$(dirname $EXEC_SCRIPT)
export ROOT_DIR=$(dirname $BASIC_SCRIPT)
export RUN_USER=$(basename $HOME)

log()         { if [ "$LOGFLAG" != 'off' ]; then echo "$@"; fi }
log_r()       { log "\033[0;31m$*\033[0m"; }
log_g()       { log "\033[0;32m$*\033[0m"; }
log_y()       { log "\033[0;33m$*\033[0m"; }

cmd_exists()  { type "$(which $1)" > /dev/null 2>&1; }
fun_exists()  { type "$1" 2>/dev/null | grep -q 'function'; }
check_sudo()  { [ $(whoami) != 'root' ] && log_r "Must be run as root" && exit 1; }
check_bash()  { [ -z "$BASH_VERSION" ] && log_y "Change to: bash $0" && setsid bash $0 $@ && exit; }
check_privil(){ if [ ! -w '/sys' ];then log_r 'Not running in privileged mode.';exit 1;fi; }
user_exists() { $(id -u "$1" > /dev/null 2>&1); }
runUser()     { runuser -l $RUN_USER -c "$1"; }
chownUser()   { chown -R $RUN_USER:$RUN_USER $1; }

apt_exists()  { [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]; }
check_apt()   { for p in "$@";do if apt_exists $p;then log_g "$p installed"; else apt install -y $p;fi done; }
ensure_apt()  { for p in "$@";do if ! apt_exists $p;then apt install -y $p;fi done; }
select_apt()  { for p in $@;do if apt search -n "^$p$" >/dev/null 2>&1;then check_apt $p;return 0;fi done }

check_npm_g() { r=$(npm root -g); for p in "$@";do if [ -d $r/$p ];then log_g "$p exists";else npm i -g "$p";fi done; }
node_init() { nocmd_update nodejs;ensure_apt nodejs; for p in "$@"; do check_npm_g $p; done; }
node_exec() { if [ -f $1 ];then c=$(cat $1);else c=$($1); fi; shift; echo "$c" | NODE_PATH=$(npm root -g) node - $@; }

check_update(){ check_sudo; apt update -y; }
nocmd_update(){ for cmd in "$@"; do if ! cmd_exists $cmd; then check_update;return 0;fi done; }
check_repo()  { add-apt-repository -y $1; check_update; }

empty_exit()  { [ -z $1 ] && log_r "ERROR. the $2 is invalid." && exit 1; }
set_ini()     { if [ $# -eq 1 ];then _crud="$1";check_apt crudini;return;fi;crudini --set $_crud $@; }
waitfor_die() { sleep infinity & CLD=$!;[ -n "$1" ] && trap "${1};kill -9 $CLD" 1 2 9 15;wait "$CLD"; }
has_substr()  { [ "${1%$2*}" != "$1" ]; }
enum_lines() { P=$1; IFS=$(printf '\n+'); set -- $2; while [ "$1" != '' ]; do $P $1; shift; done; }
public_ip()   { curl -4 icanhazip.com; }

check_docker(){ cmd_exists docker && return; sh -c "$(curl -fsSL get.docker.com)" --mirror Aliyun; }
image_exists(){ check_docker; docker images --all | grep -q "$1"; }
check_image() { check_docker; for p in "$@"; do if ! image_exists "$p";then docker pull "$p";fi done; }
build_image() { image_exists $1 && return;f=$CACHE_DIR/$1.docker;cat >&1 > $f;docker build -f $f -t $1 $DATA_DIR; }
cont_running(){ [ $(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null) = 'true' ]; }
check_cont()  { ! cont_running "$1" && docker start -ai "$1"; }

git_get()   { git config --global --get "$1"; }
git_set()   { git config --global --add "$1" "$2"; }
read_exit() { read -p "$1 : " JUST_READ; [ -z "$JUST_READ" ] &&  echo "Input is empty, EXIT" && exit 1; }
git_read()  { read_exit "$2"; git_set "$1" "$JUST_READ"; }

while true; do [ -f config.sh ] && . ./config.sh; [ -f $LIBSH ] && break; cd ..; done; cd $EXEC_DIR
while true; do [ -f functions.sh ] && . ./functions.sh; [ -f $LIBSH ] && break; cd ..; done; cd $EXEC_DIR
