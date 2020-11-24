#!/bin/dash
. $(f='basic_functions.sh'; while [ ! -f $f ]; do f="../$f"; done; readlink -f $f)
#------------------------------------------------------------------------------#

main() 
{
	check_apt ffmpeg
	ffmpeg -i "$1" -vcodec libx265 -crf 28 "${1}-output.mp4"
}

#------------------------------------------------------------------------------#
main_entry $@
