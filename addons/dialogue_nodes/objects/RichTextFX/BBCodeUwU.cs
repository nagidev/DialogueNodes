using Godot;
using System;

[GlobalClass]
[Tool]
public partial class BBCodeUwU : RichTextEffect
{
	//syntax: [uwu][/uwu]
	private string bbcode = "uwu";

	uint r = "r"[0];
	uint R = "R"[0];
	uint l = "l"[0];
	uint L = "L"[0];

	uint w = "w"[0];
	uint W = "W"[0];

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
		uint thisChar = glyphIndexToChar(charFX);

		if (thisChar == r || thisChar == l) 
		{
			charFX.GlyphIndex = charToGlyphIndex(charFX.Font, w);
		}
		else if (thisChar == R || thisChar == L) 
		{
			charFX.GlyphIndex = charToGlyphIndex(charFX.Font, w);
		}

		return true;
	}
}
