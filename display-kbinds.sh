#!/bin/bash
##
## tiling-kbinds.sh  by damo, August 2017
##

KBINDS="$HOME/.config/openbox/tiling-kbinds.txt"

ERROR_MSG1="$KBINDS does not exist"
ERROR_MSG2="This script requires 'yad' to be installed"

[[ -f $KBINDS ]] 2>/dev/null || { notify-send "$ERROR_MSG1" >&2;exit 1;}

if type yad &>/dev/null;then
    yad --text-info --filename="$KBINDS" --width=380 --height=500 --undecorated \
    --no-buttons --margins=20 --borders=0
else
    notify-send "$ERROR_MSG2" >&2
    exit 1
fi
