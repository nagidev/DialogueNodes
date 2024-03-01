using Godot;
using System;
using System.Linq;
using System.Threading;

[GlobalClass]
[Tool]
public partial class BBCodeNervous : RichTextEffect
{
	//syntax: [nervous scale=1.0 freq=8.0][/nervous]
	private readonly string bbcode = "nervous";

	private readonly uint[] splitters = {" "[0], ","[0],"-"[0],"."[0]};
	private float word = 0.0f;

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}
	
	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {
		if (charFX.RelativeIndex == 0) 
		{
			word = 0;
		}

		bool hasScale = charFX.Env.TryGetValue("scale", out Variant scaleV);
		bool hasFreq = charFX.Env.TryGetValue("freq", out Variant freqV);

		float scale = hasScale ? (float)scaleV : 1.0f;
		float freq = hasFreq ? (float)freqV : 8.0f;

		uint glyphIndexAsChar = glyphIndexToChar(charFX);

		if (splitters.Contains(glyphIndexAsChar)) 
		{	
			word += 1;
		}

		float s = (float)(word + charFX.ElapsedTime) * Mathf.Pi * 1.25f % Mathf.Pi * 2.0f;
		float p = (float)Mathf.Sin(charFX.ElapsedTime * freq);

		float x = charFX.Offset.X + Mathf.Sin(s) * p * scale; 
		float y = charFX.Offset.Y + Mathf.Cos(s) * p * scale;

		charFX.Offset = new Vector2(x, y);

		return true;
	}
}
