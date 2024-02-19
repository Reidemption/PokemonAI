## Pokemon Automation
This Lua script is designed to be run using the mGBA emulator with a Pokemon FireRed ROM. The script will run around in a circle while out of combat and will spam the A button while in battle. This is meant to be something simple to help beginners get started with Lua scripting and understand how to interact with the game.

## Getting Started
Please make sure you have the mGBA emulator installed and a Pokemon FireRed ROM. You can download the emulator from [here](https://mgba.io/downloads.html). You can find the ROM by searching for it on Google. (I can't provide a link to the ROM as it is illegal to distribute copyrighted material). It is probably easiest to just download the `pokemon.lua` file from this repository instead of downloading the entire repository. I'll include my save file as well so you can test the script out without having to play through the game to get to the point where you can catch a Pokemon.

The .sav file is the save file. Store the save file in the same folder as where ever you place your ROM file. It is important that your save file and ROM file have the same file-name. If they are different feel free to re-name them, but keep their extension unique. You can load this file in the mGBA emulator by going to `File -> Load Game` and selecting the .sav file. The .lua file is the script file. You can load this file in the mGBA emulator by going to `Tools -> Lua -> New Lua Script Window` and selecting the .lua file.

*I'm not sure what the .ss1 file is... but I had it so I'll include it*

## Learning Resources
Official mGBA Lua scripting documentation can be found [here](https://mgba.io/docs/). This is a great resource to learn about the different functions and objects that are available to you when scripting with Lua in mGBA.

Official mGBA github repository can be found [here](https://github.com/mgba-emu/mgba). This is a great resource to learn about the source code of the emulator and how it works. You can also find more example Lua scripts in the `res/scripts` folder.

