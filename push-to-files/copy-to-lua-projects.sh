#!/bin/sh
set -x
cp libcimgui_sdl3.so $LUA_PROJECT_PATH/imgui/bin/Android/arm/
cp libpng.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libz.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libjpeg.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libtiff.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libopenal.so $LUA_PROJECT_PATH/audio/bin/Android/arm/
