# ccd
Custom Change Directory: `cd` with built-in tree navigator


## Installation
1. Download `ccd.sh` to your Mac
2. Run `echo -e "\n. <path/to>/ccd.sh" >> ~/.bash_profile` to add the alias to your Terminal
3. Restart Terminal (or open a new window) for the changes to take effect

## Usage
- `ccd` to start in the current directory
- to navigate dirs, use up + down arrow keys
- to move into a folder (e.g. open it), use right arrow key
- to move up a level, use left arrow key
- to select a dir, press enter (or space)
- to abort, press Ctrl+C (or esc?)


## TODO
- fix empty directories behavior
- save last-selected dir when moving up a level
- add key to select currently open directory (rather than one of its subfolders)