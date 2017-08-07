#!/bin/bash
#
#   ob-tile.sh   Copyright (C) 2017 damo    <damo.linux@gmail.com>
#
#   Requires wmctrl and xdotool
#
#   The first run tiles the windows, the second will restore their positions.
#
#   You must first copy the contents of "xdotool-keybinds.xml" into "~/.config/openbox/rc.xml"
#
#############################################################################################

USAGE='
    ob-tile.sh [arg]
    
    -G |--grid      Tile up to 4 quartered windows; a fifth window will be centered;
                    Any others will be left alone.
                    
    -V |--vert      Tile up to 3 windows side by side; a 4th window will be centered;
                    Any others will be left alone.
    
    -H |--horiz     Tile up to 3 windows above and below; a 4th window will be centered;
                    Any others will be left alone.
    
        *           This USAGE.
        
    With no script arguments the windows will be grid tiled, and original positions are not stored.
'

TMP_WIN_LIST=$(mktemp --tmpdir winlist.XXXX)    # stores window ID's
TMP_WIN_DIMS="$HOME/temp-windims.tmp"           # stores geometry for restoring windows
STORE_ARG="$HOME/ob_tiling.tmp"
STORE_WIN_CMDS="$HOME/win_ids.tmp"

# keybinds previously set in rc.xml
arrGRIDKBINDS=(super+alt+7 super+alt+9 super+alt+3 super+alt+1 super+alt+5)         # TL,TR,BR,BL,center
arrVERTKBINDS_2=(super+alt+4 super+alt+6)                                           # Left half,Right half
arrHORIZKBINDS_2=(super+alt+8 super+alt+2)                                          # Top half, Bottom half
arrVERTKBINDS_N=( ctrl+super+alt+4 ctrl+super+alt+5 ctrl+super+alt+6 super+alt+5 )  # L,M,R vert,center
arrHORIZKBINDS_N=( ctrl+super+alt+1 ctrl+super+alt+2 ctrl+super+alt+3 super+alt+5 ) # L,M,R horiz,center

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

testArgs(){     # test command args, see if the command has been repeated.
    a="$1"
    local TILING_OLD
    local TILING_NEW
    
    if [[ -f $STORE_ARG ]] &>/dev/null;then
        TILING_OLD="$(cat "$STORE_ARG")"
    else
        TILING_OLD=0
        echo "$TILING_OLD" > "$STORE_ARG"
    fi

if (( $# == 0 ));then 
    tileGrid
    exit 0
fi
    case "$a" in
        -G|--grid|-H|--horiz|-V|--vert )TILING_NEW="$a"
                                        echo "$TILING_NEW" > "$STORE_ARG"
                                        ;;
        -h |--help) TILING_NEW=0
                    echo "$TILING_NEW" > "$STORE_ARG"
                    exit 0            
                    ;;
        *         ) echo "Unknown script argument"
                    exit 0
                    ;;
    esac

    if [[ $TILING_OLD != "$TILING_NEW" ]] &>/dev/null;then
        if ! diff "$TMP_WIN_DIMS" "$STORE_WIN_CMDS" 2>/dev/null;then
            restoreWindows "$TMP_WIN_DIMS" 2>/dev/null           
        fi

    elif diff "$TMP_WIN_DIMS" "$STORE_WIN_CMDS" 2>/dev/null;then
        restoreWindows "$STORE_WIN_CMDS"            
    else
        restoreWindows "$TMP_WIN_DIMS" 2>/dev/null
    fi
    
}

tileWindows(){  
    num=$1   
    case $2 in
        G     ) arrKB=("${arrGRIDKBINDS[@]}");;
        V2   ) arrKB=("${arrVERTKBINDS_2[@]}");;
        VN   ) arrKB=("${arrVERTKBINDS_N[@]}");;
        H2   ) arrKB=("${arrHORIZKBINDS_2[@]}");;
        HN   ) arrKB=("${arrHORIZKBINDS_N[@]}");;
        *   ) echo "Error"
              exit 1;;
    esac
    
    for (( i=0; i < $num; i++ ));do
        xdotool windowfocus --sync "${arrWIN_ID[$i]}"
        xdotool key --clearmodifiers "${arrKB[$i]}" 
    done
}

tileVert(){
    arrL=${#arrWIN_ID[@]}
    
    if (( $arrL < 3 )) &>/dev/null;then
        tileWindows $arrL "V2"
    else
        tileWindows $arrL "VN"
    fi
}

tileHoriz(){
    arrL=${#arrWIN_ID[@]}
    
    if (( $arrL < 3 )) &>/dev/null;then
        tileWindows $arrL "H2"
    else
        tileWindows $arrL "HN"
    fi
}

tileGrid(){
    arrL=${#arrWIN_ID[@]}
    tileWindows $arrL "G"  
}

getWM_VALUES(){         # get frame and window geometry set by Openbox
    declare -a arrFRAME_EXTENTS arrWIN_EXTENTS
    
    arrFRAME_EXTENTS=( $(xprop -id $id _NET_FRAME_EXTENTS | awk ' {gsub(/,/,"");print $3,$4,$5,$6}') )
    BORDER_L="${arrFRAME_EXTENTS[0]}"
    BORDER_T="${arrFRAME_EXTENTS[2]}"
    
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
        if [[ ! -f $STORE_WIN_CMDS ]] &>/dev/null;then
            echo "$wmctrlCMD" >> "$STORE_WIN_CMDS"
        fi
    done
}

restoreWindows(){   
    while read -r line;do
        eval "$line"
    done < "$1"
}

# test if tempfile exists, containing geometry etc needed by wmctrl.
testRestore(){
    if [[ ! -f "$TMP_WIN_DIMS" ]] &>/dev/null ;then
        touch "$TMP_WIN_DIMS"
        getWindows
    else
        if diff "$TMP_WIN_DIMS" "$STORE_WIN_CMDS" 2>/dev/null;then
            restoreWindows "$STORE_WIN_CMDS"
        else
            cp "$TMP_WIN_DIMS" "$STORE_WIN_CMDS"
            restoreWindows "$STORE_WIN_CMDS"
        fi
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
while read -r line;do
    if grep -Eq -v "(Conky|Tint2)" "$TMP_WIN_LIST" &>/dev/null ;then
        if [[ $(echo "$line" | awk '{print $2}') == $CURRDTOP ]] &>/dev/null;then
            arrWIN_ID[$i]=$(echo "$line" | awk '{print $1}')
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
