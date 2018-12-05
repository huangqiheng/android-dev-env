#!/bin/bash

. $(dirname $(readlink -f $0))/basic_functions.sh

! cmd_exists git && apt install -y git
! cmd_exists vim && apt install -y vim

repo_update
