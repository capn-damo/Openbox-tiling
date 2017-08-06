#!/bin/bash
#
#   ob-tile.sh   by damo, August 2017
#
#   Requires wmctrl and xdotool
#
#   The first run tiles the windows, the second will restore their positions.
#
#############################################################################
USAGE='
    ob-tile.sh [arg]
    
    -G |--grid      Tile up to 4 quartered windows; a fifth window will be centered;
                    Any others will be left alone.
                    
    -V |--vert      Tile 2 windows side by side (only 2 windows must be open)
    
    -H |--horiz     Tile 2 windows above and below (only 2 windows must be open)
    
        *           This USAGE.
        
    With no script arguments the windows will be grid tiled.
'

TMP_WIN_LIST=$(mktemp --tmpdir winlist.XXXX)    # stores window ID's
TMP_WIN_DIMS="$HOME/temp-windims.txt"           # stores geometry for restoring windows
STORE_ARG="$HOME/.config/obtilerc"

# keybinds set in rc.xml
arrGRIDKBINDS=(super+alt+7 super+alt+9 super+alt+3 super+alt+1 super+alt+5)
arrVERTKBINDS=(super+alt+4 super+alt+6)
arrHORIZKBINDS=(super+alt+8 super+alt+2)

icoGrid="$HOME/.icons/tile-grid.png"
icoVert="$HOME/.icons/tile-vert.png"
icoHoriz="$HOME/.icons/tile-horiz.png"

NOTIFY="notify-send -t 3000 -i " 
NOTIFY_TXT='Too many windows for this operation.
ob-tile.sh requires only 2 windows
for vertical tiling.
'

runArgs(){     # get command args
    for arg in "$@";do
        case "$arg" in
            -G|--grid ) tileGrid;;
            -V|--vert ) tileVert;;
            -H|--horiz) tileHoriz;;
            -h |--help) ;;
            *         ) echo "Unknown script argument"
                        exit 0;;
        esac
    done
}

testArgs(){     # get command args, see if the command has been repeated.
    a="$@"
    local oldTiling
    local newTiling
    
    if [[ -f $STORE_ARG ]] &>/dev/null;then
        oldTiling="$(cat $STORE_ARG)"
    else
        oldTiling=0
        echo "$oldTiling" > "$STORE_ARG"
    fi

    case "$a" in
        -G|--grid ) newTiling="$a"
                    echo "$newTiling" > "$STORE_ARG"
                    ;;
        -H|--horiz )  if [[ ${#arrWIN_ID[@]} > 2 ]];then
                                    echo "Only 2 windows should be on the desktop"
                                    $NOTIFY "$icoHoriz" "$NOTIFY_TXT"
                                    newTiling=0
                                    echo "$newTiling" > "$STORE_ARG"
                                    exit 1
                                else
                                    newTiling="$a"
                                    echo "$newTiling" > "$STORE_ARG"
                                fi  
                               ;;
        -V|--vert )  if [[ ${#arrWIN_ID[@]} > 2 ]];then
                                    echo "Only 2 windows should be on the desktop"
                                    $NOTIFY "$icoVert" "$NOTIFY_TXT"
                                    newTiling=0
                                    echo "$newTiling" > "$STORE_ARG"
                                    exit 1
                                else
                                    newTiling="$a"
                                    echo "$newTiling" > "$STORE_ARG"
                                fi  
                               ;;
        -h |--help) newTiling=0
                    echo "$newTiling" > "$STORE_ARG"
                    exit 0            
                    ;;
        ' '       ) ;;  # no args, so grid tile  
        *         ) echo "Unknown script argument"
                    exit 0
                    ;;
    esac

    if [[ $oldTiling != $newTiling ]] &>/dev/null;then
        rm "$TMP_WIN_DIMS" 
    fi
    
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
    if (( $arrL < 3 )) &>/dev/null;then
        tileWindows $arrL $arg
    else
        echo "Only 2 windows should be on the desktop"
        $NOTIFY "$icoVert" "$NOTIFY_TXT"
        exit 0
    fi
}

tileHoriz(){
    local arg="H"
    arrL=${#arrWIN_ID[@]}
    if (( $arrL < 3 )) &>/dev/null;then
        tileWindows $arrL $arg
    else
        echo "Only 2 windows should be on the desktop"
        $NOTIFY "$icoHoriz" "$NOTIFY_TXT"
        exit 0
    fi
}

tileGrid(){
    local arg="G"
    arrL=${#arrWIN_ID[@]}
    tileWindows $arrL $arg  
}

getWM_VALUES(){         # get frame and window geometry set by Openbox
    
    declare -a arrFRAME_EXTENTS arrWIN_EXTENTS
    
    arrFRAME_EXTENTS=( $(xprop -id $id _NET_FRAME_EXTENTS | awk ' {gsub(/,/,"");print $3,$4,$5,$6}') )
    BORDER_L="${arrFRAME_EXTENTS[0]}"
    BORDER_R="${arrFRAME_EXTENTS[1]}"
    BORDER_T="${arrFRAME_EXTENTS[2]}"
    BORDER_B="${arrFRAME_EXTENTS[3]}"
    
    arrWIN_EXTENTS=( $(xwininfo -id $id | grep -E "(Absolute|Width|Height)" | awk '{print $NF}') )
    UPPER_L_X="${arrWIN_EXTENTS[0]}"
    UPPER_L_Y="${arrWIN_EXTENTS[1]}"
    WIDTH="${arrWIN_EXTENTS[2]}"
    HEIGHT="${arrWIN_EXTENTS[3]}"
    
    posX=$((UPPER_L_X - BORDER_L))  # adjust for window borders
    posY=$((UPPER_L_Y - BORDER_T))
}

# save window id's and geometry, for restoring with wmctrl.
getWindows(){   
    for id in "${arrWIN_ID[@]}";do
        getWM_VALUES
        wmctrlCMD="wmctrl -ir $id -e 0,$posX,$posY,$WIDTH,$HEIGHT"
        echo "$wmctrlCMD" >> "$TMP_WIN_DIMS"
    done
}

restoreWindows(){
    while read line;do
        eval $line
#        sleep 0.05
    done < "$TMP_WIN_DIMS"
}

# test if tempfile exists, containing geometry etc needed by wmctrl.
testRestore(){
    if [[ ! -f "$TMP_WIN_DIMS" ]] &>/dev/null ;then
        touch "$TMP_WIN_DIMS"
        getWindows
    else
        restoreWindows
        rm "$TMP_WIN_DIMS"
        exit 0
    fi    
}

if [[ $@ == -h ]] || [[ $@ == --help ]] &>/dev/null;then
    echo "$USAGE"
fi

# get window list, save to tempfile
wmctrl -lp > "$TMP_WIN_LIST"

declare -a arrWIN_ID

# read window list, get window ID's on current desktop
CURRDTOP=$(xprop -root _NET_CURRENT_DESKTOP | tail -c -2) # desktop number

# loop through windows, send OB keybinds to each
i=0
while read line;do
    if grep -Eq -v "(Conky|Tint2)" "$TMP_WIN_LIST" ;then
        if [[ $(echo $line | awk '{print $2}') == $CURRDTOP ]] &>/dev/null;then
            arrWIN_ID[$i]=$(echo $line | awk '{print $1}')
            ((i+=1))
        fi
    fi
done < "$TMP_WIN_LIST"

# see if the comand is repeated, to restore window positions
testArgs "$@"

# see if we are toggling the window positions to their original placement.
testRestore

if (( "$#" == 0 ));then
    tileGrid            # no script args, so just do a grid tile.
else
    runArgs "$@"
fi

rm "$TMP_WIN_LIST"
exit 0
