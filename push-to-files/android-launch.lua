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
	ffi.cdef[[int chdir(const char *path);]]
	local function chdir(s)
		local res = ffi.C.chdir((assert(s)))
		assert(res==0, 'chdir '..tostring(s)..' failed')
	end

	-- in Termux I've got this set to $LUA_PROJECT_PATH env var,
	-- but in JNI, no such variables, and barely even env var access to what is there.
	local projectsDir = '/sdcard/Documents/Projects/lua'
	local startDir = projectsDir
	local appDir = '/data/data/io.github.thenumbernine.SDLLuaJIT'
	local appFilesDir = appDir..'/files'
	local libDir = appFilesDir..'/lib'

	chdir(startDir)

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

	ffi.cdef[[int setenv(const char*,const char*,int);]]
	-- let subsequent invoked lua processes know where to find things
	ffi.C.setenv('LUA_PATH', package.path, 1)
	ffi.C.setenv('LUA_CPATH', package.cpath, 1)

	--looks like when build for Android, ffi.os==Linux
	--hot take: it should be "Android"
	assert(ffi.os == 'Linux')
	ffi.os = 'Android'
	-- armv7a has ffi.arch==arm
	print('os', ffi.os, 'arch', ffi.arch, 'jit', jit, 'sizeof(intptr_t)', ffi.sizeof'intptr_t')

	-- setup for libs android
	-- Android only lets me ffi.load if the .so is in appDir
	-- things to do to get libcimgui_sdl3.so to work:
	-- 1) upon build, `patchelf --replace-needed libSDL3.so.0 libSDL3.so libcimgui_sdl3.so` to get around Termux's symlinks to libSDL3.so.0 vs the SDLActivity's libSDL3.so
	-- 2.2) patchelf --set-rpath "\$ORIGIN" libcimgui_sdl3.so
	-- and that will force it to look in the appDir for its dep libc++_shared.so
	os.execute('mkdir -p '..libDir)
	local function setuplib(projectName, libLoadName)
		local libFileName = 'lib'..libLoadName..'.so'
		assert(os.execute(('cp %q %q'):format(
			projectsDir..'/'..projectName..'/bin/Android/arm/'..libFileName,
			libDir..'/')
	))
		require 'ffi.load'[libLoadName] = libDir..'/'..libFileName
	end

	setuplib('audio', 'ogg')
	setuplib('audio', 'openal')
	setuplib('audio', 'vorbis')
	setuplib('audio', 'vorbisenc')	-- needs vorbis
	setuplib('audio', 'vorbisfile')	-- needs vorbis

	setuplib('gui', 'brotlicommon')		-- libbrotlicommon used by libbrotlidec
	setuplib('gui', 'brotlidec')				-- libbrotlidec used by libfreetype
	setuplib('gui', 'bz2')							-- libbz2 used by libfreetype
	setuplib('gui', 'freetype')

	setuplib('image', 'z')							-- libz used by libpng
	setuplib('image', 'png')
	setuplib('image', 'jpeg')
	setuplib('image', 'tiff')

	setuplib('imgui', 'cimgui_sdl3')

	-- last is libc++_shared.so, which libcimgui_sdl3.so depends on.  idk if I should put that in any particular subdir, maybe just here?  or maybe I shoudl put it with libcimgui_sdl3.so so long as that's the only lib that uses it...
	-- how come libcimgui_sdl3.so can find libc++_shared.so no problem, but libopenal.so can't?
	-- TODO this can be packaged in your app....
	assert(os.execute(('cp %q %q'):format(
		'libc++_shared.so',
		libDir..'/')
	))
	-- TODO there's also a libc++_shared.so in /system/lib, we can symlink there too...

	-- vulkan
	os.execute('rm '..libDir..'/libvulkan.so')
	assert(os.execute('ln -s /system/lib/libvulkan.so '..libDir..'/libvulkan.so'))
	require 'ffi.load'.vulkan = libDir..'/libvulkan.so'

	--os.execute('cat '..appFilesDir..'/luajit-args')
	--local f = io.open(appFilesDir..'/luajit-args','w')
	--f:write(projectsDir..'/android-launch.lua\n')
	--f:close()
	--do return end

	--now ... try to run something in SDL+OpenGL
	local dir, run
	arg = {}
	-- [[
	--dir,run='sdl/tests'
	--dir,run='glapp/tests','info.lua'						-- WORKS
	--dir,run='glapp/tests','test_es.lua'					-- WORKS
	--dir,run='glapp/tests','test_geom.lua' 				-- blank, just like desktop when using GLES3
	--dir,run='glapp/tests','test_tex.lua' 					-- WORKS
	--dir,run='glapp/tests','test_uniformblock.lua'			-- WORKS
-- TODO glapp.orbit needs multitouch for pinch-zoom (scroll equiv) and right-click (two finger tap?)
-- TODO imgui ui probably needs bigger to be able to touch anything
	--dir,run='imgui/tests','demo.lua'						-- WORKS
	--dir,run='imgui/tests','console.lua'					-- WORKS, KEYBOARD TOO
	--dir,run='line-integral-convolution','run.lua'			-- got glCheckFramebufferStatus==0
	--dir,run='rule110','rule110.lua'						-- WORKS
	--dir,run='fibonacci-modulo','run.lua'					-- WORKS
	--dir,run='vk/tests','test.lua' 						-- queries physical devices, finds the one with the queue graphics bit, crashes when trying to find the one with surface support ...
	--dir,run,arg='seashell','run.lua', {'usecache'}		-- WORKS but runs slow
	--dir,run='audio/test','test.lua'						-- no errrors, and I don't hear anything...
	--dir,run='sdl/tests','audio.lua'						-- WORKS
	--dir,run='numo9','run.lua',{'-noaudio'}				-- needs me to use uniform buffers instead of uniforms, like on Windows
	--dir,run='lua/tests','test.lua'						-- WORKS
	--dir,run='moldwars','run-cpu.rua'						-- WORKS
	--dir,run='moldwars','run-gpu.rua'						-- WORKS
	--dir,run='moldwars','run-cpu-mt.lua'					-- WORKS
	--dir,run='moldwars','run-cpu-mt.rua'					-- says it cant find langfix from within the thread...
	dir,run='sand-attack','run.lua'							-- WORKS - sound, touch, everything
	--dir,run='chess-on-manifold','run.lua'					-- WORKS but it's slow (I wonder why...)
	--dir,run='platonic-solids','run.lua'					-- WORKS but runs horribly slow, got a glCheckFramebufferStatus==0
	--dir,run='zeta2d','init.lua' 							-- WORKS AND SOUND, but needs touch controls
	--dir,run='zeta3d','init.lua'
	-- pong, but numo9 works as well
	-- kart, but numo9 works as well
	--dir,run='gui/tests','test-gui.lua'						-- WORKS
	--dir,run='gui/tests','test-truetype.lua'					-- WORKS
	--dir,run='TacticsLua','init.lua'
	--dir,run,arg='hydro-cl','run.lua',{'float','verbose'}		--
	--dir,run='solarsystem','graph.lua'							-- needs eph data which is big ... but you could use the subset in earthquake-shear-lines...
	--dir,run='solarsystem','solarsytem.lua'					-- needs eph data which is big ... but you could use the subset in earthquake-shear-lines...
	--dir,run='earthquake-shear-lines','run.rua'				-- will break because it needs wget to download
	--]]

	if dir or run then
		if run:match'%.rua$' then
			require 'ext'
			require 'ext.ctypes'
			require 'langfix'
		end
		chdir(assert(dir))

--debug trace
--debug.sethook(function() print(debug.traceback()) end, 'l')

		assert(loadfile(assert(run)))(table.unpack(arg))
	end
end, function(err)
	print(err, '\n', debug.traceback())
end)

-- need this or else we will lose output.
io.stdout:flush()
io.stderr:flush()
print'DONE launch-android.lua'
io.stdout:flush()
