using Godot;
using System;

[GlobalClass]
[Tool]
public partial class BBCodeRain : RichTextEffect
{
	//syntax: [rain][/rain]
	private readonly string bbcode = "rain";

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}

	private double getRandom(CharFXTransform charFX) 
	{
		return getRandomUnclamped(charFX) % 1.0;
	}

	private double getRandomUnclamped(CharFXTransform charFX) 
	{
		uint glyphIndexAsChar = glyphIndexToChar(charFX);
		return glyphIndexAsChar * 33.33 + charFX.GlyphIndex * 4545.5454;
	}

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {
		double time = charFX.ElapsedTime;
		double r = getRandom(charFX);
		float t = (float)((r + time * 0.5) % 1.0);

		float y = charFX.Offset.Y + t * 8.0f;
		charFX.Offset = new Vector2(charFX.Offset.X, y);
		charFX.Color = charFX.Color.Lerp(Colors.Transparent, t);

		return true;
	}
}
