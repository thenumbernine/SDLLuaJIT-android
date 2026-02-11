#!/bin/sh
set -x

# image
cp libz.so $LUA_PROJECT_PATH/image/bin/Android/arm/		# needed by libpng.so
cp libpng.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libjpeg.so $LUA_PROJECT_PATH/image/bin/Android/arm/
cp libtiff.so $LUA_PROJECT_PATH/image/bin/Android/arm/

# audio
cp libopenal.so $LUA_PROJECT_PATH/audio/bin/Android/arm/

# imgui
cp libcimgui_sdl3.so $LUA_PROJECT_PATH/imgui/bin/Android/arm/

# gui
cp libbrotlicommon.so $LUA_PROJECT_PATH/gui/bin/Android/arm/
cp libbrotlidec.so $LUA_PROJECT_PATH/gui/bin/Android/arm/
cp libbz2.so $LUA_PROJECT_PATH/gui/bin/Android/arm/
cp libfreetype.so $LUA_PROJECT_PATH/gui/bin/Android/arm/
