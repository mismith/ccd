#!/bin/bash

function ccd() {
  # some concepts adapted from: https://bbs.archlinux.org/viewtopic.php?id=105732

  ORIGINAL_IFS=$IFS
  IFS=$'\n'
  DIRS=(`CLICOLOR_FORCE=1 ls -lad */`)
  IFS=$ORIGINAL_IFS

  TOTAL_NUMBER=${#DIRS[@]} # total number of items
  DIRS+=(..) # store hidden "up-a-level" dir

  # TODO [[ $TOTAL_NUMBER -lt 1 ]] && exit 1 # no subfolders

  # TODO: [[ $TOTAL_NUMBER -gt $(( `tput lines` - 1 )) ]] && exit 3 # more items than rows

  # keys
  ESCAPE="`echo -e '\x1b'`" # escape-character
  ARROW_UP="`echo -e '\x1b[A'`" # arrow up
  ARROW_DOWN="`echo -e '\x1b[B'`" # arrow down
  ARROW_RIGHT="`echo -e '\x1b[C'`" # arrow right
  ARROW_LEFT="`echo -e '\x1b[D'`" # arrow left
  NEWLINE="`echo -e '\n'`" # newline

  # clear current output
  clearlist() {
    for j in `seq 1 $(( $TOTAL_NUMBER + 1 ))`
    do
      tput cuu1 # move up a line
      tput el # clear line
    done
    tput cud $(( $TOTAL_NUMBER + 1 )) # return cursor to starting position
  }

  { # capture stdout to stderr

    CURRENT_POSITION=1 # current position
    END=false
    RECURSE=false

    pwd

    while ! $END
    do
      for i in `seq 1 $TOTAL_NUMBER`
      do
        echo -n "  "
        [[ $CURRENT_POSITION == $i ]] && tput rev # reverse styling if currently selected item
        echo -e "${DIRS[$i - 1]}"
        tput sgr0 # reset all styles
      done

      read -sn 1 KEY
      [[ "$KEY" == "$ESCAPE" ]] &&
      {
        read -sn 2 ESCAPED_KEY
        KEY="$KEY$ESCAPED_KEY"
      }

      case "$KEY" in
        "$ARROW_UP")
          CURRENT_POSITION=$(( CURRENT_POSITION - 1 )) # move selector up
          [[ $CURRENT_POSITION == 0 ]] && CURRENT_POSITION=$TOTAL_NUMBER # loop
          ;;
        "$ARROW_DOWN")
          CURRENT_POSITION=$(( CURRENT_POSITION + 1 )) # move selector down
          [[ $CURRENT_POSITION == $(( TOTAL_NUMBER + 1 )) ]] && CURRENT_POSITION=1 # loop
          ;;
        "$ARROW_RIGHT")
          # move into this folder, then load its subdirectories in place
          clearlist
          SELECTED=true
          END=true
          RECURSE=true
          ;;
        "$ARROW_LEFT")
          # cd up a level and load its subdirectories in place
          CURRENT_POSITION=$(( TOTAL_NUMBER + 1 )) # use hidden dir
          clearlist
          SELECTED=true
          END=true
          RECURSE=true
          ;;
        "$NEWLINE")
          SELECTED=true
          END=true
          ;;
      esac

      tput cuu $TOTAL_NUMBER # move cursor to top for next time
    done

    $RECURSE && tput cuu 1 || tput cud $TOTAL_NUMBER # move cursor back to bottom if done, or very top if recursing

  } >&2 # end capture

  # parse the folder name out from ls's output
  DIR="${DIRS[$CURRENT_POSITION - 1]##*:}" # remove all chars until (and including) ":"
  DIR="${DIR#* }" # trim all chars until (and including) first " "
  DIR="$(echo $DIR | sed $'s,\x1b\\[[0-9;]*[a-zA-Z],,g')" # strip coloring/formatting to get raw string

  $SELECTED && cd "${DIR}"
  $RECURSE && ccd
}