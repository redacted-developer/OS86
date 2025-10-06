# What is OS86?
OS86 (version 0.1.0) is an in-development project kernel (modular) for 8086 machines, like IBM PC 5000-series.
## How are modules loaded?
The metadata of that program's `.run` file has a list of modules or other programs it needs loaded with it. OS86 will load these before the actual program. This metadata may look a bit like this:
```metadata
mFS;
p.otherprogram.run;
;
```
OS86 is responsible for loading these.
## How does the program know where the dependencies are?
It doesn't implicitly know. It's explicitly told. There's always a 64-byte table of addresses (for 16 modules) for the dependent modules, in the order they were in the metadata. So, if it requested module `FS` (filesystem), that module is loaded, and it's address (or entry point) is given at `[modtable+0]`, and `[modtable]` is **always** `[entry_addr - 64]`.
It's good to note that OS86 won't only load kernel modules, but also dependent files and programs listed in the metadata. **The metadata can have 16 depends.**
## How does OS86 know when to unload a module?
OS86 will check for modules to be unloaded (and also check for missing modules) when the program either `yeild()`s, or `close()`s. During this kernel time, OS86 will check the PID list, and then check the current module list (addr, size) and the ID of the module on that list from the PID list (PID, name, module ID * 16 module 16-bit IDs) to determine which ones can be removed. At the same time, if it sees that a module is missing from a program, it will halt that program and present the user with an error, that a module was missing.
## There's multitasking?
Yes, OS86 can multitask! Using it's kernel interrupt 80, programs can `yeild()` to the kernel, which can switch to a different program until that program `yeild()`s. So although it's just **cooperative multitasking**, and isn't that safe, it's still possible for certain programs to use the cooperative multitasking ability of OS86.
## What happens if there isn't enough memory to load a program or module?
Well, as of version 0.1.0, there is no ability to use swap memory, so it will just say it couldn't load it because it ran out of memory. The good news is, memory is checked before loading is attempted, it checks the size of the dependencies and the program and makes sure it can fit in memory before attempting to load, that way your time isn't really wasted.