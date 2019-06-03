#auto startx
#if [ -z "$DISPLAY" ] && [ $(tty) = /dev/tty1 ]; then
#  startx
# does nothing as the GUI will start x itself
#fi