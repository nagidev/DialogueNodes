using Godot;
using System;
using System.Linq;
using Godot.Collections;

[GlobalClass]
[Tool]
public partial class BBCodeWord : RichTextEffect
{	
	[Signal] 
    public delegate void WaitFinishedEventHandler();

	public bool Skip = false;
	//syntax: [word][/word]
	private readonly string bbcode = "word";

	private readonly uint[] splitters = {" "[0]};
	private bool reveal = false;
	private float revealSpeed = 5f;
	private float pauseSpeed = 25.0f;
	private int lastAllowedCharIndex = 0;
	private int lastFullyProcessedIndex = -1;
	private bool wordRevealed = false;
	private bool reset = false;
	private bool finished = false;

	private double elapsedTime = 0.0f;
	private double lastFrameTime = 0.0f;

	
	private void resetValues() 
	{	
		if (!reset) 
		{
			reset = true;
			elapsedTime = 0.0;
			wordRevealed = false;
			lastFullyProcessedIndex = -1;
			lastAllowedCharIndex = 0;
			lastFrameTime = 0.0f;
			reveal = false;
			finished = false;
		}
	}

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}
	private void processChar(CharFXTransform charFX) 
	{	
		if (charFX.RelativeIndex > lastFullyProcessedIndex) 
		{
			float t = (float)Mathf.Clamp(elapsedTime * revealSpeed, 0.0, 1.0);
			charFX.Color = Colors.Transparent.Lerp(charFX.Color, t);

			if (charFX.RelativeIndex > lastAllowedCharIndex) 
			{
				lastAllowedCharIndex = charFX.RelativeIndex;
			}

			if (t >= 1.0) 
			{	
				wordRevealed = true;
				elapsedTime = 0.0;
				lastFullyProcessedIndex = lastAllowedCharIndex;
			}
		}
		else 
		{
			finishConditionCheck(charFX);
		}
	}

	private void finishConditionCheck(CharFXTransform charFX) 
	{	
		int last = charFX.Env.TryGetValue("last", out Variant lastVariant) ? lastVariant.AsInt32(): 0;
		int length = charFX.Env.TryGetValue("length", out Variant lengthVariant) ? lengthVariant.AsInt32(): 0;

		if (!finished && charFX.RelativeIndex >= last && last == length -1 && wordRevealed) 
		{
			finished = true;
			EmitSignal("WaitFinished");
		}
	}

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
		if (charFX.ElapsedTime == 0.0) 
		{
			resetValues();
		}

		if (Skip) 
		{	
			charFX.Visible = true;
			finishConditionCheck(charFX);
			return true;
		} 

		double delta = charFX.ElapsedTime - lastFrameTime;
        lastFrameTime = charFX.ElapsedTime;
		elapsedTime += delta;
		reset = false;

		uint asChar = glyphIndexToChar(charFX);

		if (lastAllowedCharIndex < charFX.RelativeIndex - 1) 
		{	
			if (wordRevealed) 
			{
				wordRevealed = false;
				processChar(charFX);
			}
			else 
			{
				charFX.Visible = false;
			}
		}
		else if (reveal)
		{
			if (splitters.Contains(asChar))
			{
				reveal = false;
			}
			else
			{
				processChar(charFX);
			}
		}
		else
		{
			if (charFX.ElapsedTime > (float)charFX.RelativeIndex / pauseSpeed)
			{	
				if (splitters.Contains(asChar))
				{	
					charFX.Visible = false;
					reveal = false;
				}
				else
				{	
					processChar(charFX);
					reveal = true;
				}
			}
			else
			{	
				charFX.Visible = false;
			}
		}

		return true;
	}
}
