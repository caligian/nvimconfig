#!/bin/bash

DST=$HOME/.config/nvim/luarocks
HELP="$(cat <<EOF
$0: Install luarock to $DST

Pass the name of the package you wish to install. 

This script will download and use only lua5.1  packages
EOF
)" 

[[ -z $1 ]] && echo 'No package name provided'  && exit 1
[[ $1 =~ -h ]] && echo "$HELP" && exit 0
[[ ! -d $DST ]] && mkdir $DST

luarocks --lua-version 5.1 --tree $HOME/.config/nvim/luarocks install $1 
