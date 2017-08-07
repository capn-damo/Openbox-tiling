# Openbox-tiling

`ob-tile.sh`    Script to tile windows on current desktop;

`grid-tile.sh`  Simple script to tile 4 windows in a grid;

`tiling-keybinds.xml`   Keybinds for tiling windows in Openbox, using numpad keys;

`display-kbinds.sh`     Script to display manual numpad keybinds in a yad dialog window;

USAGE
-----
Copy the contents of `xdotool-keybinds.xml` into your `~/.config/openbox.rc.xml`, 
ensuring that any other tiling commands are removed first.

See `ob-tile -h|--help` for usage.

DISPLAY KEYBINDS
----------------
To display the manual numpad keybinds, copy `tiling-kbinds.sh` to your $PATH, and make it executable;
then copy `tiling-kbinds.txt` to `~/.config/openbox/`;

To create a keybind to show them in a yad dialog window: for example
```
    <!-- Show tiling keybinds in yad window -->
    <keybind key="C-Menu">
      <action name="Execute">
        <command>tiling-kbinds.sh</command>
      </action>
    </keybind>
```

ICONS
-----
If you would like to use launchers to run the grid/vertical/horizontal commands then copy the
icons to eg `~/.icons` or `/usr/share/pixmaps`.
