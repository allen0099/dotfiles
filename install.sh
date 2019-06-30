#!/usr/bin/env bash

# Absolute path to this script, e.g. /home/user/Pwngdb/install.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/Pwngdb
SCRIPTPATH=$(dirname "$SCRIPT")
# Checking distro
source ./check_distribution.sh

# Config files
files=(vimrc zshrc tmux.conf tmux.conf.local)
# Needed softwares
softwares=(git zsh vim tmux curl python-pip exuberant-ctags ack-grep autojump)
echo "Your distribution is $distribution $distribution_version"

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
    dst="$home_directory/.$1"
    if [ -f $dst ] || [ -d $dst ]; then
        echo "File conflict: $dst"
    else
        src="$SCRIPTPATH/$1"
        echo "Link $src to $dst"
        ln -s $src $dst
        chown -h $current_user:$current_user $dst
    fi
}

function install_dotfiles_folder() {
    if [ -e "$home_directory/dotfiles" ]; then
        echo "dotfiles in $home_directory existed"
    else
        echo "Link $SCRIPTPATH to $home_directory"
        ln -s $SCRIPTPATH $home_directory
        chown -h $current_user:$current_user $home_directory/dotfiles
    fi
}

function check_software() {
    echo "checking $1..."
    if [ -x "`which $1`" ]; then
        echo "Done!"
    else
        echo "$1 is not installed. installing..."
        if [ "$distribution" == "Ubuntu" ]; then
            apt install -y $1
        elif [ "$distribution" == "CentOS Linux" ]; then
            yum -y install $1
        fi
    fi
}

echo ""
echo "  +------------------------------------------------+"
echo "  |                                                |\\"
echo "  |       allen0099's dotfile install script       | \\"
echo "  |                                                | |"
echo "  +------------------------------------------------+ |"
echo "   \\______________________________________________\\|"
echo ""
echo "copy from inndy, thank you Inndy!"
echo " fork from azdkj532, thank you Squirrel!"
echo "  edit from WildfootW, thank you WildfootW!"

initial

# Check sudo
if [ $permission != "root" ]; then
    echo "You need to be sudo..., exit."
    exit 1
fi

# Check and install softwares
for software in ${softwares[@]}; do
    check_software $software
done
# Fisa vim need them
echo "Pip installing..."
pip install pep8 flake8 pyflakes isort yapf

# Force Android emulator use system libs
if [ "$distribution" == "Ubuntu" ]; then
    if [ -f ~/.pam_environment ]; then
        read -p "Force Android emulator use system libs (y/N)?" choice
        case "$choice" in 
            y|Y ) echo "ANDROID_EMULATOR_USE_SYSTEM_LIBS=1" >> ~/.pam_environment;;
            n|N ) echo "Don't add environment";;
            * ) echo "Invalid options, disrupted";;
        esac
    fi
fi

# Install files and folders
for file in ${files[@]}; do
    install_file $file
done
install_dotfiles_folder

# Install vim plugins
echo "Install vim plugins"
vim +qall

# Install zsh && plugins
./oh-my-zsh/tools/install.sh
git clone https://github.com/bhilburn/powerlevel9k.git $home_directory/.oh-my-zsh/custom/themes/powerlevel9k
git clone https://github.com/zsh-users/zsh-autosuggestions $home_directory/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting $home_directory/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
sed -i "17s:\$USER:$current_user:" zshrc
sed -i "26s:\$HOME:$home_directory:" zshrc
# Unknown reason rc file replaced by other
rm $home_directory/.zshrc
mv $home_directory/.zshrc.pre-oh-my-zsh .zshrc
mv .zshrc ~/

# Switch to zsh
echo "Change default shell to zsh"
chsh -s /bin/zsh $current_user

# Change owner in dotfiles back to user
echo "Change owner"
chown -R $current_user:$current_user $SCRIPTPATH
chown -R $current_user:$current_user ~/.vim
chown -R $current_user:$current_user ~/.viminfo
chown -R $current_user:$current_user ~/.oh-my-zsh
