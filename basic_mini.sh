THIS_SCRIPT=$(readlink -f $0)
THIS_DIR=$(dirname $THIS_SCRIPT)
RUN_USER=$(basename $HOME)

log()         { if [ "$LOGFLAG" != 'off' ]; then echo "$@"; fi }
log_r()       { log "\033[0;31m$*\033[0m"; }
log_g()       { log "\033[0;32m$*\033[0m"; }
log_y()       { log "\033[0;33m$*\033[0m"; }
cmd_exists()  { type "$(which "$1")" > /dev/null 2>&1; }
apt_exists()  { [ $(dpkg-query -W -f='${Status}' ${1} 2>/dev/null | grep -c "ok installed") -gt 0 ]; }
check_sudo()  { [ $(whoami) != 'root' ] && log_r "Must be run as root" && exit 1; }
check_bash()  { [ -z "$BASH_VERSION" ] && log_y "Change to: bash $0" && setsid bash $0 $@ && exit; }
check_apt()   { for p in "$@";do if ! apt_exists $p;then apt install -y $p;fi done; }
check_npm_g() { for p in "$@";do [ ! -d $(npm ls -g|head -1)/node_modules/$p ] &&  npm i -g "$p";done; }
empty_exit()  { [ -z $1 ] && log_r "ERROR. the $2 is invalid." && exit 1; }
check_update(){ check_sudo; apt update -y; }
nocmd_update(){ for cmd in "$@"; do if ! cmd_exists $cmd; then check_update;return 0;fi done; }
check_repo()  { add-apt-repository -y $1; check_update; }
set_ini()     { if [ $# -eq 1 ];then _crud="$1";check_apt crudini;return;fi;crudini --set $_crud $@; }
waitfor_die() { sleep infinity & CLD=$!;[ -n "$1" ] && trap "${1};kill -9 $CLD" 1 2 9 15;wait "$CLD"; }

