getpass() {
    echo -n "Password: " > /dev/stderr
    read -s
    echo $REPLY
    echo > /dev/stderr
}
