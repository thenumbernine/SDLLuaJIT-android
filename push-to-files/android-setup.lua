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

TODO now that LuaJIT has Java access, I don't need to set the env vars anymore!
--]]

-- LuaJIT access to JNI ...
require 'java.ffi.jni'	-- cdef for JNIEnv

local ffi = require 'ffi'
ffi.cdef[[JNIEnv * SDLLuaJIT_GetJNIEnv();]]
local main = ffi.load'main'
print('main', main)

local J = require 'java.jnienv'{ptr=main.SDLLuaJIT_GetJNIEnv()}
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

-- [===[ don't need to do this snice I *must* do it on apk startup
function M.copyAssetsToFiles()
	local dontCopyFromAssetsFilename = appFilesDir..'/dontcopyfromassets'
	local dontCopyFromAssetsExists = io.open(dontCopyFromAssetsFilename, 'r')
	if not dontCopyFromAssetsExists then
		local assets = context:getAssets()
		print('assets', assets)

		local File = J.java.io.File
		local FileOutputStream = J.java.io.FileOutputStream
		
		local function copyAssets(f)
			local toPath = appFilesDir..'/'..f
			local toFile = File(toPath)
			local list = assets:list(f)	-- root is ''
			local n = #list
			if n == 0 then
print(f)--, 'is', is, is_close)
				-- no files?  its either not a dir, or its an empty dir
				-- no way to tell in Android, fucking retarded

				local is = asserts:open(f)
				local os = FileOutputStream(toFile)
				-- is:transferTo(os) ... not available in my version?
				local buf = J:_newArray('byte', 16384)
				while true do
					local res = is:read(buf)
					if res <= 0 then break end
					os:write(buf, 0, res)
				end

				is:close()
				os:flush()
				os:close()
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

		-- write that we did copy the files
		assert(io.open(dontCopyFromAssetsFilename, 'w')):close()
	end
end
--]===]

return M
