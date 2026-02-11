# SDL+LuaJIT Launcher for Android

This is an Android app with SDL + LuaJIT packaged.

Why SDL?  Because last I checked, the hardware surface creation of Android is tied so closely to the app, which is tied to java, so using SDL's Android demo is a good starting point.

Why LuaJIT?  Because I don't want to write code in Java or C++.

This app is as minimal as possible, it creates the surface, launches LuaJIT, and that's that.

Included is a LuaJIT script for launching under Android which redirects stdout/stderr to a file (since Android OS throws stdout away smh),
chdir's to files (idk maybe it is there by default), and adjusts some library locations to be so's in files/.

# Installing

1) Build.  With AndroidStudio.  Try not to get it to crash.  Hahaha. And then deploy.

2) Create a `luajit-args` file with args to run.
2) Then `adb push luajit-args /data/data/io.github.thenumbernine.SDLLuaJIT/files/`

3) If you are telling it to launch a file or do anything with the filesystem outside its files/ folder, i.e. in the `/sdcard` folder, you will have to go to app permissions and give it all-file permissions.

If all goes well then maybe I'll merge it with `lua-dist` and make it one of the other alternatives alongside win64, linux64, osx, and appimage. But things probably won't go well because the Android development environment is famous for being a giant pile of shit.  Which is why each of those platforms' distributable packages take a script of a few kb to build, while Android needs GIGABYTES to do the equivalent, and do it poorly.

# Want Extra Libraries?

I have been copying binaries from Termux, which at least for me happens to be armv7a.
So to get them working all I have to do is `patchelf` then change the library name, dependency names, and rpath.
I've been setting the `rpath` to `$ORIGIN/..` which happens to resolve to the `files/` folder, and then putting them all there, because Android lets me link libraries there, not so much for other locations.

I've generated LuaJIT bindings to go with most POSIX functions of Termux's android, it's in my `lua-ffi-bindings` project in the `Android/c` folder.

# TODO

- connect the luajit build scripts to the CMakeLists.txt to have it build luajit through Android Studio instead of as a separate shell script.
- right now it just packages the armv7a luajit.  idk even what architecture SDL is on.  TODO would be public universal one for all archs.
- automated script in my lua-dist project for auto-generating the Android build files for some particular appname/classname, and auto-package the luajit contents, to auto-build Android apps:
	- 1) sed all the io.github.thenumbernine.SDLActivity with whatever apk classname for the specific repo
	- 3) setup luajit-args to the init/boostrap file
	- 4) copy the dist package dir over to the /data/data/app/files/
- add a text console output, for non-graphics scripts, pipe stdout/stderr into it, and only create the SDL surface upon SDL request.
- builtin settings to edit the CLI args, option to disable for when using this to package specific apps.
