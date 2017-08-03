#!/bin/bash
##
## win-tile.sh

TMPFILE=$(mktemp --tmpdir winlist.XXXX)

arrGRIDKBINDS=(super+alt+7 super+alt+9 super+alt+3 super+alt+1 super+alt+5)
arrVERTKBINDS=(super+alt+4 super+alt+6)
arrHORIZKBINDS=(super+alt+8 super+alt+2)

findArgs(){     # get command args
    for arg in "$@";do
    echo "arg= $arg"
        case "$arg" in
            --grid ) tileGrid;;
            --vert ) tileVert;;
            --horiz) tileHoriz;;
            *      ) echo "Help!"
                     exit 0;;
        esac
    done
}

tileWindows(){  
    num=$1
    local arg=$2
    if [[ $2 == V ]];then
        arrKB=("${arrVERTKBINDS[@]}")
    elif [[ $2 == H ]];then
        arrKB=("${arrHORIZKBINDS[@]}")
    elif [[ $2 == G ]];then
        arrKB=("${arrGRIDKBINDS[@]}")
    fi
    
    for (( i=0; i < $num; i++ ));do
    echo "winID= ${arrWIN_ID[$i]} keys= ${arrKB[$i]}"
        xdotool windowactivate --sync ${arrWIN_ID[$i]} key --clearmodifiers ${arrKB[$i]} sleep 0.2
    done
}

tileVert(){
    local arg="V"
    arrL=${#arrWIN_ID[@]}
    if (( $arrL < 3 ));then
        tileWindows $arrL $arg
    fi
}

tileHoriz(){
    arg="H"
    arrL=${#arrWIN_ID[@]}
    if (( $arrL < 3 ));then
        tileWindows $arrL $arg
    fi
}

tileGrid(){
    arg="G"
    arrL=${#arrWIN_ID[@]}
    tileWindows $arrL $arg  
}
wmctrl -lx > "$TMPFILE"

declare -a arrWIN_ID

CURRDTOP=$(xprop -root _NET_CURRENT_DESKTOP | tail -c -2) # desktop number

i=0
while read line;do
    if grep -Eq -v "(Conky|Tint2)" "$TMPFILE";then
        if [[ $(echo $line | awk '{print $2}') == $CURRDTOP ]];then
            arrWIN_ID[$i]=$(echo $line | awk '{print $1}')
            ((i+=1))
        fi
    fi
done < "$TMPFILE"

findArgs $@

rm "$TMPFILE"
