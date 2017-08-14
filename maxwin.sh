#!/bin/bash
##
## maxwin.sh    Toggle Maximize all windows on current desktop
#
#rc.xml:
#       <keybind key="W-Up">
#           <action name="ToggleMaximize"/>
#       </keybind>
#
########################################################################

KBIND="super+Up"    # rc.xml keybind for ToggleMaximize"
TMP_WIN_LIST=$(mktemp --tmpdir winlist.XXXX)    # stores window ID's

# get window list, save to tempfile
wmctrl -lp > "$TMP_WIN_LIST"

# read window list, get window ID's on current desktop
CURRDTOP=$(xprop -root _NET_CURRENT_DESKTOP | tail -c -2) # desktop number

declare -a arrWIN_ID

# loop through windows, add to windows array
i=0
while read -r line;do
    if grep -Eq -v "(Conky|Tint2)" "$TMP_WIN_LIST" &>/dev/null ;then
        if [[ $(echo "$line" | awk '{print $2}') == $CURRDTOP ]] &>/dev/null;then
            arrWIN_ID[$i]=$(echo "$line" | awk '{print $1}')
            ((i+=1))
        fi
    fi
done < "$TMP_WIN_LIST"

arrL=${#arrWIN_ID[@]}
i=0

# send Openbox keybind to each window
for (( i=0; i < $arrL; i++ ));do
    xdotool windowfocus --sync "${arrWIN_ID[$i]}"
    xdotool key --clearmodifiers "$KBIND" 
    #sleep 0.1
done

rm "$TMP_WIN_LIST"
exit 0
