using Godot;
using System;

[Icon("res://addons/dialogue_nodes/icons/Dialogue.svg")]
[Tool]
public partial class DialogueManager : Control
{
	[Signal] public delegate void DialogueStartedEventHandler(string id);
    [Signal] public delegate void DialogueProceededEventHandler(string nodeType);
    [Signal] public delegate void DialogueSignalEventHandler(string value);
    [Signal] public delegate void DialogueEndedEventHandler();
	[Signal] public delegate void DialogueCharDisplayedEventHandler(int idx);
    [Signal] public delegate void InternalVariableChangedEventHandler(string varName, Variant value);
	[Signal] public delegate void OptionSelectedEventHandler(int idx);

	[Export] private DialogueData data;
	[Export] private string startID = "Start";
	[Export] private string skipInputAction = "ui_accept";
	[Export] private RichTextTransitionType transitionType = RichTextTransitionType.Wait;
	[Export(PropertyHint.Range, "1,150,")] private float textSpeed = 50.0f;
	[Export(PropertyHint.Range, "0,2,")] private float punctuationPause = 0.45f;

	private DialogueCore dialogueCore;
	private DialogueUI dialogueUI;

	public void Initialize() 
	{	
		this.Hide();
		dialogueCore = this.GetNode<DialogueCore>("DialogueCore");
		dialogueUI = this.GetNode<DialogueUI>("DialogueUI");
		dialogueUI.GetNode<DialogueInput>("MarginContainer/DialogueInput").Initialize(skipInputAction);
		dialogueUI.Initialize(this, transitionType, textSpeed, punctuationPause);
		dialogueCore.Initialize(this, transitionType, punctuationPause);
	}

	public void Start(DialogueData dialogueData = null, string dialogueID = null) 
	{	
		dialogueData ??= data;
		dialogueID = string.IsNullOrEmpty(dialogueID) ? startID : dialogueID;
		
		this.Show();
		dialogueCore.Start(dialogueData, dialogueID);
	}

	public void Stop() 
    {
		dialogueUI.Display(false);
		dialogueCore.IsRunning = false;
		this.Hide();
        EmitSignal("DialogueEnded");
    }

	public bool IsRunning()
	{
		return dialogueCore.IsRunning;
	}

	public void AddExternalVariable(Object obj) 
	{
		dialogueCore.AddExternalVariables(obj);
	}

	public DialogueUI GetUIManager() 
	{
		return dialogueUI;
	}

	public DialogueCore GetCoreManager() 
	{
		return dialogueCore;
	}

	public void EmitDialogueStarted(string id) 
	{
		EmitSignal("DialogueStarted", id);
	}

	public void EmitDialogueProceeded(string nodeType) 
	{
		EmitSignal("DialogueProceeded", nodeType);
	}

	public void EmitDialogueSignal(string value) 
	{	
		EmitSignal("DialogueSignal", value);
	}

	public void EmitInternalVariableChanged(Variant varName, Variant value) 
	{	
		EmitSignal("InternalVariableChanged", varName, value);
	}

	public void EmitOptionSelected(int idx) 
	{
		EmitSignal("OptionSelected", idx);
	}

	public void EmitCharDisplayed(int idx) 
	{
		EmitSignal("DialogueCharDisplayed", idx);
	}
}
