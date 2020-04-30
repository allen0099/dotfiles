#!/usr/bin/env bash

# Defines
SCRIPT=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "$SCRIPT")

# Checking distribution
source ./check_distribution.sh

echo "[INFO] "
echo "[INFO]   +------------------------------------------------+"
echo "[INFO]   |                                                |\\"
echo "[INFO]   |       allen0099's dotfile install script       | \\"
echo "[INFO]   |                                                | |"
echo "[INFO]   +------------------------------------------------+ |"
echo "[INFO]    \\______________________________________________\\|"
echo "[INFO] "

echo "[INFO] Your distribution is ${distribution:?} ${distribution_version:?}"

function chk_sfw() {
  for software in "$@"; do
    echo "[INFO] Checking $software ..."
    if [ -x "$(command -v "$software")" ]; then
      echo "[INFO] $software has been installed successfully!"
    else
      echo "[INFO] $software is not installed. Installing..."
      if [ "$distribution" == "Ubuntu" ]; then
        sudo apt install -y "$software"
      fi
    fi
  done
}

function chk_ln() {
  dst="$HOME/$1"
  if [ -f "$dst" ] || [ -d "$dst" ]; then
    echo "[WARNING] File conflict: $dst already existed!"
    read -rp "[WARNING] move conflict to $dst.bak (y/N)?" choice
    case "$choice" in
    y | Y)
      echo "[INFO] Moving file..."
      mv "$dst" "$dst.bak"
      src="$SCRIPT_PATH/$1"
      echo "[INFO] Link $src to $dst"
      ln -s "$src" "$dst"
      ;;
    n | N)
      echo "[INFO] Do nothing! Not link the file!"
      ;;
    *)
      echo "[ERROR] Invalid options, disrupted"
      ;;
    esac
  else
    src="$SCRIPT_PATH/$1"
    echo "[INFO] Link $src to $dst"
    ln -s "$src" "$dst"
  fi
}

function cfg_link() {
  chk_ln .bashrc
  chk_ln .gitconfig
}

function install_vim() {
  echo "[INFO] Installing fisa-vim..."
  chk_sfw git curl python3-pip exuberant-ctags ack-grep
  sudo pip3 install pynvim flake8 pylint isort
  chk_ln .vimrc
  vim +qall
}

function install_tmux() {
  echo "[INFO] Installing tmux..."
  chk_sfw tmux
  chk_ln .tmux.conf
  chk_ln .tmux.conf.local
}

function install_zsh() {
  echo "[INFO] Installing zsh..."
  chk_sfw zsh

  echo "[INFO] Installing ohmyzsh..."
  chk_sfw curl
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "[INFO] Installing ohmyzsh theme (powerlevel10k)..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

  echo "[INFO] Installing ohmyzsh plugins..."
  chk_sfw autojump
  git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
  chk_ln .p10k.zsh
  chk_ln .zshrc
}

function other() {
  clear
  echo "****** Other option ******"
  echo "(1)  Force Android emulator use system libs"
  echo "(2)  Change default shell to zsh"
  echo "(3)  QT input module (ibus)"
  echo ""
  echo "(q)  Leave"

  read -r other_choose
  case "$other_choose" in
  1)
    if [ -f ~/.pam_environment ]; then
      echo "ANDROID_EMULATOR_USE_SYSTEM_LIBS=1" >>~/.pam_environment
    fi
    echo "[INFO] Done!"
    read -rp "Press [Enter] to continue..."
    other
    ;;
  2)
    chsh -s "$(command -v zsh)" "$USER"
    other
    ;;
  3)
    if [ -f ~/.pam_environment ]; then
      echo "GTK_IM_MODULE=ibus" >>~/.pam_environment
      echo "QT_IM_MODULE=ibus" >>~/.pam_environment
      echo "XMODIFIERS=@im=ibus" >>~/.pam_environment
    fi
    other
    ;;
  q | Q)
    main
    ;;
  *)
    echo "[ERROR] Invalid option, aborting..."
    main
    ;;
  esac
}

function main() {
  clear
  echo "****** Main menu (which to install) ******"
  echo "(1)  vim"
  echo "(2)  tmux"
  echo "(3)  zsh"
  echo ""
  echo "(c)  config link"
  echo "(a)  All of above"
  echo "(o)  Others (some settings)"
  echo "(q)  Leave"

  read -r main_choose
  case "$main_choose" in
  1)
    install_vim
    main
    ;;
  2)
    install_tmux
    main
    ;;
  3)
    install_zsh
    main
    ;;
  a | A)
    install_vim
    install_tmux
    install_zsh
    cfg_link
    main
    ;;
  c | C)
    cfg_link
    main
    ;;
  o | O)
    other
    ;;
  q | Q)
    return 0
    ;;
  *)
    echo "[ERROR] Invalid option, aborting..."
    return 1
    ;;
  esac
}

function init() {
  # download submodules
  echo "[INFO] submodule initializing..."
  chk_sfw git
  git submodule update --init --recursive
  echo "[INFO] submodule initialized!"

  read -rp "Press [Enter] to continue..."
  main
}

init
