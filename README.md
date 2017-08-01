# Openbox-tiling
Keybinds for tiling windows in Openbox

Requires `yad`

Copy the contents of `rc.xml.tiling` into your `~/.config/openbox.rc.xml`, ensuring that any other tiling commands are removed first.

To display the keybinds, copy `tiling-kbinds.sh` to your $PATH, and make it executable;
then copy `tiling-kbinds.sh` to `~/.config/openbox/`;

To create a keybind to show them in a yad dialog window: for example
```
    <!-- Show tiling keybinds in yad window -->
    <keybind key="C-Menu">
      <action name="Execute">
        <command>tiling-kbinds.sh</command>
      </action>
    </keybind>
```
