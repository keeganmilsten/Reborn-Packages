#!/bin/bash
#
# Simple HTTP server with a (Yad based) GUI, for local network.
#
# Usage: for options, see variable $USAGE below!
#
# Requirements:
#    - python 3
#    - yad
#    - firewall does not prevent the port number this server uses (see $SRV_PORT below)
#    - uses package gksu for certain administrative tasks
#
# You can verify (on the server) that this server is running (or not)
# e.g. with this command:
#    ps -ef | grep http.server | grep -v yad | grep -v grep
#
# A client machine may use the server e.g. with a browser:
#    firefox http://servername-or-ip:portnr
# For example:
#    firefox http://192.168.1.101:8000
#
# Note 1: The http server initially stops all of its existing server instances.
# Note 2: If 'ufw' firewall is enabled, then this http server opens ufw port $SRV_PORT,
#         and after stopping the http server, the port is closed.
#
# Written by: @manuel at Antergos.com
# Date:       2018-01-27
# Changes:    2018-01-29:
#                 - managing only port $SRV_PORT of the firewall (thanks casquinhas!)
#                 - added info about starting directory
#                 - added option --dir=<starting-directory> (thanks Keegan!)


ip=`hostname --ip-address`
export SRV_PORT=8000                                  # port may be changed!
export SRV_COMMAND="python -m http.server $SRV_PORT"  # this implements the server!
export SRV_STATUS="[unknown]"

USAGE="Usage: $0 [--dir=<starting-directory>]"


_message()  # show a message with yad
{
    # User may give extra options (e.g. --geometry=AxB+C+D)
    # before the actual message.
    local opts xx
    for xx in "$@"
    do
        case "$xx" in
            --*) opts+="$xx " ; shift ;;
            *) break ;;
        esac
    done

    local line="$*"
    local width=$((${#line} * 8))
    local width_limit=600
    if [ $width -gt $width_limit ] ; then
        width=$width_limit
    fi

    yad --form --title="Message" \
        --width=$width           \
        --button=gtk-quit:1      \
        --field="":TXT "$line"          $opts
}

Stop()
{
    local yadfield="$1"
    SRV_STATUS=stopped
    echo "$yadfield:$SRV_STATUS"       # output to yad field (Server status)
    if [ $HAS_UFW -eq 1 ] ; then
        gksu -w "ufw delete allow $SRV_PORT/tcp"
    fi
    pkill -fx "$SRV_COMMAND"
}
Start()
{
    local yadfield="$1"
    SRV_STATUS=started
    echo "$yadfield:$SRV_STATUS"       # output to yad field (Server status)
    if [ $HAS_UFW -eq 1 ] ; then
        gksu -w "ufw allow $SRV_PORT/tcp"
    fi
    $SRV_COMMAND >/dev/null &
}
Restart()
{
    local yadfield="$1"
    Stop  "$yadfield"
    Start "$yadfield"
}

export -f Stop Start Restart  # for yad!

Constructor()
{
    # If Firewall (ufw) is on, prepare for disabling port $SRV_PORT while http server is running,
    # and enabling it again when the http server stops.

    HAS_UFW=0
    if [ "$(which ufw 2>/dev/null)" != "" ] ; then              # is ufw installed
        if [[ "$(gksu -w "ufw status")" =~ "active" ]] ; then   # if ufw enabled
           HAS_UFW=1
        fi
    fi

    # Handle user options:
    local xx
    local tmp

    for xx in "$@"
    do
        case "$xx" in
            --dir=*)               # use given starting directory
                tmp="${xx:6}"
                case "$tmp" in
                    ~*) tmp="$HOME"${tmp:1} ;;
                esac
                cd "$tmp"
                ;;
            -*)
                _message "Error: option '$*' not supported.\n$USAGE"
                exit 1
                ;;
        esac
    done
}

# trap "{ gksu -w 'ufw delete allow 8000/tcp' ; }" EXIT   # enable firewall at exit

StartHere()
{
    Constructor "$@"

    local address=$(uname -n):$SRV_PORT
    # If 'uname -n' does not work in your system, use e.g. this:
    # address=$(ip addr | grep "inet " | grep -v "127.0" | head -n 1 | awk '{print $2}' | sed 's|/24||'):$SRV_PORT

    Restart    # There may be old instances, stop them first.

    yad --form \
        --title="Simple HTTP Server at $address" \
        --width=400 \
        --field="Server status":RO    "$SRV_STATUS" \
        --field="Directory root":RO   "$PWD" \
        --field="Start":fbtn          '@bash -c "Restart 1"' \
        --field="Stop":fbtn           '@bash -c "Stop 1"' \
        --field="View Files On PC Hosting Them":fbtn        "xdg-open http://localhost:$SRV_PORT" \
        --field="View Files On PC Recieving Them":fbtn       "xdg-open http://$ip:8000" \
        --button=gtk-quit:1

    Stop
}

StartHere "$@"
