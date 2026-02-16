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
local jniEnv = require 'java.jnienv'(main.SDLLuaJIT_GetJNIEnv())

-- alright at this point ...
-- this is just as well 'main()'
-- I could launch the org.libsdl.app.SDLActivity myself and not even bother with the rest
-- TODO this eventually, circumvent all SDL if possible ...
-- but for now I'm using SDL to set things up at least.

-- now why did I even bother with this?
-- because I wanted to access the assets/ folder
local org_libsdl_app_SDLActivity = jniEnv:findClass'org/libsdl/app/SDLActivity'
local version = org_libsdl_app_SDLActivity:getMethod{
	name = 'nativeGetVersion',
	sig = {'java/lang/String'},
	static = true,
}(org_libsdl_app_SDLActivity)
print('verison', version)

-- alright now
-- try to get our context
local context = org_libsdl_app_SDLActivity:getMethod{
	name = 'getContext',
	sig = {'android/content/Context'},
	static = true,
}(org_libsdl_app_SDLActivity)
print('context', context)

-- I don't need os.getenv'APP_PACKAGE_NAME' now
local packageName = context:getMethod{
	name = 'getPackageName',
	sig = {'java/lang/String'},
}(context)
print('packageName', packageName)

-- I don't need os.getenv'APP_FILES_DIR' now
local filesDirObj = context:getMethod{
	name = 'getFilesDir',
	sig = {'java/io/File'},
}(context)
local appFilesDir = filesDirObj:getMethod{
	name = 'getAbsolutePath',
	sig = {'java/lang/String'},
}(filesDirObj)
print('appFilesDir', appFilesDir)

local haveAssetsBeenCopiedFilename = appFilesDir..'/haveassetsbeencopied'
local haveAssetsBeenCopied = io.open(haveAssetsBeenCopiedFilename, 'r')
if not haveAssetsBeenCopied then
	local assets = context:getMethod{
		name = 'getAssets',
		sig = {'android/content/res/AssetManager'},
	}(context)
	print('assets', assets)

	local assets_list = assets:getMethod{
		name = 'list',
		sig = {'java/lang/String[]', 'java/lang/String'},
	}
	-- so tempting to cache these...
	local assets_open = assets:getMethod{
		name = 'open',
		sig = {'java/io/InputStream', 'java/lang/String'},
	}
	
	local File = jniEnv:findClass'java/io/File'
	local File_init = File:getMethod{name='<init>', sig={'void', 'java/lang/String'}}

	--local InputStream = jniEnv:findClass'java/io/InputStream'
	--local InputStream_transferTo = InputStream:getMethod{name='transferTo', sig={'long', 'java/io/OutputStream'}}

	local InputStream = jniEnv:findClass'java/io/InputStream'
	local InputStream_close = InputStream:getMethod{name='close', sig={}}

	local FileOutputStream = jniEnv:findClass'java/io/FileOutputStream'
	local FileOutputStream_init = FileOutputStream:getMethod{name='<init>', sig={'void', 'java/io/File'}}
	local FileOutputStream_flush = FileOutputStream:getMethod{name='flush', sig={}}
	local FileOutputStream_close = FileOutputStream:getMethod{name='close', sig={}}

	local function copyAssets(f)
		local toPath = appFilesDir..'/'..f
		local toFile = File_init:newObject(File, toPath)
		local list = assets_list(assets, f)	-- root is ''
		local n = #list
		if n == 0 then
print(f)--, 'is', is, is_close)
			-- no files?  its either not a dir, or its an empty dir
			-- no way to tell in Android, fucking retarded
			
			local is = assets_open(assets, f)
			-- do you need to create a new file before an output stream?
			--toFile:getMethod{name='createNewFile', sig={'java/io/File'}}
--DEBUG:print'os='
			local os = FileOutputStream_init:newObject(FileOutputStream, toFile)
			-- java.io.InputStream transferTo ... can JNI get that from the child class as well?
--DEBUG:print'is.copyTo(os)'
			--InputStream_transferTo(is, os)
			local buf = jniEnv:newArray('byte', 16384)
			while true do
				local res = is:getMethod{name='read', sig={'int', 'byte[]'}}(is, buf)
--DEBUG:print('copied', res)				
				if res <= 0 then break end
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
			toFile:getMethod{name='mkdirs', sig={'boolean'}}(toFile)

			for i=0,n-1 do
				-- how to determine subfolder?
				-- official way?
				-- try to query it with list()
				local subf = list:getElem(i)
				local path = f == '' and subf or f..'/'..subf
--DEBUG:print(path)
				copyAssets(path)
			end
		end
	end
	copyAssets''

	--assert(io.open(haveAssetsBeenCopiedFilename, 'w')):close()
end
