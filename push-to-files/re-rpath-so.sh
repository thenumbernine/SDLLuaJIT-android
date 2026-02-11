#!/bin/sh
# reset the rpath of a so to my SDLLuaJIT files folder
# (is there another rpath I can use? maybe one thats relative or that depends on an env var? Anything that Android authors didn't intentionally cripple because they are dumb?)
patchelf --set-rpath /data/data/io.github.thenumbernine.SDLLuaJIT/files "$1"
