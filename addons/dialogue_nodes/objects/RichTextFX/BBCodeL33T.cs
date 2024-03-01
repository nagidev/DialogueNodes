using System.Collections.Generic;
using Godot;
using System;

[GlobalClass]
[Tool]
public partial class BBCodeL33T : RichTextEffect
{	
	//syntax: [l33t][/l33t]
	private string bbcode = "l33t";

	private readonly Dictionary<uint, uint> leetDict = new()
	{
		{"L"[0], "1"[0]},
		{"l"[0], "1"[0]},
		{"I"[0], "1"[0]},
		{"i"[0], "1"[0]},
		{"E"[0], "3"[0]},
		{"e"[0], "3"[0]},
		{"T"[0], "7"[0]},
		{"t"[0], "7"[0]},
		{"S"[0], "5"[0]},
		{"s"[0], "5"[0]},
		{"A"[0], "4"[0]},
		{"a"[0], "4"[0]},
		{"O"[0], "0"[0]},
		{"o"[0], "0"[0]},
	};	

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}

	private uint charToGlyphIndex(Rid font, uint c)
    {	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetGlyphIndex(font, 1, c, 0));
    }

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
		uint glyphIndexAsChar = glyphIndexToChar(charFX);

		if (leetDict.TryGetValue(glyphIndexAsChar, out uint leetValue))
		{
			charFX.GlyphIndex = charToGlyphIndex(charFX.Font, leetValue);
		}

		return true;
	}
}
