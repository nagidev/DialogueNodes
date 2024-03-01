using Godot;
using Godot.Collections;
using System;
using System.Linq;

public partial class Demo : Control
{	
	[Export] private DialogueData[] dialogueData;
	[Export] private DialogueManager dialogueBox;
	[Export] private CpuParticles2D cpuParticles;
	[Export] private OptionButton demoSelector;
	[Export] private AudioStreamPlayer audioStreamPlayer;
	[Export] private ExternalVariablesDemo externalVariablesDemo;

	[ExportCategory("SFX Options")]
	[Export] private bool enableAudio = true;
	[Export(PropertyHint.Range, "1,5,1.0")] private float sfxFrequency = 3;
	private DialogueData currentData;

	public override void _Ready()
	{	
		dialogueBox.Initialize();

		foreach (DialogueData res in dialogueData) 
		{
			string resourcePath = res.ResourcePath;
			int lastSlashIndex = resourcePath.LastIndexOf('/');
			int lastDotIndex = resourcePath.LastIndexOf('.');
			string label = resourcePath.Substring(lastSlashIndex + 1, lastDotIndex - lastSlashIndex - 1);
			demoSelector.AddItem(label);
		}

		if (dialogueData != null && dialogueData.Count() > 0) 
		{
			currentData = dialogueData[0];
		}

		dialogueBox.AddExternalVariable(externalVariablesDemo);
	}

	public void OnButtonPressed() 
	{
		if (!dialogueBox.IsRunning()) 
		{
			dialogueBox.Start(currentData);
		} 
	}

	public void OnDemoSelected(int index) 
	{	
		currentData = dialogueData[index];
	}

	public void OnDialogueSignal(string value) 
	{	
		switch (value) 
		{
			case "explode":
				explode();
				break;

			default:
				break;
		}
	}

	private void explode() 
	{	
		cpuParticles.Emitting = true;
	}

	public void OnCharacterDisplayed(int index) 
	{	
		if (enableAudio && index % sfxFrequency == 0) 
		{
			audioStreamPlayer.Play();
		}
	}
}
