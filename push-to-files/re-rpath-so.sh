#!/bin/sh
# reset the rpath of a so to my SDLLuaJIT files folder
# (is there another rpath I can use? maybe one thats relative or that depends on an env var? Anything that Android authors didn't intentionally cripple because they are dumb?)
# It looks like $ORIGIN is the /data/data/app/bin folder, such that $ORIGIN/../lib/ is the library folder ... which I probably can't write to ... but copying the .so's into files/ and setting rpath to $ORIGIN/.. seems to work, but $ORIGIN/../files/ is where the libraries are going.
patchelf --set-rpath "\$ORIGIN/../files" "$1"
