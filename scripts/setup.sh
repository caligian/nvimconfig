#!/bin/bash

function help() {
    echo <<EOF
    Usage: Download and install essentials to run this framework

    Luarocks to be installed:
        penlight
        lua-yaml
        lualogging
        luafun

    Neovim packages to be installed:
        paq-nvim
EOF
}

[[ $1 =~ -?h(elp)? ]] && help && exit 0

# Install paq-nvim
dest="${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/pack/packer/start/packer.nvim
[[ ! -d $dest ]] && git clone --depth 1 https://github.com/wbthomason/packer.nvim $dest

# Install these luarocks to ~/.config/nvim/luarocks
dest=$HOME/.config/nvim/luarocks
packages=(penlight lua-yaml lualogging luafun)

[[ ! -d $dest ]] && mkdir -p $dest

for i in ${packages[@]}; do
    luarocks --tree $dest install $i --lua-version 5.1
done
