package io.github.thenumbernine.SDLLuaJIT;

import android.content.Context;
import android.os.Bundle;
import android.system.Os;

import java.util.ArrayList;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

public class SDLActivity extends org.libsdl.app.SDLActivity {
	// org.libsdl.app.SDLActivity calls its .mSingleton.get* functions
	// its .mSingleton is set upon first call or something
	// ... any chance that it will always be assigned to my instance of this?
	// I guess the only time it would catch anything else is if in this codebase something else instanciated org.libsdl.app.SDLActivity or another of its subclasses other than this ....
	// I don't trust the SDL lib's java code not to do that...

	protected String[] getLibraries() {
		return new String[]{
				"SDL3",
				"luajit",
				"main"
		};
	}

	protected void copyFromAssetsToFilesIfItDoesntExist(String filename) {
		try {
			// using this ctor does that mean I can only write to getFilesDir() base folder files?  java is so weird.
			File file = new File(getContext().getFilesDir(), filename);
			if (file.exists()) return;

			InputStream is = getContext().getAssets().open(filename);
			FileOutputStream os = new FileOutputStream(file);
			byte[] buf = new byte[16384];
			int len = -1;
			while ((len = is.read(buf)) > 0) {
				os.write(buf, 0, len);
			}
			is.close();
			os.flush();
			os.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	/**
	 * This method is called by SDL before starting the native application thread.
	 * It can be overridden to provide the arguments after the application name.
	 * The default implementation returns an empty array. It never returns null.
	 *
	 * @return arguments for the native application.
	 */
	protected String[] getArguments() {
		String[] arguments = new String[0]; // args to pass it

		// bootloading ...
		// if files/luajit-args doesn't yet exist then write it with a default
		copyFromAssetsToFilesIfItDoesntExist("luajit-args");		// what luajit should do
		copyFromAssetsToFilesIfItDoesntExist("android-launch.lua");	// setup our env to capture stdout
		copyFromAssetsToFilesIfItDoesntExist("android-setup.lua");	// copy the rest of the files over
		// if files/android-launch.lua doesn't yet exist then write it with a default

		try {
			// get args from `/data/data/app/files/luajit-args`
			File file = new File(getContext().getFilesDir(), "luajit-args");
			// Use try-with-resources to ensure the BufferedReader is closed automatically
			BufferedReader br = new BufferedReader(new FileReader(file));
			ArrayList<String> args = new ArrayList<String>();
			// Read each line and process it as long as the line is not null (end of file)
			String line;
			while ((line = br.readLine()) != null) {
				args.add(line);
			}
			arguments = args.toArray(new String[0]);
		} catch (IOException e) {
			// Handle potential IO exceptions (e.g., File not found, permission issues)
			e.printStackTrace();
		}

		// I could modify org.libsdl.app.SDLActivity to have it also pass the JNIEnv into SDL_Main but ...
		// instead I'll just do it here
		// note, this is already done in SDL/src/core/android/SDL_android.c's Android_JNI_getEnv()
		// but it's not extern, and luajit ffi isn't seeing it ...
		nativeSetJNIEnv();

		return arguments;
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {

		// TODO no need to do this anymore, just use android JNI on startup and read from java directly
		Context context = (Context)this;
		try {
			Os.setenv("APP_PACKAGE_NAME", context.getPackageName(), true);
			Os.setenv("APP_FILES_DIR", context.getFilesDir().getAbsolutePath(), true);
			Os.setenv("APP_RES_DIR", context.getPackageResourcePath(), true);
			Os.setenv("APP_CACHE_DIR", context.getCacheDir().getAbsolutePath(), true);
			Os.setenv("APP_DATA_DIR", context.getDataDir().getAbsolutePath(), true);
			Os.setenv("APP_EXTERNAL_CACHE_DIR", context.getExternalCacheDir().getAbsolutePath(), true);
			Os.setenv("APP_PACKAGE_CODE_DIR", context.getPackageCodePath(), true);
		} catch (android.system.ErrnoException e) {}

		super.onCreate(savedInstanceState);
	}

	// maybe I can pass Java pointers back through JNI to LuaJIT ...
	// there's already a "getContext()" in org.libsdl.app.SDLActivity ...
	public static native void nativeSetJNIEnv();
}
