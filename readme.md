# OS86
v0.1.0

# What is OS86?
OS86 (version 0.1.0) is an in-development project kernel (modular) for 8086 machines, like IBM PC 5000-series.
## Dispatch.s
Dispatch is the "glue" between all the modules. it is hooked to interrupt 80 (20h) and controls module loading/unloading, and directing the function call to the correct module. Programs may ask for module... Lets say module 4, and pretend that module is the TTY services. So a program calls dispatch in the form of interrupt 80, and puts 4 in AX. Dispatch will do a quick table search and do a far call to wherever the entry point of that tty service module is, by doing basically `call [modtable+ax]`
Here's a nutshell:
```x86asm
; this is the user process.
int 0x80

; this is dispatch.s
call [modtable+ax]
iret

; this is the module
; do stuff
ret
```
## How does the program know which module is which?
And the answer is.. it doesn't, really. Instead, the metadata of the program's file contains libraries or modules it's going to need. OS86 will load these before loading the program. Then, there's a small 32-byte allocation of double-byte (16-bit) codes. The program knows that the second double-byte is the code for TTY service. It loads *that* into AX, before doing interrupt 80.
## What about unloading modules?
This happens when a program is closed. You see, to unload modules, OS86 needs to make sure no other program is using them. So it takes a long, long mission. Basically, it takes a look at the current processes, finds them, then goes to check what modules they are using, and records this. Then, it compares this to the currently loaded modules to find ones it can remove from the closed program. It also does a missing check here, if it notices one is missing, it will load it back in.
## What else happens when a program closes?
First, the program is removed from the process list and the needed modules are unloaded. Second, it writes 0s to all of the spaces of memory that the program used. Why? **Data remanence.** Basically, if the data from the previous program is still there, another malicious program can grab that data, and intentionally do harmful things. So, OS86 tries to stop this, even knowing the 8086 is basically a asking to get malicious programs.