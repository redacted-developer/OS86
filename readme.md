(C) 2025 Emily Jane Force, The Safety License 1.0.
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
## Can modules be loaded as fragments?
No, this is a limitation of the 8086. The modules, programs, or anything loaded must have an entire chunk big enough for it, to be available to load.
## How does the program know where the dependencies are?
It doesn't implicitly know. It's explicitly told. There's always a table of addresses for the dependent modules, in the order they were in the metadata. So, if it requested module `tty` (tty services), that module is loaded, and it's address (or entry point) is given at `[si+0]`.
It's good to note that OS86 won't only load kernel modules, but also dependent files and programs listed in the metadata.
## Is the module table dynamically allocated?
Yes! It's a dynamically allocated table, it's only big enough to hold the addresses of the needed modules. The table's position is given by `si`, and can be used as `call far [si+2]`, to call the second module.
## How does OS86 know when to unload a module?
OS86 will check for modules to be unloaded (and also check for missing modules) when the program `close()`s. During this kernel time, OS86 will check the PID list, and then check the current module list (addr, size) and the ID of the module on that list from the PID list (PID, name, module ID * 16 module 16-bit IDs) to determine which ones can be removed. At the same time, if it sees that a module is missing from a program, it will halt that program and present the user with an error, that a module was missing.

