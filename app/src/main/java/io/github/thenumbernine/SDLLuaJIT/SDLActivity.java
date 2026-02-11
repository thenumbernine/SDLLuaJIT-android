package io.github.thenumbernine.SDLLuaJIT;

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
        return new String[] {
            "SDL3",
            "luajit",
            "main"
        };
    }

    /**
     * This method is called by SDL before starting the native application thread.
     * It can be overridden to provide the arguments after the application name.
     * The default implementation returns an empty array. It never returns null.
     * @return arguments for the native application.
     */
    protected String[] getArguments() {
        File filesDir = getContext().getFilesDir();
        String[] arguments = new String[]{ // args to pass it
            filesDir.getAbsolutePath()		// pass the cwd last and within SDL_main pick it out so we know where to chdir() into at the start
        };

		try {
            // get args from `/data/data/app/files/luajit-args`
            File file = new File(filesDir, "luajit-args");
            // Use try-with-resources to ensure the BufferedReader is closed automatically
            BufferedReader br = new BufferedReader(new FileReader(file));
            ArrayList<String> args = new ArrayList<String>();
            // Read each line and process it as long as the line is not null (end of file)
            String line;
            while ((line = br.readLine()) != null) {
                args.add(line);
            }
            args.add(arguments[0]); // add cwd last
            arguments = args.toArray(new String[0]);
        } catch (IOException e) {
            // Handle potential IO exceptions (e.g., File not found, permission issues)
            e.printStackTrace();
        }

		return arguments;
	}
};
