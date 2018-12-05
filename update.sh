#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

! cmd_exists git && apt install git
! cmd_exists vim && apt install vim

repo_update
