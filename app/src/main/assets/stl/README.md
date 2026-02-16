# STL in Lua

but not really.

It just holds whatever STL classes I tried to reproduce in LuaJIT.

So far it's just `<vector>`

Even at that, I've got two implementations.

One is wrapped in a Lua table for cohesion with `__gc`, the other is a pure `cdata` object that should mimic STL in-memory, useful for casting and interacting with live C++ data.

Depends on my lua-ext project.
