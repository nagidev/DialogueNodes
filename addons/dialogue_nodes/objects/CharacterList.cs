using Godot;

[Icon("res://addons/dialogue_nodes/icons/CharacterList.svg")]
[Tool]
public partial class CharacterList : Resource
{
    [Export] public Godot.Collections.Array<Character> Characters;
}