using Godot;
using System;

[Tool]
public partial class DialogueInput : Control
{	
	private string skipInputAction;
	private DialogueUI dialogueUI;
	private bool isRunning;

    public void Initialize(string skipInput) 
	{	
		skipInputAction = skipInput;
		dialogueUI = (DialogueUI)this.GetParent().GetParent();

		if (dialogueUI == null) 
		{
			GD.PrintErr("DialogueInput: Impossible to find DialogueUI");
		}
		else 
		{
			isRunning = true;
		}
		
	}

    public override void _GuiInput(InputEvent @event)
    {	
		if (!isRunning) return;
		if (@event is InputEventMouseButton mouseEvent && mouseEvent.Pressed)
		{
			if (mouseEvent.ButtonIndex == MouseButton.Left) 
			{	
				dialogueUI.OnDialogueInput();
			}
		}
    }

    public override void _UnhandledInput(InputEvent @event)
    {	
		if (!isRunning) return;
        if (@event.IsActionPressed(skipInputAction))
        {	
            dialogueUI.OnDialogueInput();
        }
    }
}
