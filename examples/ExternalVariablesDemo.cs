using Godot;
using System;

public partial class ExternalVariablesDemo : Node
{
	public int Gold;
	public string PlayerName;
	public string FriendName;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		Gold = 3;
		PlayerName = "Cuao";
		FriendName ="Cuao";
	}
}
