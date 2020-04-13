#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
# Checking distro
source ./check_distribution.sh

# Needed softwares
softwares=(git zsh vim tmux)
vim_require=(git curl python3-pip exuberant-ctags ack-grep)
zsh_require=(autojump)
echo "Your distribution is ${distribution:?} ${distribution_version:?}"

function initial() {
    if [ "$distribution" == "Ubuntu" ]; then
        permission=$USER
        current_user=$SUDO_USER
        home_directory=$HOME
    elif [ "$distribution" == "CentOS Linux" ]; then
        permission=$USER
        current_user=$SUDO_USER
        home_directory="/home/$SUDO_USER"
    else
        echo "Your distribution havn't been support yet. exit.."
        exit 1
    fi
}

function install_file() {
    dst="$home_directory/$1"
    if [ -f "$dst" ] || [ -d "$dst" ]; then
        echo "File conflict -> $dst"
    else
        src="$SCRIPTPATH/$1"
        echo "Link $src to $dst"
        ln -s "$src" "$dst"
        chown -h "$current_user":"$current_user" "$dst"
    fi
}

function check_software() {
    read -rp "Install $1... (y/N)?" choice
    case "$choice" in
        y|Y )
            echo "Checking $1"
            if [ -x "$(command -v "$1")" ]; then
                echo "Done!"
            else
                echo "$1 is not installed. installing..."
                if [ "$distribution" == "Ubuntu" ]; then
                    apt install -y "$1"
                elif [ "$distribution" == "CentOS Linux" ]; then
                    yum -y install "$1"
                fi
            fi
            ;;
        n|N )
            echo "Don't install $1"
            ;;
        * )
            echo "Invalid options, disrupted"
            ;;
    esac
}

echo ""
echo "  +------------------------------------------------+"
echo "  |                                                |\\"
echo "  |       allen0099's dotfile install script       | \\"
echo "  |                                                | |"
echo "  +------------------------------------------------+ |"
echo "   \\______________________________________________\\|"
echo ""

initial

# Check sudo
if [ "$permission" != "root" ]; then
    echo "You need to be sudo..., exit."
    exit 1
fi

# Check and install software
for software in "${softwares[@]}"; do
    check_software "$software"
done

# Check vim and install require
if [ -x "$(command -v vim)" ]; then
    echo "Install vim require..."
    for software in "${vim_require[@]}"; do
        check_software "$software"
    done
    pip3 install pep8 flake8 pyflakes isort yapf
    install_file .vimrc
    vim +qall
else
    echo "Vim is not installed. Aborting..."
fi

# Check tmux and install require
if [ -x "$(command -v tmux)" ]; then
    echo "Install vim require..."
    for software in "${vim_require[@]}"; do
        check_software "$software"
    done
    pip3 install pep8 flake8 pyflakes isort yapf
    install_file .vimrc
    vim +qall
else
    echo "Tmux is not installed. Aborting..."
fi

# Check zsh and install require
#if [ -x "$(command -v zsh)" ]; then
#    echo "Install zsh require..."
#    for software in "${zsh_require[@]}"; do
#        check_software "$software"
#    done
#else
#    echo "Zsh is not installed. Aborting..."
#fi

# Force Android emulator use system libs
if [ "$distribution" == "Ubuntu" ]; then
    if [ -f ~/.pam_environment ]; then
        read -rp "Force Android emulator use system libs (y/N)?" choice
        case "$choice" in
            y|Y ) echo "ANDROID_EMULATOR_USE_SYSTEM_LIBS=1" >> ~/.pam_environment;;
            n|N ) echo "Don't add environment";;
            * ) echo "Invalid options, disrupted";;
        esac
    fi
fi

# Install zsh && plugins
#./oh-my-zsh/tools/install.sh
#git clone https://github.com/bhilburn/powerlevel9k.git $home_directory/.oh-my-zsh/custom/themes/powerlevel9k
#git clone https://github.com/zsh-users/zsh-autosuggestions $home_directory/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#git clone https://github.com/zsh-users/zsh-syntax-highlighting $home_directory/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
#sed -i "17s:\$USER:$current_user:" zshrc
#sed -i "26s:\$HOME:$home_directory:" zshrc
## Unknown reason rc file replaced by other
#rm $home_directory/.zshrc
#mv $home_directory/.zshrc.pre-oh-my-zsh .zshrc
#mv .zshrc ~/
#
## Switch to zsh
#echo "Change default shell to zsh"
#chsh -s /bin/zsh $current_user
#
## Change owner in dotfiles back to user
#echo "Change owner"
#chown -R $current_user:$current_user $SCRIPTPATH
#chown -R $current_user:$current_user ~/.vim
#chown -R $current_user:$current_user ~/.viminfo
#chown -R $current_user:$current_user ~/.oh-my-zsh
