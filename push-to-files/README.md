pushing and pulling from the /data/data/pkgname/files/

I'm rpath'ing the Termux libraries to point here cuz I can only get them to link using an absolute rpath
(can I put env vars in it? what env var has the package files folder anyways?)

here's the libraries:
	in image/bin/Android/arm
		`libz.so`
		`libpng.so`
		`libtiff.so`
		`libjpeg.so`
	in audio/bin/Android/arm
		`libopenal.so`
	in imgui/bin/Android/arm
		`libcimgui_sdl3.so`

... and maybe `libc++_shared.so`
