using System.IO;
using System.Linq;
using Godot;
using Godot.Collections;

[Tool]
public partial class DialogueUI : Control
{	
	[ExportCategory("Preferences")]
	[Export] private Texture2D nextIcon = (Texture2D)GD.Load("res://addons/dialogue_nodes/icons/Play.svg");
	[Export] private Color speakerTxtColor = Colors.White;
	[Export] private bool hidePortrait;

	[ExportGroup("Connections")]
	[Export] private Label speaker;
	[Export] private TextureRect speakerPortrait;
	[Export] private RichTextLabel dialogue;
	[Export] private Button[] optionsButtons;
	[Export] private Array<RichTextEffect> customEffects = new() 
	{ 
		new BBCodeGhost()
	};

	private DialogueCore dialogueCore;
	private DialogueManager dialogueManager;
	private CharacterList characterList;
	private Dictionary<Button, Callable> signalsDict;
	private BoxContainer optionsContainer;
	private RichTextEffect transitionEffect;

	public void Initialize(DialogueManager dialogueManager, RichTextTransitionType transitionType, float textSpeed, float punctuationPause)
	{	
		this.Hide();
		this.dialogueManager = dialogueManager;
		dialogueCore = dialogueManager.GetCoreManager();
		signalsDict = new Dictionary<Button, Callable>();
		optionsContainer = (BoxContainer)optionsButtons[0].GetParent();
		initTransitionFX(transitionType, textSpeed, punctuationPause);
		initCustomEffects();
		resetValues();
	}

	public void Display(bool toggle) 
	{	
		this.Visible = toggle;
		if (!toggle) 
		{
			resetValues();
			characterList = null;
		} 
	}

	public void SetCharacterList(CharacterList characterList) 
	{	
		this.characterList = characterList;
	}

	public void SetDialogue(Dictionary dict)
    {
        resetValues();
        setSpeaker(dict);

        dialogue.Text = dialogueCore.ProcessText(dict["dialogue"].AsString());
        dialogue.GetVScrollBar().Value = 0;

        if (transitionEffect is BBCodeWait wait) 
        {
            wait.Skip = false;
        }
		else if (transitionEffect is BBCodeWord word) 
			{
				word.Skip = false;
			}
        
        setOptions(dict);
    }

	public void OnDialogueInput()
    {
        if (customEffects.Count > 0)
        {   
            if (transitionEffect is BBCodeWait wait) 
            {
                wait.Skip = true;
            }
			else if (transitionEffect is BBCodeWord word) 
			{
				word.Skip = true;
			}
        }

        optionsContainer.Show();
    }

	public void GrabFirstOptionFocus() 
	{
		optionsButtons[0].GrabFocus();
	}

	private void initCustomEffects() 
	{	
		foreach (RichTextEffect effect in customEffects)
		{   
			dialogue.InstallEffect(effect);
		}
	}

	private void initTransitionFX(RichTextTransitionType transitionType, float textSpeed, float punctuationPause) 
	{	
		if (transitionType == RichTextTransitionType.Wait) 
		{
			transitionEffect = new BBCodeWait {Speed = textSpeed, PauseValue = punctuationPause};
			transitionEffect.Connect("WaitFinished", Callable.From(showOptions));
			transitionEffect.Connect("CharDisplayed", Callable.From<int>(x => revealChar(x)));
		}
		else if (transitionType == RichTextTransitionType.Console) 
		{
			transitionEffect = new BBCodeConsole{Speed = textSpeed, PauseValue = punctuationPause};
			transitionEffect.Connect("WaitFinished", Callable.From(showOptions));
			transitionEffect.Connect("CharDisplayed", Callable.From<int>(x => revealChar(x)));
		}

		if (transitionEffect != null) dialogue.InstallEffect(transitionEffect);
	}

	private void setSpeaker(Dictionary dict) 
	{	
		if (dict.TryGetValue("speaker", out Variant speakerValue))
		{	
			if (speakerValue.VariantType == Variant.Type.String) 
			{
				speaker.Text = dialogueCore.GetExternalVariable(speakerValue.AsString());
			}
			else if (characterList != null && speakerValue.VariantType == Variant.Type.Int) 
			{
				int idx = speakerValue.AsInt32();

				if (idx > -1 && idx < characterList.Characters.Count)
				{   
					speaker.Text = dialogueCore.GetExternalVariable(characterList.Characters[idx].Name);
					speaker.Modulate = characterList.Characters[idx].Color;

					if (!hidePortrait && characterList.Characters[idx].Image != null)
					{
						speakerPortrait.Texture = characterList.Characters[idx].Image;
					}
				}
			}
		}

		speakerPortrait.Visible = !hidePortrait && speakerPortrait.Texture != null;
		speaker.Visible = speaker.Text != "";
	}

	private void setOptions(Dictionary dict) 
	{
		hideOptions();

		dict.TryGetValue("options", out Variant optionsVariant);

        Dictionary optionsDict = optionsVariant.AsGodotDictionary();
		int optionsVisibleCount = 0;

        foreach (Variant idxVar in optionsDict.Keys)
        {   
            int idx = idxVar.AsInt32();
            Button option = optionsButtons[idx];

            optionsDict.TryGetValue(idx, out Variant idxValue);
            idxValue.AsGodotDictionary().TryGetValue("link", out Variant link);

            option.Text = dialogueCore.ProcessText(idxValue.AsGodotDictionary()["text"].AsString(), false);

            Callable pressOption = Callable.From(() => onOptionPressed(idx, link.AsString()));
            connectOptionsSignals(option, pressOption);

            bool hasCondition = idxValue.AsGodotDictionary().TryGetValue("condition", out Variant condition);
            optionsDict.TryGetValue("condition", out Variant conditionVariant);

            Dictionary conditions = conditionVariant.AsGodotDictionary();

            if (hasCondition && conditions.Count > 0)
            {   
                option.Visible = dialogueCore.CheckCondition(conditionVariant.AsGodotDictionary());
            }
            else
            {
                option.Show();
            }

			if (option.Visible) optionsVisibleCount++;
        }

        if (optionsVisibleCount == 0)
        {
            optionsButtons[0].Text = "";
            optionsButtons[0].Icon = nextIcon;

            Callable proceedCallable = Callable.From(dialogueCore.EndDialogue);
            connectOptionsSignals(optionsButtons[0], proceedCallable);
     
            optionsButtons[0].Show();
        }

        if (optionsVariant.AsGodotDictionary().Count == 1 && optionsButtons[0].Text == "") 
        {	
			optionsButtons[0].Icon = nextIcon;
        }

		if (transitionEffect == null) 
		{
			showOptions();
		}
	}

	private void hideOptions() 
	{
		optionsContainer.Hide();
        foreach (Button btn in optionsButtons)
        {	
            btn.Icon = null;
            btn.Hide();
        }
	}

	private void showOptions() 
	{   
		if (optionsContainer.IsInsideTree()) 
		{
			foreach (Button btn in optionsButtons)
			{	
				if (btn.Visible) 
				{
					btn.GrabFocus();
					break;
				}
			}
			optionsContainer.Show();
		}
	}

	private void revealChar(int index) 
	{
		dialogueManager.EmitCharDisplayed(index);
	}

	private void connectOptionsSignals(Button button, Callable newCallable) 
    {   
        if (signalsDict.Keys.Contains(button)) 
        {   
            Callable containedCallable = signalsDict[button];

            if (button.IsConnected("pressed", containedCallable)) 
            {
                button.Disconnect("pressed", containedCallable);
                signalsDict.Remove(button);
            }
        }
        
        button.Connect("pressed", newCallable);
        signalsDict.Add(button, newCallable);
    }

	private void disconnectOptionsSignals() 
    {   
        if (signalsDict == null || signalsDict.Count <= 0) return;

        foreach (System.Collections.Generic.KeyValuePair<Button, Callable> connection in signalsDict)
        {
            if (connection.Key.IsConnected("pressed", connection.Value)) 
            {
                connection.Key.Disconnect("pressed", connection.Value);
            }
        }
        signalsDict.Clear();
    }

	private void resetValues() 
    {   
        disconnectOptionsSignals();
        speaker.Text = "";
        dialogue.Text = "";
		speaker.Modulate = speakerTxtColor;
        speakerPortrait.Texture = null;
    }

	private void onOptionPressed(int idx, string link) 
	{   
		dialogueManager.EmitOptionSelected(idx);
        dialogueCore.ProcessNode(link);
	}
}
