using Godot;
using Godot.Collections;


[Icon("res://addons/dialogue_nodes/icons/Dialogue.svg")]
[Tool]
public partial class DialogueData : Resource
{   
    [Export] public string FileName;
    [Export] public Dictionary Starts = new Dictionary();
    [Export] public Dictionary Nodes = new Dictionary();
    [Export] public Dictionary Variables = new Dictionary();
    [Export] public Array<string> Comments = new Array<string>();
    [Export] public Array<string> Strays = new Array<string>();
    [Export] public string Characters = "";
}