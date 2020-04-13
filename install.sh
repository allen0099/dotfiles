#!/usr/bin/env bash

# Defines
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")

# Checking distribution
source ./check_distribution.sh

# Needed software list
target_software=(git zsh vim tmux)
vim_require=(git curl python3-pip exuberant-ctags ack-grep)
zsh_require=(autojump)

echo "[INFO] Your distribution is ${distribution:?} ${distribution_version:?}"

function initial() {
    if [ "$distribution" == "Ubuntu" ]; then
        permission=$USER
        current_user=$SUDO_USER
        if [ "$distribution_version" == "20.04" ]; then
            home_directory="/home/$SUDO_USER"
        else
            home_directory=$HOME
        fi
    elif [ "$distribution" == "CentOS Linux" ]; then
        permission=$USER
        current_user=$SUDO_USER
        home_directory="/home/$SUDO_USER"
    else
        echo "[ERROR] Your distribution haven't been support yet. Exit."
        exit 1
    fi
    echo "[DEBUG] USER=$USER"
    echo "[DEBUG] SUDO_USER=$SUDO_USER"
    echo "[DEBUG] HOME=$HOME"
    echo "[DEBUG] permission=$permission"
    echo "[DEBUG] current_user=$current_user"
    echo "[DEBUG] home_directory=$home_directory"
    # permission check
    if [ "$permission" != "root" ]; then
        echo "[ERROR] You need to be sudo...! Exit."
        exit 1
    fi
    echo "[INFO] update git submodule..."
    git submodule update --init --recursive
    if [ "$HOME" != "$home_directory" ]; then
        HOME=$home_directory
        echo "[INFO] home fixed!"
        echo "[DEBUG] HOME=$HOME"
        echo "[DEBUG] home_directory=$home_directory"
    fi
}

function ln_conf() {
    dst="$home_directory/$1"
    if [ -f "$dst" ] || [ -d "$dst" ]; then
        echo "[WARNING] File conflict: $dst already existed!"
        read -rp "[WARNING] move conflict to $dst.bak (y/N)?" choice
        case "$choice" in
            y|Y )
                echo "[INFO] Moving file..."
                mv "$dst" "$dst.bak"
                src="$SCRIPTPATH/$1"
                echo "[INFO] Link $src to $dst"
                ln -s "$src" "$dst"
                chown -h "$current_user":"$current_user" "$dst"
                ;;
            n|N )
                echo "[INFO] Do nothing! Not link the file!"
                ;;
            * )
                echo "[ERROR] Invalid options, disrupted"
                ;;
        esac
    else
        src="$SCRIPTPATH/$1"
        echo "[INFO] Link $src to $dst"
        ln -s "$src" "$dst"
        chown -h "$current_user":"$current_user" "$dst"
    fi
}

function check_software() {
    read -rp "[INFO] Install $1... (y/N)?" choice
    case "$choice" in
        y|Y )
            echo "[INFO] Checking $1..."
            if [ -x "$(command -v "$1")" ]; then
                echo "[INFO] Done!"
            else
                echo "[INFO] $1 is not installed. Installing..."
                if [ "$distribution" == "Ubuntu" ]; then
                    apt install -y "$1"
                elif [ "$distribution" == "CentOS Linux" ]; then
                    yum -y install "$1"
                fi
            fi
            ;;
        n|N )
            echo "[INFO] Don't install $1"
            ;;
        * )
            echo "[ERROR] Invalid options, disrupted"
            ;;
    esac
}

echo "[INFO] "
echo "[INFO]   +------------------------------------------------+"
echo "[INFO]   |                                                |\\"
echo "[INFO]   |       allen0099's dotfile install script       | \\"
echo "[INFO]   |                                                | |"
echo "[INFO]   +------------------------------------------------+ |"
echo "[INFO]    \\______________________________________________\\|"
echo "[INFO] "

initial

# Check and install software
for software in "${target_software[@]}"; do
    check_software "$software"
done

# Check vim and install require
if [ -x "$(command -v vim)" ]; then
    echo "[INFO] Install vim require..."
    for software in "${vim_require[@]}"; do
        check_software "$software"
    done
    echo "[INFO] fisa-vim requirements installing..."
    pip3 install pynvim flake8 pylint isort
    ln_conf .vimrc
    vim +qall

    echo "[INFO] Changing permission to $current_user"
    chown -R "$current_user":"$current_user" "$HOME/.vim"
    chown -R "$current_user":"$current_user" "$HOME/.fzf"
    chown -R "$current_user":"$current_user" "$HOME/.fzf.bash"
    chown -R "$current_user":"$current_user" "$HOME/.fzf.zsh"
else
    echo "[ERROR] Vim is not installed. Aborting..."
fi

# Check tmux and install require
if [ -x "$(command -v tmux)" ]; then
    echo "[INFO] Install tmux configuration..."
    ln_conf .tmux.conf
    ln_conf .tmux.conf.local
else
    echo "[ERROR] Tmux is not installed. Aborting..."
fi

# Check zsh and install require
if [ -x "$(command -v zsh)" ]; then
    echo "[INFO] Install oh-my-zsh plugins require..."
    for software in "${zsh_require[@]}"; do
        check_software "$software"
    done
    echo "[INFO] Install oh-my-zsh..."
    ./oh-my-zsh/tools/install.sh
    echo "[INFO] Install oh-my-zsh theme..."
    git clone https://github.com/bhilburn/powerlevel9k.git "$home_directory/.oh-my-zsh/custom/themes/powerlevel9k"
    echo "[INFO] Install oh-my-zsh plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$home_directory/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$home_directory/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    echo "[INFO] Setting up the zsh config..."
    sed -i "17s:\$USER:$current_user:" .zshrc
    sed -i "26s:\$HOME:$home_directory:" .zshrc
    ln_conf .zshrc

    echo "[INFO] Changing permission to $current_user"
    chown -R "$current_user":"$current_user" "$HOME/.oh-my-zsh"
else
    echo "[ERROR] Zsh is not installed. Aborting..."
fi

# Force Android emulator use system libs
if [ "$distribution" == "Ubuntu" ]; then
    if [ -f ~/.pam_environment ]; then
        read -rp "[INFO] Force Android emulator use system libs (y/N)?" choice
        case "$choice" in
            y|Y ) echo "ANDROID_EMULATOR_USE_SYSTEM_LIBS=1" >> ~/.pam_environment;;
            n|N ) echo "Don't add environment";;
            * ) echo "Invalid options, disrupted";;
        esac
    fi
fi

## Switch to zsh
#echo "Change default shell to zsh"
#chsh -s /bin/zsh $current_user
