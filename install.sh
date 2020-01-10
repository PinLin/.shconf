#!/bin/sh

REPO_URL="https://github.com/PinLin/dotfiles"
REPO_NAME="dotfiles"

INSTALL_DIRECTORY=${INSTALL_DIRECTORY:-"$HOME/.$REPO_NAME"}
INSTALL_VERSION=${INSTALL_VERSION:-"master"}


askquestion() {
    printf "$1 [y/N] "

    read ans
    case $ans in
    [Yy*])
        return $(true)
        ;;
    *)
        return $(false)
        ;;
    esac
}

main() {
    # Exit if git was not installed
    if ! command -v git >/dev/null 2>&1; then
        echo "You must install git before using the installer."
        return $(false)
    fi

    # Remove old one
    if [ -d $INSTALL_DIRECTORY ]; then
        rm -rf $INSTALL_DIRECTORY
    fi

    # Clone repo to local
    git clone $REPO_URL $INSTALL_DIRECTORY
    if [ $? != 0 ]; then
        echo "Failed to clone $REPO_NAME."
        return 1
    fi
    cd $INSTALL_DIRECTORY
    git checkout $INSTALL_VERSION

    # Apply the config of zsh
    if askquestion "Do you want to apply the config of zsh?"; then
        # Require oh-my-zsh
        if ! [ -d $HOME/.oh-my-zsh ]; then
            if command -v curl >/dev/null 2>&1; then
                sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
            else
                sh -c "$(wget -qO- https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
            fi
        fi
        # Install powerlevel9k
        if ! [ -d $HOME/.oh-my-zsh/custom/themes/powerlevel9k ]; then
            git clone https://github.com/bhilburn/powerlevel9k.git $HOME/.oh-my-zsh/custom/themes/powerlevel9k
        fi
        # Install zsh-autosuggestions
        if ! [ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        fi
        # Install zsh-syntax-highlighting
        if ! [ -d ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        fi
        if [ -f $HOME/.zshrc ]; then
            mv $HOME/.zshrc $HOME/.zshrc.bak
        fi
        echo "source $INSTALL_DIRECTORY/config/zsh/sample.zshrc" >>$HOME/.zshrc
        echo "DEFAULT_USER=$USER" >>$HOME/.zshrc
    fi

    # Apply the config of vim
    if askquestion "Do you want to apply the config of vim?"; then
        if [ -f $HOME/.vimrc ]; then
            mv $HOME/.vimrc $HOME/.vimrc.bak
        fi
        echo "source $INSTALL_DIRECTORY/config/vim/sample.vimrc" >>$HOME/.vimrc
    fi

    # Apply the config of tmux
    if askquestion "Do you want to apply the config of tmux?"; then
        if [ -f $HOME/.tmux.conf ]; then
            mv $HOME/.tmux.conf $HOME/.tmux.conf.bak
        fi
        echo "source $INSTALL_DIRECTORY/config/tmux/sample.tmux.conf" >>$HOME/.tmux.conf
    fi

    # Finished
    echo
    echo Done! $REPO_NAME:$INSTALL_VERSION was installed.
}

main
