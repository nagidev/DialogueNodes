using Godot;
using System;
using System.Linq;

[GlobalClass]
[Tool]
public partial class BBCodeCuss : RichTextEffect
{	
	//syntax: [cuss][/cuss]
	private string bbcode = "cuss";
	private bool wasSpace = false;

	private static readonly uint[] vowels = new uint[]
    {	
        "a"[0],  "e"[0], "i"[0], "o"[0], "u"[0],
		"A"[0],  "E"[0], "I"[0], "O"[0], "U"[0],
    };

    private static readonly uint[] chars = new uint[]
    {	
		"&"[0],  "$"[0], "!"[0], "@"[0], "*"[0], "#"[0], "%"[0]
    };

    private static readonly int space = Convert.ToChar(' ');
	

	private uint charToGlyphIndex(Rid font, uint c)
    {	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetGlyphIndex(font, 1, c, 0));
    }

	private uint glyphIndexToChar(CharFXTransform charFX) 
	{	
		return Convert.ToUInt32(TextServerManager.GetPrimaryInterface().FontGetCharFromGlyphIndex(charFX.Font, 1, charFX.GlyphIndex));
	}

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
		uint glyphIndexAsChar = glyphIndexToChar(charFX);

		if (!wasSpace && charFX.RelativeIndex != 0 && glyphIndexAsChar != space)
		{
			double t = charFX.ElapsedTime + charFX.GlyphIndex * 10.2 + charFX.Range.X * 2;
			t *= 4.3;

			if (vowels.Contains(glyphIndexAsChar) || Mathf.Sin(t) > 0.0)
			{
				charFX.GlyphIndex = chars[(int)t % chars.Length];
				charFX.GlyphIndex = charToGlyphIndex(charFX.Font, chars[(int)t % chars.Length]);
			}
		}

		wasSpace = charFX.GlyphIndex == space;
		return true;
	}
}
