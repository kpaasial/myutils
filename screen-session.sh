#!/bin/sh


screen_session_cleanup()
{
    if [ -L "${USERSOCKET}" ]; then
        echo "Removing ${USERSOCKET}"
        rm "${USERSOCKET}"
    fi
}


if [ -n "$STY" ]; then
    # Already in a screen session, do nada
    echo "Already in a screen session, not creating a new one."
    exit 1
fi

# Command line arguments

while getopts dn o
do
    case "$o" in
    d)  FORCE_DETACH="yes";;
    n)  IGNORE_AGENT="yes";;
    esac

done

shift $((OPTIND-1))



SCREEN_SESSION=$1

: ${SCREEN_SESSION:="sshwrap"}


USERSOCKET="/tmp/.wrap_auth_sock-${USER}-${SCREEN_SESSION}"

# If forceful detaching of other sessions is requested do it here.
# This should cause the other client session to end and the
# socket link to be deleted.

if [ -n "${FORCE_DETACH}" ]; then
    screen -D -S "${SCREEN_SESSION}"
    sleep 2
    rm -f "${USERSOCKET}"
fi


# Set up symbolic link for ssh agent forwarding

# If there is a non-broken link to a socket do not overwrite it.
# The -d option can be used to detach the other session and
# have the link removed.
# If the link exists but is broken, remove it.
if [ -L "${USERSOCKET}" ]; then
    if [ -e "${USERSOCKET}" ]; then
        echo "Refusing to overwrite existing link, use $0 -d to force detach and re-attach."
        exit 1
    else
        # Remove the broken link
        rm "${USERSOCKET}"
    fi
fi

if [ -n  "$SSH_TTY" ] && [ -n "${SSH_AUTH_SOCK}" ]; then # Ssh connection and agent forwarding is on
    # Set up trap to clean the link automatically
    trap screen_session_cleanup EXIT HUP

    ln -fs "$SSH_AUTH_SOCK" "${USERSOCKET}" # Create the symbolic link
    export SSH_AUTH_SOCK="${USERSOCKET}" # Set SSH_AUTH_SOCK to the link
fi


#export STY="screen-${SCREEN_SESSION}"


screen -d -RR -S "${SCREEN_SESSION}"

