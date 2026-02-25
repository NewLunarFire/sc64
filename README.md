# SC64 communication with Ocarina of Time (N64)
This repo is an effort to be able to communicate with an OOT ROM running on real N64 hardware and read/write memory during gameplay

This starts with a ROM hack for Ocarina of Time, which is in folder asm/

It also contains a "communicator" program written on Python (mostly for testing), in folder comm/

And in folder connector_oot/ I have copied the Bizhawk connector for Ocarina of Time multiworld from the Archipelago repo (https://github.com/ArchipelagoMW/Archipelago) in hopes of being able to reuse it with the Oot Client in Archipelago for the Proof-of-Concept

# asm
The code in asm folder is the romhack to enable communication on the N64 side. It does the following

- It adds a hook in the main function to a blanked-out spot in code file
- The blanked-out spot runs the overwritten instruction, then runs code to DMA a file to RAM and create an OS Thread for SC64 communication
- The SC64 communication is appended to the ROM file and is DMA'd in the previous step to RAM. An entry in the dmadata table is also appended to the ROM
- The SC64 thread does the following
    - Probe: It writes the magic values required to unlock the SC64 register, and checks the identifier register for the expected value. If it does not find it loops. The reason it loops is that sometimes it doesn't work the first time, but after a few loops it eventually succeeds. I have no idea why, I should take to the people who designed the cart.
    - Main loop (does this continously):
        - Overwrites Link's tunic color (at 0x801DAB6C) with value 4 (a white tunic). This tells me that the probe worked and that the SC64 registers are unlocked, and that code execution is in this thread. I liked this test because it let me know my code worked on the intro screen.
        - Overwrites the player name in the save context (0x8011A5F4) with the value from the identifier register. I did this because then I could see what I read from the identifier register and see if the unlock worked. I could do this by talking to Saria outside Link's house. It's not that useful anymore for now but I like it because it lets me see the value quickly by going in-game. Not as useful anymore but I want to keep the routine around in case I want to see some values from memory while troubleshooting.
        - Read if there is any data in the USB receive buffer on the SC64 side. If there is, read the first 4 bytes as a memory address (apply bitmasks and stuff to make sure this is an address in SDRAM) then read a word (4 bytes) at this address and write it back to the USB interface. This is a very primitive version of what I want to do but this tells me the communication works.

Notes:
- I have used 0x80400000 as the starting point, meaning that the hack requires an N64 expansion pack to work. The stack for this thread is also in expansion pack territory. I had trouble finding a free spot in on-board RAM (0x80000000 - 0x803FFFFF) that is not used by something else or would be overwritten during testing. I also did not want to clobber the heap and risk a crash that could occur during gameplay, so I opted to use the expansion pack since that is not used in the base game as it is designed to run on base N64 hardware.
- I have placed my hook point a bit randomly, it was easier to me to just replace a function call (jal 0xsomething) as temporary registers are not guaranteed to be preserved during a function call and the compiler should have assumed them to be dirty after returning from the function call. This allowed me to redirect to execution to another spot in code without risking side effects.
- I found the largest contiguous run of zeroes in the code file and placed the thread creating code there. I have no idea if I am overwriting something important, but a large run of zeroes in the code files tells me this might just be extra padding. I found no side effects thus far.
- I do not call osThreadYield for now. I think I should to not to overwhelm the CPU but every call I make to that functions ends up never returning to this thread, so instead I busy wait. Miraculously this ends up not causing any slowdowns to the game so I guess the scheduler is doing its job.
- I have a lot of commented out code in my sc64.asm file. I think I'll clean this up after my initial commit in Git. I want to keep this as part of the history, so once the initial commit is done I can delete a lot of this and rely on Git history in the future.

# comm
A very basic communicator in Python. I used pyserial to read and write to the SC64 interface. Not much to say about this, especially considering the way the Lua connector is done.

# connector_oot
In order not to have to rewrite the logic in another language I want to just want to reuse the current connector as much as possible and replace the calls to the BizHawk API to calls that will communicate with the SC64. This is not the greateast way to go about it but it should work for a Proof-of-Concept.

# Shout-outs
A lot of the information I used during testing is thanks to the good folks who created [CloudModding OOT Wiki](https://wiki.cloudmodding.com/oot/Main_Page), so thanks a lot for your valuable treasure trove of information.

I have looked at some of the code from the GZ repo, mostly the SC64 code ()[https://github.com/glankk/gz/blob/master/src/gz/sc64.c] and that helped me a ton in making 

Some help was given to me early on by the OOT Randomizer Discord, so props to you as well.

SC64 documentation is available here: [](https://github.com/Polprzewodnikowy/SummerCart64/tree/main)
