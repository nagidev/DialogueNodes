using Godot;
using System;

[GlobalClass]
[Tool]
public partial class BBCodeWoo : RichTextEffect
{
	//syntax: [woo scale=1.0 freq=8.0][/woo]
	private string bbcode = "woo";

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
		bool hasScale = charFX.Env.TryGetValue("scale", out Variant scaleV);
		bool hasFreq = charFX.Env.TryGetValue("freq", out Variant freqV);

		float scale = hasScale ? (float)scaleV : 1.0f;
		float freq = hasFreq ? (float)freqV : 8.0f;

		if (Mathf.Sin(charFX.ElapsedTime * freq + charFX.GlyphIndex * scale) < 0) 
		{
			uint glyphIndexAsChar = glyphIndexToChar(charFX);

			if (glyphIndexAsChar >= 65 && glyphIndexAsChar <= 90) 
			{
				glyphIndexAsChar += 32;
				charFX.GlyphIndex = charToGlyphIndex(charFX.Font, glyphIndexAsChar);
			}
			else if (glyphIndexAsChar >= 97 && glyphIndexAsChar <= 122) 
			{
				glyphIndexAsChar -= 32;
				charFX.GlyphIndex = charToGlyphIndex(charFX.Font, glyphIndexAsChar);
			}
		}
		return true;
	}
}

