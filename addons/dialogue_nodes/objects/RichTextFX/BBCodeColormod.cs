using Godot;
using System;
using System.Collections.Generic;

[GlobalClass]
[Tool]
public partial class BBCodeColormod : RichTextEffect
{   
    //syntax: [colormod color=red][/colormod]
	private string bbcode = "colormod";
    private Dictionary<string, Color> colorsDict;

    public BBCodeColormod() 
    {
        colorsDict = new Dictionary<string, Color>
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
    }

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
        if (!charFX.Env.TryGetValue("color", out Variant colorVariant))
        {
            return false;
        }
        string colorName = colorVariant.AsString().ToLower();

        if (!colorsDict.ContainsKey(colorName)) 
        {
            return false;
        }

		float t = Mathf.SmoothStep(0.3f, 0.6f, (float)Mathf.Sin(charFX.ElapsedTime * 4.0f) * 0.5f + 0.5f);
        charFX.Color = charFX.Color.Lerp(colorsDict[colorName], t);
        return true;
    }
}
