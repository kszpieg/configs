#!/usr/bin/env bash

DIR=$(realpath "$(dirname "$0")")

function create_ln() {
    FILE=$(basename "$1")

    if [ "$2" = "-nf" ]; then
        echo -ne "creating symlink of $FILE to $HOME/$FILE  "
        ln -sfn "$DIR/$1" "$HOME/$FILE"
        echo DONE
    else
        echo -ne "creating symlink of $1 to $HOME/$1  "
        ln -sfn "$DIR/$1" "$HOME/$1"
        echo DONE
    fi
}

# === Base setup section ===
echo "=====setting up your computer... please wait...====="

if [ "$OSTYPE" = "linux-gnu" ]; then
    # run latest updates
    echo "=====checking for updates... please wait...====="
    sudo apt update -y && sudo apt upgrade -y

    # check for curl and install if it's not found
    echo "=====checking for curl...====="
    if test ! "$(which curl)"; then
        sudo apt install curl -y
    fi
    echo DONE
elif [ "$OSTYPE" = "darwin" ]; then
    # run latest updates
    echo "=====checking for updates... please wait...====="
    sudo softwareupdate -i -a
fi

# check for homebrew and install if it's not found
echo "=====checking for homebrew...====="
if test ! "$(which brew)"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo DONE

# === Homebrew section ===
echo "=====installing brew packages...====="

# update homebrew recipes
brew update

# install brew dependencies with bundle
brew tap homebrew/bundle
brew bundle --file ./Brewfile

if [ "$OSTYPE" = "linux-gnu" ]; then
    # check for zsh and install if it's not found
    echo "=====checking for zsh...====="
    if test ! "$(which zsh)"; then
        sudo apt install zsh -y
    fi
    echo DONE

    # === App section
    echo "=====installing linux apps...====="

    # install batcat
    sudo apt install bat -y

    # install htop
    sudo apt install htop -y
fi

# check for oh-my-zsh and install if it's not found
echo "=====checking for oh-my-zsh...====="
if test ! "$(which omz)"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
echo DONE

# check for starship and install if it's not found
echo "=====checking for starship...====="
if test ! "$(which starship)"; then
    curl -sS https://starship.rs/install.sh | sh
fi
echo DONE

# === Symlinks section ===
echo "=====creating symlinks...====="

# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"

# create symlinks for all configs
create_ln zsh/.zshrc -nf
create_ln zsh/.aliases.zsh -nf
create_ln git/.gitconfig -nf
create_ln .config/fastfetch/config.jsonc
create_ln .config/starship.toml

# === Finish section ===

echo "=====almost done...====="

# load zsh config
source "$HOME/.zshrc"

echo "=====your machine is settled up, enjoy!====="