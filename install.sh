#!/bin/sh

REPO_URL="https://github.com/PinLin/.shconf"
REPO_NAME=".shconf"
REPO_VERSION="v3.1"

# Ask for question
askQuestion() {
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
    # Check git
    if ! command -v git >/dev/null 2>&1; then
        echo "This installer uses git to clone the configs to localhost."
        return -1
    fi

    # Remove old one
    if [ -d $HOME/$REPO_NAME ]; then
        rm -rf $HOME/$REPO_NAME
    fi

    # Clone repo to local
    git clone $REPO_URL $HOME/$REPO_NAME
    if [ $? != 0 ]; then
        echo "Failed to clone $REPO_NAME."
        return 1
    fi
    cd $HOME/$REPO_NAME
    git checkout $REPO_VERSION

    # Ask for applying configs
    todo=''
    apps='zsh vim tmux'
    for app in $apps; do
        msg="Do you want to apply configs about $app?"

        if askQuestion "$msg"; then
            todo="$todo $app"
        fi
    done

    # Apply configs about zsh
    if echo $todo | grep zsh >/dev/null; then
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
        echo "source $HOME/$REPO_NAME/config/zsh/sample.zshrc" >>$HOME/.zshrc
        echo "DEFAULT_USER=$USER" >>$HOME/.zshrc
    fi

    # Apply configs about vim
    if echo $todo | grep vim >/dev/null; then
        if [ -f $HOME/.vimrc ]; then
            mv $HOME/.vimrc $HOME/.vimrc.bak
        fi
        echo "source $HOME/$REPO_NAME/config/vim/sample.vimrc" >>$HOME/.vimrc
    fi

    # Apply configs about tmux
    if echo $todo | grep tmux >/dev/null; then
        if [ -f $HOME/.tmux.conf ]; then
            mv $HOME/.tmux.conf $HOME/.tmux.conf.bak
        fi
        echo "source $HOME/$REPO_NAME/config/tmux/sample.tmux.conf" >>$HOME/.tmux.conf
    fi

    # Finished
    echo
    echo Done! $REPO_NAME was installed.
}

main
