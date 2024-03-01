using Godot;
using System;
using System.Linq;

[GlobalClass]
[Tool]
public partial class BBCodeHeart : RichTextEffect
{	
	//syntax: [heart scale=1.0 freq=8.0][/heart]
	private string bbcode = "heart";

	uint heart = "♡"[0];
	uint[] toChange = new uint[] {"o"[0], "O"[0], "a"[0], "A"[0]};

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
		bool hasFreq = charFX.Env.TryGetValue("freq", out Variant speedVariant);
		bool hasScale = charFX.Env.TryGetValue("scale", out Variant spanVariant);

		float freq = hasFreq ? (float)speedVariant : 2.0f;
		float scale = hasScale ? (float)spanVariant : 16.0f;

		double x = charFX.Range.X / scale - charFX.ElapsedTime * freq;
		float t = (float)(Mathf.Abs(Mathf.Cos(x)) * Mathf.Max(0.0, Mathf.SmoothStep(0.712, 0.99, Mathf.Sin(x))) * 2.5);

		charFX.Color = charFX.Color.Lerp(Colors.Blue.Lerp(Colors.Red, t), t);
		charFX.Offset = new Vector2(charFX.Offset.X, charFX.Offset.Y - t * 4.0f);

		uint glyphIndexAsChar = glyphIndexToChar(charFX);

		if (charFX.Offset.Y < -1.0) 
		{
			if (toChange.Contains(glyphIndexAsChar)) 
			{
				charFX.GlyphIndex = charToGlyphIndex(charFX.Font, heart);
			}
		}

		return true;
	}
}
