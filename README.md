# Spyro Scope

[![Latest Version](https://img.shields.io/github/v/release/FranklyGD/Spyro-Scope)](https://github.com/FranklyGD/Spyro-Scope/releases/latest) [![GitHub All Releases](https://img.shields.io/github/downloads/FranklyGD/Spyro-Scope/total)](https://github.com/FranklyGD/Spyro-Scope/releases) [![Discord](https://img.shields.io/discord/619694339777495056?color=7289DA&label=Mod%20the%20Dragon&logo=discord&logoColor=ffffff)](https://discord.gg/nVwGhN2)

A project that sparked when looking back at the program created to see the data of the the original trilogy's games as it is being ran in an emulator.
The program, called Spyro Scope, was only an in-house made program never released, so I thought it would be cool to recreate it.

This project is an OpenGL-SDL program made with [Beef](https://github.com/beefytech/Beef) that is used to draw the game's data that are not normally visualized.
This program is also being built in hopes of aiding the modding community for Spyro's PS1 games.

It can only support the following as of now:

|Emulators|
|-|
|See [`./config/emulators`](https://github.com/FranklyGD/Spyro-Scope/blob/master/dist/config/emulators)|

|Games|
|-|
|Spyro the Dragon NTSC U|
|Spyro: Ripto's Rage NTSC|
|Spyro: Gateway to Glimmer PAL|
|Spyro: Year of the Dragon NTSC v1.1|

*Note: The versions shown are only what I have tested so far myself, you can try to use it for other versions,
however it may mess up the program or game. You have been warned!*

For those new to Github or its new layout, here is the link to [Releases](https://github.com/FranklyGD/Spyro-Scope/releases).

## Features

### World View

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

### World View

* `Left Mouse` - Select
* `Right Mouse Hold` - Rotate View/Camera
* `Right Mouse Hold + WASD` - Move Camera
* Move mouse to top-left of window to show menu with toggles and actions with their shortcuts
* Move mouse to right of window to show menu and inspector for the current object selected
* Top middle button controls the game loop, left one Play/Pause while right one Steps (runs one frame)

### VRAM View

Accessed by the `V` key. (Press again to return)

* `Left Mouse` - Select
* `Right Mouse Hold` - Pan View
* `Scroll Wheel` - Zoom
* `1` - Expand Working Area
* `9` - Save VRAM
* `0` - Reset Position
* `Ctrl` + `Left Mouse` - Save Texture (Not CLUT)
* `Alt` + `Left Mouse` - Load Texture/CLUT

## Compiling

Beef IDE is used to compile the project as the language used is *beeflang*. You must download it from the [official website](https://www.beeflang.org/) or from the repository mentioned above. 
Get the latest "release" version possible. Make sure the "Add to path" option is checked when installing for the following to work, which is usually toggled on by default.

The project cannot be immediately compiled once cloned/downloaded from the repo since there is missing files it uses.
You must run `RUNME.ps1` file first with powershell (right click file then in the context menu, select `Run with PowerShell`).
This will grab all the required files to download that is not provided by this repository and places them in the appropriate directories.

## Contributing

As for the source code, any changes/improvements is welcome with supported reasoning behind it.
Create a pull request (but make sure it can compile first) and it will be reviewed/discussed further within the pull request. Code style is not such a huge deal for me in this project, I would eventually rearrange code after it has been accepted/implemented to my needs.

There are files that may not require the IDE to submit changes. Currently...

* The support for known emulators are not all implemented and can be expanded on if needed.
* *More files will appear over time that will be edittable by plain text editors*

## Issue Reporting

This can be done within Github's issue tracker or directly into my Discord, preferably as DMs to `FranklyGD#2512`.
If you have an account for one or the other but not both, you can use what is immediately available and do not have to create a new account just to report something on either platform.
