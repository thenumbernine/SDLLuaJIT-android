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
	
	-- first chdir to our lua projects root
	ffi.cdef[[
int chdir(const char *path);
]]
	local startDir = '/sdcard/Documents/Projects/lua'
	ffi.C.chdir(startDir)

	local appFilesDir = '/data/data/io.github.thenumbernine.SDLLuaJIT/files'

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

	-- can we even get env cmd PWD?
	-- no.   not without os.execute 'set'.
	ffi.cdef[[
char * getcwd(const char *name);
]]
	--print('PWD', os.getenv'PWD')		-- os.getenv returning nil...
	--print('PWD', ffi.C.getcwd'PWD')	-- ffi.C.getenv returns NULL...
	--os.execute'set'					-- set says PWD exists...
	-- but nothing in 'set' pertains to io.github.thenumbernine.SDLLuaJIT

	--looks like when build for Android, ffi.os==Linux
	--hot take: it should be "Android"
	assert(ffi.os == 'Linux')
	ffi.os = 'Android'
	-- armv7a has arch==arm
	print('os', ffi.os, 'arch', ffi.arch)

	-- setup for libs android

	--ffi.cdef[[void android_update_LD_LIBRARY_PATH(const char*);]]
	--ffi.C.android_update_LD_LIBRARY_PATH(appFilesDir)
	-- not in libc
	--local libdl = ffi.load'dl'
	--libdl.android_update_LD_LIBRARY_PATH(appFilesDir)
	-- not in libdl either

	--[=[ getenv and setenv for os and ffi.C had problems before,....
	ffi.cdef[[
char * getenv(const char*);
int setenv(const char*, const char*, int);
int putenv(const char*);
]]
	local libPath = ffi.C.getenv'LD_LIBRARY_PATH'
	--print('LD_LIBRARY_PATH', libPath ~= nil and ffi.string(libPath) or '(null)')	-- nil
	local function setenv(k,v) ffi.C.setenv(k,v,1) end
	--local function setenv(k,v) ffi.C.putenv(k..'='..v) end
	setenv('PATH', appFilesDir)
	setenv('LD_LIBRARY_PATH', appFilesDir)
	setenv('SDP_LIBRARY_PATH', appFilesDir)
	setenv('ASDP_LIBRARY_PATH', appFilesDir)
	setenv('DYLD_LIBRARY_PATH', appFilesDir)
	--]=]

	-- Android only lets me ffi.load if the .so is in appFilesDir
	--
	-- things to do to get libcimgui_sdl3.so to work:
	-- 1) upon build, `patchelf --replace-needed libSDL3.so.0 libSDL3.so libcimgui_sdl3.so` to get around Termux's symlinks to libSDL3.so.0 vs the SDLActivity's libSDL3.so
	-- 2.1) patchelf --remove-rpath libcimgui_sdl3.so
	-- 2.2) patchelf --add-rpath /data/data/io.github.thenumbernine.SDLLuaJIT/files libcimgui_sdl3.so
	-- and that will force it to look in the appFilesDir for its dep libc++_shared.so
	--
	require 'ffi.load'.z = appFilesDir..'/libz.so'
	require 'ffi.load'.png = appFilesDir..'/libpng.so'
	require 'ffi.load'.jpeg = appFilesDir..'/libjpeg.so'
	require 'ffi.load'.tiff = appFilesDir..'/libtiff.so'
	require 'ffi.load'.openal = appFilesDir..'/libopenal.so'
	require 'ffi.load'.cimgui_sdl3 = appFilesDir..'/libcimgui_sdl3.so'

	--now ... try to run something in SDL+OpenGL
	local dir, run 
	arg = {}
	-- [[ 
	--ffi.C.chdir'sdl/tests' -- stuck on desktop-GL until I force init gl.setup to OpenGLES3... 
	--dir, run = 'glapp/tests', 'info.lua'						-- WORKS
	--dir, run = 'glapp/tests', 'test_es.lua'					-- WORKS
	--dir, run = 'glapp/tests', 'test_geom.lua' 				-- blank, just like desktop when using GLES3
	--dir, run = 'glapp/tests', 'test_tex.lua' 					-- WORKS 
	--dir, run = 'glapp/tests', 'test_uniformblock.lua'			-- WORKS
-- TODO glapp.orbit needs multitouch for pinch-zoom (scroll equiv) and right-click (two finger tap?)
-- TODO imgui ui probably needs bigger to be able to touch anything	
	--dir, run = 'imgui/tests', 'demo.lua'						-- WORKS
	--dir, run = 'imgui/tests', 'console.lua'					-- WORKS, KEYBOARD TOO
	--dir, run = 'line-integral-convolution', 'run.lua'			-- got glCheckFramebufferStatus == 0
	--dir, run = 'rule110', 'rule110.lua'						-- WORKS
	--dir, run = 'fibonacci-modulo', 'run.lua'					-- WORKS
	--dir, run = 'vk/tests', 'test.lua' 						-- crashes
	--dir,run,arg = 'seashell', 'run.lua', {'usecache'}			-- WORKS but runs slow
	dir,run = 'numo9','run.lua'									-- needs image.ffi.zlib to be fixed
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
io.stdout:flush()
io.stderr:flush()
