#!/bin/sh

REPO_URL="https://github.com/PinLin/.shconf"
REPO_NAME=".shconf"
REPO_VERSION="v3.1"

# Install application
makeInstall() {
    # Check counts of arguments
    if [ $# -lt 1 ]; then
        return -1
    fi

    # Judge which is the package manager we used
    kernel=$(uname -s)
    if [ "$kernel" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            # macOS with brew
            brew install $1
            return $?
        else
            echo "You need to install Homebrew on your macOS before runing this script."
            echo See this: https://brew.sh
            return 87
        fi

    elif [ "$kernel" = "FreeBSD" ]; then
        if command -v pkg >/dev/null 2>&1; then
            # FreeBSD with pkg
            sudo pkg install -y $1
            return $?
        else
            echo "You need to install PKGNG on your FreeBSD before runing this script."
            echo See this: https://wiki.freebsd.org/pkgng
            return 87
        fi

    elif [ "$kernel" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu with apt-get
            sudo apt-get install -y $1
            return $?
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora/CentOS with dnf
            sudo dnf install -y $1
            return $?
        elif command -v yum >/dev/null 2>&1; then
            # Fedora/CentOS with yum
            sudo yum install -y $1
            return $?
        elif command -v ipkg >/dev/null 2>&1; then
            # Embedded Device with ipkg
            sudo ipkg install $1
            return $?
        elif command -v opkg >/dev/null 2>&1; then
            # Embedded Device with opkg
            sudo opkg install $1
            return $?
        fi
    fi
}

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
        if askQuestion "Do you want to install git?"; then
            makeInstall git
        fi
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

    # Ask for installing
    todo=''
    apps='zsh vim tmux'
    for app in $apps; do
        if ! command -v $app >/dev/null 2>&1; then
            msg="Do you want to install and apply configs about $app?"
        else
            msg="Do you want to apply configs about $app?"
        fi

        if askQuestion "$msg"; then
            todo="$todo $app"
        fi
    done
    if [ "$todo" != "" ]; then
        makeInstall $todo
    fi

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
