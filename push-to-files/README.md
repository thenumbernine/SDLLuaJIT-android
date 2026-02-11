pushing and pulling from the /data/data/pkgname/files/

I'm rpath'ing the Termux libraries to point to `$ORIGIN/..` 

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

... and maybe `libc++_shared.so` ... where should I save that at? here? why not?
