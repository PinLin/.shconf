#!/bin/sh

REPO_NAME=".shconf"
REPO_URL="https://github.com/PinLin/$REPO_NAME"

# Install application
makeInstall() {
    # Check counts of arguments
    if [ $# -lt 1 ]
    then
        return -1
    fi
    
    # Judge which is the package manager we used
    kernel=$(uname -s)
    if [ "$kernel" = "Darwin" ]
    then
        if command -v brew > /dev/null 2>&1
        then
            # macOS with brew
            brew install $1
            return $?
        else
            echo "You need to install Homebrew on your macOS before runing this script."
            echo See this: https://brew.sh
            return 87
        fi
        
    elif [ "$kernel" = "FreeBSD" ]
    then
        if command -v pkg > /dev/null 2>&1
        then
            # FreeBSD with pkg
            sudo pkg install -y $1
            return $?
        else
            echo "You need to install PKGNG on your FreeBSD before runing this script."
            echo See this: https://wiki.freebsd.org/pkgng
            return 87
        fi
        
    elif [ "$kernel" = "Linux" ]
    then
        if command -v lsb_release > /dev/null 2>&1
        then
            os=$(echo $(lsb_release -i | cut -d ':' -f 2))
        else
            os=''
        fi

        case $os in
            "Debian"|"Ubuntu")
                # Debian/Ubuntu with apt-get
                sudo apt-get install -y $1
                return $?
            ;;

            "Fedora"|"CentOS")
                if command -v dnf > /dev/null 2>&1
                then
                    # Fedora/CentOS with dnf
                    sudo dnf install -y $1
                    return $?
                else
                    # Fedora/CentOS with yum
                    sudo yum install -y $1
                    return $?
                fi
            ;;

            *)
                if command -v ipkg > /dev/null 2>&1
                then
                    # Embedded Device with ipkg
                    sudo ipkg install $1
                    return $?
                fi

                if command -v opkg > /dev/null 2>&1
                then
                    # Embedded Device with opkg
                    sudo opkg install $1
                    return $?
                fi
            ;;
        esac
    fi 
}


# Ask for question
askQuestion() {
    # Check counts of arguments
    if [ $# -lt 2 ]
    then
        return -1
    fi

    # Ask
    if [ "$2" = "Yn" ]
    then
        # Display question and default yes
        echo -n $1 [Y/n]' '; read ans
        case $ans in
            [Nn*])
                return 1
                ;;
            *)
                return 0
                ;;
        esac
    else
        # Display question and default no
        echo -n $1 [y/N]' '; read ans
        case $ans in
            [Yy*]) 
                return 0
                ;;
            *) 
                return 1
                ;;
        esac
    fi
}


main() {
    # Check git
    if ! command -v git > /dev/null 2>&1
    then
        echo "This installer uses git to clone the configs to localhost."
        if askQuestion "Do you want to install git?" "Yn"
        then
            makeInstall git
        fi
    fi

    # Remove old one
    if [ -d ~/$REPO_NAME ]
    then
        rm -rf ~/$REPO_NAME
    fi
    
    # Clone repo to local
    git clone $REPO_URL ~/$REPO_NAME
    if [ $? != 0 ]
    then
        echo "Failed to clone $REPO_NAME."
        return 1
    fi

    # Ask for installing
    todo=''
    apps='zsh vim tmux'
    for app in $apps
    do
        if ! command -v $app > /dev/null 2>&1
        then
            msg="Do you want to install and apply configs about $app?"
        else
            msg="Do you want to apply configs about $app?"
        fi

        if askQuestion "$msg" "Yn"
        then
            todo="$todo $app"
        fi
    done
    if [ "$todo" != "" ]
    then
        makeInstall $todo
    fi
    
    # Apply configs about zsh
    if echo $todo | grep zsh > /dev/null
    then
        # Require oh-my-zsh
        if ! [ -d ~/.oh-my-zsh ]
        then
            if command -v curl > /dev/null 2>&1
            then
                sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
            else
                sh -c "$(wget -qO- https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env zsh -l//g')"
            fi
        fi
        # Install zsh-autosuggestions
        if ! [ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions ]
        then
            git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        fi
        # Install zsh-syntax-highlighting
        if ! [ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting ]
        then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        fi
        if [ -f ~/.zshrc ]
        then
            mv ~/.zshrc ~/.zshrc.bak
        fi
        echo "source ~/$REPO_NAME/config/zsh/sample.zshrc" >> ~/.zshrc
    fi
    
    # Apply configs about vim
    if echo $todo | grep vim > /dev/null
    then
        if [ -f ~/.vimrc ]
        then
            mv ~/.vimrc ~/.vimrc.bak
        fi
        echo "source ~/$REPO_NAME/config/vim/sample.vimrc" >> ~/.vimrc
    fi
    
    # Apply configs about tmux
    if echo $todo | grep tmux > /dev/null
    then
        if [ -f ~/.tmux.conf ]
        then
            mv ~/.tmux.conf ~/.tmux.conf.bak
        fi
        echo "source ~/$REPO_NAME/config/tmux/sample.tmux.conf" >> ~/.tmux.conf
    fi
    
    # Finished
    echo
    echo Done! $REPO_NAME was installed.
}

main
