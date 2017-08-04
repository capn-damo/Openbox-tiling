#!/bin/bash
#
#   ob-tile.sh   by damo, August 2017
#
#   Requires wmctrl and xdotool

TMPFILE=$(mktemp --tmpdir winlist.XXXX)
USAGE='
    ob-tile.sh [arg]
    
    -G|--grid       Tile up to 4 quartered windows; a fifth window will be centered;
                    Any others will be left alone.
                    
    -V|--vert       Tile 2 windows side by side.
    
    -H|--horiz      Tile 2 windows above and below.
    
        *           This USAGE.
        
    With no script arguments the windows will be grid tiled.
'
arrGRIDKBINDS=(super+alt+7 super+alt+9 super+alt+3 super+alt+1 super+alt+5)
arrVERTKBINDS=(super+alt+4 super+alt+6)
arrHORIZKBINDS=(super+alt+8 super+alt+2)

findArgs(){     # get command args
    for arg in "$@";do
        case "$arg" in
            -G|--grid ) tileGrid;;
            -V|--vert ) tileVert;;
            -H|--horiz) tileHoriz;;
            *         ) echo "$USAGE"
                        exit 0;;
        esac
    done
}

tileWindows(){  
    num=$1   
    case $2 in
        G   ) arrKB=("${arrGRIDKBINDS[@]}");;
        V   ) arrKB=("${arrVERTKBINDS[@]}");;
        H   ) arrKB=("${arrHORIZKBINDS[@]}");;
        *   ) echo "Error"
              exit 1;;
    esac
    
    for (( i=0; i < $num; i++ ));do
        xdotool windowfocus --sync ${arrWIN_ID[$i]} 
        xdotool key --clearmodifiers ${arrKB[$i]} 
    done
}

tileVert(){
    local arg="V"
    arrL=${#arrWIN_ID[@]}
    if (( $arrL < 3 ));then
        tileWindows $arrL $arg
    else
        echo "Only 2 windows should be on the desktop"
        notify-send "Too many windows for this operation.
ob-tile.sh requires only 2 windows."
        exit 0
    fi
}

tileHoriz(){
    local arg="H"
    arrL=${#arrWIN_ID[@]}
    if (( $arrL < 3 ));then
        tileWindows $arrL $arg
    else
        echo "Only 2 windows should be on the desktop"
        notify-send "Too many windows for this operation.
ob-tile.sh requires only 2 windows."
        exit 0
    fi
}

tileGrid(){
    local arg="G"
    arrL=${#arrWIN_ID[@]}
    tileWindows $arrL $arg  
}

# get window list, save to tempfile
wmctrl -lx > "$TMPFILE"

declare -a arrWIN_ID

# read window list, get window ID's on current desktop
CURRDTOP=$(xprop -root _NET_CURRENT_DESKTOP | tail -c -2) # desktop number

# loop through windows, send OB keybinds to each
i=0
while read line;do
    if grep -Eq -v "(Conky|Tint2)" "$TMPFILE";then
        if [[ $(echo $line | awk '{print $2}') == $CURRDTOP ]];then
            arrWIN_ID[$i]=$(echo $line | awk '{print $1}')
            ((i+=1))
        fi
    fi
done < "$TMPFILE"

if (( "$#" == 0 ));then
    tileGrid            # no script args
else
    findArgs "$@"
fi

rm "$TMPFILE"
