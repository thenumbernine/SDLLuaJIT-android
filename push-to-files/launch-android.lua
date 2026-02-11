--[[
ok the SDL+OpenGL+LuaJIT launcher is the package io.github.thenumbernine.SDLLuaJIT
the launch activity is io.github.thenumbernine.SDLLuaJIT.SDLActivity
it can be launched from termux with `am start -n io.github.thenumbernine.SDLLuaJIT/io.github.thenumbernine.SDLLuaJIT.SDLActivity`)
it is going to read the file in /data/data/io.github.thenumbernine.SDLLuaJIT/files/luajit-args to tell what to do
each line is a separate CLI arg
the first file it encounters is what it will launch
so I've set that (with `adb push luajit-args /data/local/tmp/` `adb shell run-as io.github.thenumbernine.SDLLuaJIT cp /data/local/tmp/luajit-args /data/data/io.github.thenumbernine.SDLLuaJIT/files/`)
with the file contents set to `/sdcard/Documents/Projects/lua/launch-android`
and that brings us here.

stdout/stderr DO NOT WORK
BECAUSE ANDROID FUCKING PIPES THEM INTO THE SHITTER BY DEFAULT
so the first thing we have to do is fix the Google dev team's incompetence.
NOTICE that SDLActivity sets cwd to its files folder,
so cwd is `/data/data/io.github.thenumbernine.SDLLuaJIT/files` at present.
--]]
xpcall(function()
	local ffi = require 'ffi'

	-- in Termux I've got this set to $LUA_PROJECT_PATH env var,
	-- but in JNI, no such variables, and barely even env var access to what is there.
	local projectsDir = '/sdcard/Documents/Projects/lua'
	local appFilesDir = '/data/data/io.github.thenumbernine.SDLLuaJIT/files'

	-- first chdir to our lua projects root
	ffi.cdef[[
int chdir(const char *path);
]]
	local startDir = projectsDir
	ffi.C.chdir(startDir)

	-- next redirect stdout and stderr to ./out.txt
	ffi.cdef[[
struct FILE;
typedef struct FILE FILE;
FILE * freopen(const char * filename, const char * modes, FILE * stream);
extern FILE * stdin;
extern FILE * stdout;
extern FILE * stderr;
]]
	local newstdoutfn = 'out.txt'	-- relative to cwd
	ffi.C.freopen(newstdoutfn, 'w+', ffi.C.stdout)
	ffi.C.freopen(newstdoutfn, 'w+', ffi.C.stderr)
	io.stdout:flush()
	io.stderr:flush()
	io.output(io.stdout)	-- I thought doing this would help io.flush() work right but meh
	-- if we error before this point then we won't see it anyways

	-- [[ old print doesn't flush new stdout ?
	local oldprint = print
	print = function(...)
		oldprint(...)
		io.flush()
	end
	--]]

	print'BEGIN launch-android.lua'

	-- setup LUA_PATH and LUA_CPATH here
	package.path = table.concat({
		'./?.lua',
		startDir..'/?.lua',
		startDir..'/?/?.lua',
	}, ';')
	package.cpath = table.concat({
		'./?.so',
		startDir..'/?.so',
		startDir..'/?/init.so',
	}, ';')

	--looks like when build for Android, ffi.os==Linux
	--hot take: it should be "Android"
	assert(ffi.os == 'Linux')
	ffi.os = 'Android'
	-- armv7a has ffi.arch==arm
	print('os', ffi.os, 'arch', ffi.arch)

	-- setup for libs android

	-- Android only lets me ffi.load if the .so is in appFilesDir
	--
	-- things to do to get libcimgui_sdl3.so to work:
	-- 1) upon build, `patchelf --replace-needed libSDL3.so.0 libSDL3.so libcimgui_sdl3.so` to get around Termux's symlinks to libSDL3.so.0 vs the SDLActivity's libSDL3.so
	-- 2.2) patchelf --set-rpath "\$ORIGIN/../files" libcimgui_sdl3.so
	-- and that will force it to look in the appFilesDir for its dep libc++_shared.so
	--
	require 'ffi.load'.z = appFilesDir..'/libz.so'
	require 'ffi.load'.png = appFilesDir..'/libpng.so'
	require 'ffi.load'.jpeg = appFilesDir..'/libjpeg.so'
	require 'ffi.load'.tiff = appFilesDir..'/libtiff.so'
	require 'ffi.load'.openal = appFilesDir..'/libopenal.so'
	require 'ffi.load'.cimgui_sdl3 = appFilesDir..'/libcimgui_sdl3.so'

	-- can I copy from projectsDir/projectName/bin/Android/arm/libraryName to appFilesDir/ from within the SDLLuaJIT app?
	assert(os.execute(('cp %q %q'):format(projectsDir..'/image/bin/Android/arm/libz.so', appFilesDir..'/')))
	assert(os.execute(('cp %q %q'):format(projectsDir..'/image/bin/Android/arm/libpng.so', appFilesDir..'/')))
	assert(os.execute(('cp %q %q'):format(projectsDir..'/image/bin/Android/arm/libjpeg.so', appFilesDir..'/')))
	assert(os.execute(('cp %q %q'):format(projectsDir..'/image/bin/Android/arm/libtiff.so', appFilesDir..'/')))
	assert(os.execute(('cp %q %q'):format(projectsDir..'/imgui/bin/Android/arm/libcimgui_sdl3.so', appFilesDir..'/')))
	assert(os.execute(('cp %q %q'):format(projectsDir..'/audio/bin/Android/arm/libopenal.so', appFilesDir..'/')))
	-- last is libc++_shared.so, which libcimgui_sdl3.so depends on.  idk if I should put that in any particular subdir, maybe just here?  or maybe I shoudl put it with libcimgui_sdl3.so so long as that's the only lib that uses it...

	--now ... try to run something in SDL+OpenGL
	local dir, run
	arg = {}
	-- [[
	--ffi.C.chdir'sdl/tests' -- stuck on desktop-GL until I force init gl.setup to OpenGLES3...
	--dir, run = 'glapp/tests', 'info.lua'						-- WORKS
	--dir, run = 'glapp/tests', 'test_es.lua'					-- WORKS
	--dir, run = 'glapp/tests', 'test_geom.lua' 				-- blank, just like desktop when using GLES3
	--dir, run = 'glapp/tests', 'test_tex.lua' 					-- WORKS
	dir, run = 'glapp/tests', 'test_uniformblock.lua'			-- WORKS
-- TODO glapp.orbit needs multitouch for pinch-zoom (scroll equiv) and right-click (two finger tap?)
-- TODO imgui ui probably needs bigger to be able to touch anything
	--dir, run = 'imgui/tests', 'demo.lua'						-- WORKS
	--dir, run = 'imgui/tests', 'console.lua'					-- WORKS, KEYBOARD TOO
	--dir, run = 'line-integral-convolution', 'run.lua'			-- got glCheckFramebufferStatus == 0
	--dir, run = 'rule110', 'rule110.lua'						-- WORKS
	--dir, run = 'fibonacci-modulo', 'run.lua'					-- WORKS
	--dir, run = 'vk/tests', 'test.lua' 						-- crashes
	--dir,run,arg = 'seashell', 'run.lua', {'usecache'}			-- WORKS but runs slow
	--dir,run = 'numo9','run.lua'								-- needs me to reduce uniforms, Windows does too, TODO use uniform blocks.
	--dir, run = 'moldwars', 'run-cpu.rua'						-- WORKS
	--dir, run = 'moldwars', 'run-gpu.rua'						-- WORKS
	--dir, run = 'moldwars', 'run-cpu-mt.lua'					-- needs ffi.Android.c.semaphore
	--dir, run = 'moldwars', 'run-cpu-mt.rua'					-- same
	--dir,run = 'sand-attack','run.lua'							-- WORKS but openal doesnt make sound, and TODO make this touch-capable
	--dir,run = 'chess-on-manifold','run.lua'					-- WORKS but it's slow (I wonder why...)
	--dir,run = 'platonic-solids','run.lua'						-- needs to be GLES3 friendly, get rid of glPolygonMode
	--dir,run = 'zeta2d','init.lua'								-- WORKS AND openal WORKS but needs touch controls
	--dir,run = 'zeta3d','init.lua'
	--dir,run = 'TacticsLua','init.lua'
	-- pong, but numo9 works as well
	-- kart, but numo9 works as well
	--]]

	if dir or run then
		if run:match'%.rua$' then
			local before = loadfile
			require 'ext'
			require 'ext.ctypes'
			require 'langfix'
			assert(loadfile ~= before, "langfix didn't change loadfile...")
		end
		ffi.C.chdir(assert(dir))
		assert(loadfile(assert(run)))(table.unpack(arg))
	end
end, function(err)
	io.stderr:write(err, '\n', debug.traceback())
end)

-- need this or else we will lose output.
print'DONE launch-android.lua'
io.stdout:flush()
io.stderr:flush()
