--[[ these are set upon app init:
local function showenvvar(var)
	print(var, os.getenv(var))
end
showenvvar'APP_PACKAGE_NAME'
--
showenvvar'APP_FILES_DIR' -- /data/user/0/$APP_PACKAGE_NAME
showenvvar'APP_CACHE_DIR'
showenvvar'APP_DATA_DIR'
-- both /data/app/~~sagOtG7hLwKdTrVfctEkIw==/io.github.thenumbernine.SDLLuaJIT-TabWhHRksmn0DykywPgr_w==/base.apk
showenvvar'APP_RES_DIR'
showenvvar'APP_PACKAGE_CODE_DIR'
-- folder on sdcard?
showenvvar'APP_EXTERNAL_CACHE_DIR'
--exec'set'

-- nothing there
--exec('ls -al '..os.getenv'APP_RES_DIR')
--]]

-- try to access JNI functions ...
require 'java.ffi.jni'	-- cdef for JNIEnv
local ffi = require 'ffi'
ffi.cdef[[JNIEnv * SDLLuaJIT_GetJNIEnv();]]
local main = ffi.load'main'
print('main', main)
local J = require 'java.jnienv'(main.SDLLuaJIT_GetJNIEnv())
print('J', J)

-- alright at this point ...
-- this is just as well 'main()'
-- I could launch the org.libsdl.app.SDLActivity myself and not even bother with the rest
-- TODO this eventually, circumvent all SDL if possible ...
-- but for now I'm using SDL to set things up at least.

-- now why did I even bother with this?
-- because I wanted to access the assets/ folder
local SDLActivity = J.org.libsdl.app.SDLActivity
print('SDLActivity', SDLActivity)
print('verison', SDLActivity:nativeGetVersion())

-- TODO better way to get our running app's activity?
local context = SDLActivity:getContext()
print('context', context)

local M = {}
M.packageName = tostring(context:getPackageName())
print('packageName', M.packageName)

M.appFilesDir = context:getFilesDir():getAbsolutePath()
print('appFilesDir', M.appFilesDir)

M.appResDir = context:getPackageResourcePath()
print('appResDir', M.appResDir)

M.appCacheDir = context:getCacheDir():getAbsolutePath()
print('appCacheDir', M.appCacheDir)

M.appDataDir = context:getDataDir():getAbsolutePath()
print('appDataDir', M.appDataDir)

M.appExtCacheDir = context:getExternalCacheDir():getAbsolutePath()
print('appExtCacheDir', M.appExtCacheDir)

M.appPackageCodeDir = context:getPackageCodePath()
print('appPackageCodeDir', M.appPackageCodeDir)

--[===[ don't need to do this snice I *must* do it on apk startup
local function copyAssetsToFiles()
	local dontCopyFromAssetsFilename = appFilesDir..'/dontcopyfromassets'
	local dontCopyFromAssetsExists = io.open(dontCopyFromAssetsFilename, 'r')
	if not dontCopyFromAssetsExists then
		local assets = context:getAssets()
		print('assets', assets)

		local File = J.java.io.File
		-- TODO lookup ctors and use Object:_new
		local File_init = File:_method{name='<init>', sig={'void', 'java/lang/String'}}

		local InputStream = J.java.io.InputStream
		local FileOutputStream = J.java.io.FileOutputStream
		-- TODO lookup ctors and use Object:_new
		local FileOutputStream_init = FileOutputStream:_method{name='<init>', sig={'void', 'java/io/File'}}
		
		local function copyAssets(f)
			local toPath = appFilesDir..'/'..f
			local toFile = File_init:_newObject(File, toPath)
			local list = assets:list(f)	-- root is ''
			local n = #list
			if n == 0 then
print(f)--, 'is', is, is_close)
				-- no files?  its either not a dir, or its an empty dir
				-- no way to tell in Android, fucking retarded

				local is = asserts:open(f)
				-- do you need to create a new file before an output stream?
				--toFile:createNewFile()
--DEBUG:print'os='
				local os = FileOutputStream_init:_newObject(FileOutputStream, toFile)
				-- java.io.InputStream transferTo ... can JNI get that from the child class as well?
--DEBUG:print'is.copyTo(os)'
				--io:transferTo(os)
				local buf = J:_newArray('byte', 16384)
				while true do
					-- TODO here's a case of symbol overload resolution
					--local res = is:read(buf)
					local res = is:getMethod{name='read', sig={'int', 'byte[]'}}(is, buf)
--DEBUG:print('copied', res)
					if res <= 0 then break end
					--os:write(os, buf, 0, res)
					os:getMethod{name='write', sig={'void', 'byte[]', 'int', 'int'}}(os, buf, 0, res)
				end

--DEBUG:print'is.close()'
				InputStream_close(is)
--DEBUG:print'os.flush()'
				FileOutputStream_flush(os)
--DEBUG:print'os.close()'
				FileOutputStream_close(os)
--DEBUG:print'file done'
			else
				-- is dir so we can mkdirs
				toFile:mkdirs()

				for i=0,n-1 do
					-- how to determine subfolder?
					-- official way?
					-- try to query it with list()
					local subf = list[i]
					local path = f == '' and subf or f..'/'..subf
	--DEBUG:print(path)
					copyAssets(path)
				end
			end
		end
		copyAssets''

		--assert(io.open(dontCopyFromAssetsFilename, 'w')):close()
	end
end
--]===]

return M
