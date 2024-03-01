using Godot;
using System;
using System.Linq;

[GlobalClass]
[Tool]
public partial class BBCodeJump : RichTextEffect
{	
	//syntax: [jump angle=3.141][/jump]
	private string bbcode = "jump";
	private int wChar = 0;
	private int last = 999;

	private uint[] splitters = new uint[]
	{
		" "[0], "."[0], ","[0]
	};

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {
		float angle = charFX.Env.TryGetValue("angle", out Variant angleV) ? (float)angleV: 3.141f;

        uint glyphIndexAsChar = glyphIndexToChar(charFX);

		if (charFX.Range.X < last || splitters.Contains(glyphIndexAsChar)) 
		{
			wChar = charFX.Range.X;
		}

		last = charFX.Range.X;
		angle = Mathf.DegToRad(angle);

		double t = Mathf.Abs(Mathf.Sin(charFX.ElapsedTime * 8.0 + wChar * Mathf.Pi * 0.025)) * 4.0;
		float x = (float)(charFX.Offset.X + Mathf.Sin(angle) * t);
		float y = (float)(charFX.Offset.Y + Mathf.Cos(angle) * t);

		charFX.Offset = new Vector2(x, y);
		return true;
	}
}
