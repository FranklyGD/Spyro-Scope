# Spyro-Scope
[![GitHub All Releases](https://img.shields.io/github/downloads/FranklyGD/Spyro-Scope/total)](https://github.com/FranklyGD/Spyro-Scope/releases) [![Discord](https://img.shields.io/discord/619694339777495056?color=7289DA&label=Mod%20the%20Dragon&logo=discord&logoColor=ffffff)](https://discord.gg/nVwGhN2)

A project that sparked when looking back at the program created to see the data of the the original trilogy's games as it is being ran in an emulator.
The program, called Spyro Scope, was only an in-house made program never released, so I thought it would be cool to recreate it.

This project is an OpenGL-SDL program made with [Beef](https://github.com/beefytech/Beef) that is used to draw the game's data that are not normally visualized.
This program is also being built in hopes of aiding the modding community for Spyro's PS1 games.
It can only support the following as of now:

|Emulators|
|-|
|No$PSX 2.0|
|ePSXe 2.0.5 *(No VRAM Support)*|
|Bizhawk 2.4.2 (x64)|
|Mednafen 1.24.3|

|Games|
|-|
|Spyro the Dragon NTSC U|
|Spyro: Ripto's Rage NTSC|
|Spyro: Year of the Dragon NTSC v1.1|

*Note: The versions shown are only what I have tested so far myself, you can try to use it for other versions,
however it may mess up the program or game. You have been warned!*

For those new to Github or its new, layout here is the link to [Releases](https://github.com/FranklyGD/Spyro-Scope/releases)

## Features
* Externally play/pause and step the game's update loop
* View the levels in sync with the current game's view or separated on its own
* The ability to move and look around using the game's camera
* Collision Mesh
	* Show each of the triangle's data in the collision mesh color coded of their "material"
	* Visualize deforming or pieces of the collision
* Visual Mesh
	* Render both their far low-poly mesh and near high-poly mesh
	* See updating parts of the near mesh including
		* Deformation of the mesh
		* Scrolling & Swapping Textures
* Show height levels where death occurs or the max free flight limit
* Objects origins and their shapes (only static)
* Teleport Spyro to the camera's current location
* Move around Spyro and objects using an editor like tool

## Usage
* `Right Mouse Hold` - Rotate View/Camera
* `Right Mouse Hold + WASD` - Move Camera
* Move mouse to top-left of window to show menu with toggles and actions with their shortcuts
* Top middle button controls the game loop, left one Play/Pause while right one Steps (runs one frame)

## Compiling
Beef IDE is used to compile the project as the language used is *beeflang*.

The only external library needed is FreeType in order for the program to fully compile. You can get a simple library integration from [here](https://github.com/FranklyGD/BasicFreeType-beef) where only the essential parts are used for this program. If you want to integrate a fully supported version, it should also work with minor changes.
