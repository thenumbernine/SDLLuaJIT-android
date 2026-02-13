#!/bin/sh
# reset the rpath of a so to my SDLLuaJIT files folder
# (is there another rpath I can use? maybe one thats relative or that depends on an env var? Anything that Android authors didn't intentionally cripple because they are dumb?)
patchelf --set-rpath "\$ORIGIN" "$1"
#
# somehow I got libopenal to work one time, and it needs libc++_shared.so, and setting its rpath to ORIGIN/../files isn't working so ...
#patchelf --set-rpath "\$ORIGIN/.." "$1"
# nah that also didn't work...
