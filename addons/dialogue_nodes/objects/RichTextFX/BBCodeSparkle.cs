using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

[GlobalClass]
[Tool]
public partial class BBCodeSparkle : RichTextEffect
{
	//syntax: [sparkle c1=red c2=yellow c3=blue][/sparkle]
	private string bbcode = "sparkle";
	private List<Color> colors = new List<Color>();
	private Dictionary<string, Color> colorsDict = new()
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

	private Color lerpList(List<Color> a, double t) 
	{
		if (a.Count == 0) return Colors.White;

		else if (a.Count == 1) return a[0];

		t = (float)Mathf.Wrap(t, 0.0, 1.0);

		double scaled = t * (a.Count - 1.0);

		Color from = a[Mathf.Wrap((int)Mathf.Floor(scaled), 0, a.Count)];
		Color to = a[Mathf.Wrap((int)Mathf.Floor(scaled + 1.0), 0, a.Count)];

		t = scaled - Mathf.Floor(scaled);
		
		return from.Lerp(to, (float)t);
	}

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

	private double getRandUnclamped(CharFXTransform charFX) 
	{
		return charFX.GlyphIndex * 33.33 + charFX.Range.X * 4545.5454;
	}

	public override bool _ProcessCustomFX(CharFXTransform charFX)
    {
		bool hasFreq = charFX.Env.TryGetValue("freq", out Variant freqVariant);

		float freq = hasFreq ? (float)freqVariant : 2.0f;

		bool hasC1 = charFX.Env.TryGetValue("c1", out Variant c1Variant);
		bool hasC2 = charFX.Env.TryGetValue("c2", out Variant c2Variant);
		bool hasC3 = charFX.Env.TryGetValue("c3", out Variant c3Variant);

		if (hasC1) colors.Add(getColor(c1Variant.AsString()));
		else colors.Add(charFX.Color);
		if (hasC2) colors.Add(getColor(c2Variant.AsString()));
		if (hasC3) colors.Add(getColor(c3Variant.AsString()));

		if (colors.Count() > 0) 
		{
			double t = Mathf.Sin(charFX.ElapsedTime * freq + getRandUnclamped(charFX) * 0.5 + 0.5);
			charFX.Color = lerpList(colors, t);
		}

		colors.Clear();
		return true;
	}
}
