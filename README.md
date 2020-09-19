# Spyro-Scope
![GitHub All Releases](https://img.shields.io/github/downloads/FranklyGD/Spyro-Scope/total) ![Discord](https://img.shields.io/discord/619694339777495056?color=7289DA&label=Mod%20the%20Dragon&logo=discord&logoColor=ffffff)  
A project that sparked when looking back at the program created to see the data of the the original trilogy's games as it is being ran in an emulator.
The program, called Spyro Scope, was only an in-house made program never released, so I thought it would be cool to recreate it.

This project is an OpenGL-SDL program made with [Beef](https://github.com/beefytech/Beef) that is used to draw the game's data that are not normally visualized. It can only support the following as of now:
### Emulators
* No$PSX 2.0
* ePSXe 2.0.5
* Bizhawk 2.4.2 (x64)
### Games
* Spyro: Ripto's Rage NTSC
* Spyro: Year of the Dragon NTSC v1.1

*Note: The versions shown are only what I have tested so far myself, you can try to use it for other versions,
however it may mess up the program or game. You have been warned!*

## Features
* Externally play/pause and step the game's update loop
* View the levels in sync with the current game's view or separated on its own
* The ability to move and look around using the game's camera
* Display the collision mesh each level uses
* Show each of the triangle's data in the collision mesh color coded of their "material"
* Visualize deforming or animated pieces of collision mesh
* Show height levels where death occurs or the max free flight limit
* Objects origins and their shapes (only static)
* Teleport Spyro to the camera's current location

## Usage
`Right Mouse Hold` - Rotate View/Camera
`Right Mouse Hold + WASD` - Move Camera
Move mouse to top-left of window to show menu with toggles and actions with their shortcuts
Top middle button controls the game loop, left one Play/Pause while right one Steps (runs one frame)

However, there is one thing to keep in mind when using this program...
## *One* Major Issue
Because this program is a separate program that reads memory at a different rate than any of the emulators that read and write to its RAM,
there is a chance where in the process of reading, it may get invalid or old information that is in the process of being unloaded.
Because of this, any form of major data changes in the RAM done by the emulator, such as loading into a new level or loading a save state if the emulator provides the ability to, will cause the program to crash. This will happen often if one plans to use save states often.


## Compiling
Beef IDE is used to compile the project as the language used is *beeflang*.

The only external library needed is FreeType in order for the program to fully compile. You can get a simple library integration from [here](https://github.com/FranklyGD/BasicFreeType-beef) where only the essential parts are used for this program. If you want to integrate a fully supported version, it should also work with minor changes.
