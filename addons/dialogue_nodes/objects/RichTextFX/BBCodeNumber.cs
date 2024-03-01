using Godot;
using System;
using System.Collections.Generic;
using System.Runtime.Serialization;

[GlobalClass]
[Tool]
public partial class BBCodeNumber : RichTextEffect
{
	//syntax: [number][/number]
	private readonly string bbcode = "number";

	private uint spaceAsGlyphIndex;
	private uint periodAsGlyphIndex;
	private uint zeroAsGlyphIndex;
	private uint nineAsGlyphIndex;
	private uint commaAsGlyphIndex;

	private bool lastCharWasNumber = false;
	private bool lastWordWasNumber = false;
	private bool processed = false;

	private readonly Dictionary<string, Color> colorsDict = new()
    {
            { "red", Colors.Red },
            { "blue", Colors.Blue },
            { "yellow", Colors.Yellow },
            { "green", Colors.Green },
            { "gray", Colors.Gray },
            { "black", Colors.Black },
            { "white", Colors.White },
            { "purple", Colors.Purple },
            { "orange", Colors.Orange },
            { "cyan", Colors.Cyan },
            { "brown", Colors.Brown },
            { "violet", Colors.Violet },
            { "magenta", Colors.Magenta },
            { "rose", Colors.MistyRose },
            { "lime", Colors.Lime },
            { "gold", Colors.Gold },
            { "silve", Colors.Silver },
            { "aqua", Colors.Aqua },
            { "beige", Colors.Beige },
            { "pink", Colors.Pink },
            { "turquoise", Colors.Turquoise },
    };

	private Color getColor(string s) 
	{
		if (colorsDict.TryGetValue(s, out Color color))
		{
			return color;
		}
		else if (s.StartsWith('#')) 
		{
			 s = s[1..];
			 return Color.FromHtml(s);
		}
		else 
		{
			return Color.FromString(s, Colors.Black);
		}
	}

	private void setInitialValues(CharFXTransform charFX) 
	{
		if (!processed) 
		{
			spaceAsGlyphIndex = charToGlyphIndex(charFX.Font, " "[0]);
			periodAsGlyphIndex = charToGlyphIndex(charFX.Font, "."[0]);
			zeroAsGlyphIndex = charToGlyphIndex(charFX.Font, "0"[0]);
			nineAsGlyphIndex = charToGlyphIndex(charFX.Font, "9"[0]);
			commaAsGlyphIndex = charToGlyphIndex(charFX.Font, ","[0]);
			processed = true;
		}
	}

	private uint charToGlyphIndex(Rid font, uint c)
    {	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetGlyphIndex(font, 1, c, 0));
    }

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
		bool hasColor = charFX.Env.TryGetValue("color", out Variant colorVar);
		Color colorNumber = hasColor ? getColor(colorVar.AsString()) : Colors.Yellow;

		//reset on first character
		if (charFX.RelativeIndex == 0) 
		{
			lastCharWasNumber = false;
			lastWordWasNumber = false;
			processed = false;
		}

		setInitialValues(charFX);

		//if the following is a word, and it came after a number, we'll colorize it
		if (charFX.GlyphIndex == spaceAsGlyphIndex) 
		{
			if (lastCharWasNumber) 
			{
				lastWordWasNumber = true;
			}
			else 
			{
				lastWordWasNumber = false;
			}
		}
		//colorize characters after a number, except for the period
		if (lastWordWasNumber && charFX.GlyphIndex != periodAsGlyphIndex) 
		{
			charFX.Color = colorNumber;
		} 
		// if character is a number, color it.
		if (charFX.GlyphIndex >= zeroAsGlyphIndex && charFX.GlyphIndex <= nineAsGlyphIndex) 
		{
			charFX.Color = colorNumber;
			lastCharWasNumber = true;
		}
		// colorize trailing commas and periods.
		else if (lastCharWasNumber && charFX.GlyphIndex == commaAsGlyphIndex) 
		{
			charFX.Color = colorNumber;
			lastCharWasNumber = false;
		}
		else 
		{
			lastCharWasNumber = false;
		}

		return true;
	}
}
