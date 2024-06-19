#!/usr/bin/env bash

DIR=$(realpath "$(dirname "$0")")

function create_ln() {
    FILE=$(basename "$1")

    if [ "$2" = "-nf" ]; then
        echo -ne "Creating symlink of $FILE to $HOME/$FILE  "
        ln -sfn "$DIR/$1" "$HOME/$FILE"
        echo DONE
    else
        echo -ne "Creating symlink of $1 to $HOME/$1  "
        ln -sfn "$DIR/$1" "$HOME/$1"
        echo DONE
    fi
}

# === Base setup section ===
echo "INFO: SETTING UP YOUR COMPUTER..."

# run latest updates
sudo apt update -y && sudo apt upgrade -y

# check for curl and install if it's not found
echo "Checking for curl..."
if test ! "$(which curl)"; then
    sudo apt install curl -y
fi
echo DONE

# check for zsh and install if it's not found
echo "Checking for zsh..."
if test ! "$(which zsh)"; then
    sudo apt install zsh -y
fi
echo DONE

# check for oh-my-zsh and install if it's not found
echo "Checking for oh-my-zsh..."
if test ! "$(which omz)"; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
echo DONE

# check for starship and install if it's not found
echo "Checking for starship..."
if test ! "$(which starship)"; then
    curl -sS https://starship.rs/install.sh | sh
fi
echo DONE

# check for homebrew and install if it's not found
echo "Checking for homebrew..."
if test ! "$(which brew)"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo DONE

# === Symlinks section ===
echo "INFO: CREATING SYMLINKS..."

# remove .zshrc from $HOME (if it exists)
rm -rf "$HOME/.zshrc"

# create symlinks for all configs
create_ln zsh/.zshrc -nf
create_ln zsh/.aliases.zsh -nf
create_ln git/.gitconfig -nf
create_ln .config/fastfetch/config.jsonc
create_ln .config/starship.toml

# === App section
echo "INFO: INSTALLING APPS..."

# install batcat
sudo apt install bat -y

# install htop
sudo apt install htop -y

# === Homebrew section ===
echo "INFO: INSTALLING BREW PACKAGES..."

# update homebrew recipes
brew update

# install brew dependencies with bundle
brew tap homebrew/bundle
brew bundle --file ./Brewfile

# === Finish section ===

# load zsh config
source "$HOME/.zshrc"
