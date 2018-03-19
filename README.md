# iTunesPlus

![preview](preview.png) 

# Information:

- Designed for macOS 10.9+
- Designed for iTunes 10.0+
- iTunesPlus is a [mySIMBL](https://github.com/w0lfschild/mySIMBL) plugin that adds some features to iTunes
    - Change the dock icon to the now playing track art
        - None
        - Square
        - Tilted square
        - Classic Circular
        - Modern Circular
    - Add badge to app icon when muted or paused
    - Restart iTunes
    - Settings in Dock menu and iTunes+ item in the menubar
- Author: [w0lfschild](https://github.com/w0lfschild)

# Installation:

1. Download [mySIMBL](https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/mySIMBL_master.zip)
2. Download [iTunesPlus](https://github.com/w0lfschild/iTunesPlus/raw/master/build/iTunesPlus.bundle.zip)
3. Unzip downloads
4. Open `iTunesPlus.bundle` with `mySIMBL.app`
5. Disable System Integrity Protection
6. Disable Apple Mobile File Integrity : `sudo nvram boot-args="amfi_get_out_of_my_way=1 "; reboot`
7. Open iTunes

### License:
Pretty much the BSD license, just don't repackage it and call it your own please!    
Also if you do make some changes, feel free to make a pull request and help make things more awesome!
