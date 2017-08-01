#!/bin/bash
##
## tiling-kbinds.sh
##

KBINDS="$HOME/.config/openbox/tiling-kbinds.txt"

yad --text-info --filename="$KBINDS" --width=380 --height=680 --undecorated \
	--no-buttons --margins=20 --borders=0
