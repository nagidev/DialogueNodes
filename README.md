![DialogueNodes icon](icon.svg)
# Dialogue Nodes
![DialogueNodes editor](.screenshots/DN0.png)
<img src='.screenshots/DN1.png' width='51%'/>
<img src='.screenshots/DN2.png' width='48%'/>
A plugin for creating and exporting dialogue trees from within the Godot Editor.
Godot provides all the tools needed to create your own dialogue system, however, for most game developers, this task is tedious and complex. This is where Dialogue Nodes come into the picture. The plugin extends your Godot editor to allow for creating, testing and incorporating branching dialogues in your game.

####
## Installation
1. Search for "Dialogue Nodes" in the Godot AssetLib
2. Install the plugin
3. Enable the plugin from the project settings
4. Done.

Check out [the installation instructions in the wiki](https://github.com/nagidev/DialogueNodes/wiki#installation-and-setup) for further details.

> [!NOTE]
> For installing the plugin directly from this Github repository, you can find the instructions [here](https://github.com/nagidev/DialogueNodes/wiki#install-from-github).

####
## Features
- Simple editor, straight-forward dialogue box
- Dialogue animations with bbcodes
- Conditional dialogues & options
- Support for variables & signals
- Character portraits & colors
- In-editor dialogue previewer
- Localization through `tres` files

####
## Learn more
Read [the wiki](https://github.com/nagidev/DialogueNodes/wiki) to learn how to get started with using the plugin and adding dialogues to your awesome games!

> [!NOTE]
> The wiki is still being updated frequently. Some of the functionalities might not be documented. Please expect more updates soon, and feel free to [contact me](https://twitter.com/NagiDev) if you want to contribute to the documentation. (I could really use some help here lol!)

####
## Known issues
- Using return character in the dialogue results in options not showing up in certain cases
- DialogNodes in the graph have options overflowing outside the edges. This seems to be [a bug introduced in Godot 4.2](https://github.com/godotengine/godot/issues/85558)

If you find any bugs or issues, [report them in the issues page](https://github.com/nagidev/DialogueNodes/issues). Please ensure the same or a similar issues isn't already present before creating your own.

####
## C# Support
The plugin was built using GDscript and has not been tested for a proper C# support. If this plugin does not function well with your C# project, you can check out this project:
[DialogueNodesForCSharp](https://github.com/germanbv/DialogueNodesForCSharp)

----
Dialogue Nodes is distributed under the MIT license. It is completely free forever and does not require any payment of any kind (except maybe cat pictures). However, if you want to support my work, you can buy me a Ko-fi (or send me cat pictures).
<p align='center'><a href='https://ko-fi.com/nagidev'><img src='https://ko-fi.com/img/githubbutton_sm.svg'/></a></p>

