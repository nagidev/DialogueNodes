using Godot;

[GlobalClass]
[Tool]
public partial class BBCodeGhost : RichTextEffect
{	
    //syntax: [ghost][/ghost]
	private string bbcode = "ghost";

    public override bool _ProcessCustomFX(CharFXTransform charFX)
    {	
		bool hasSpeed = charFX.Env.TryGetValue("freq", out Variant speedVariant);
		bool hasSpan = charFX.Env.TryGetValue("span", out Variant spanVariant);

		float speed = hasSpeed ? (float)speedVariant : 5.0f;
		float span = hasSpan ? (float)spanVariant : 10.0f;

        float alpha = Mathf.Sin((float)charFX.ElapsedTime * speed + (charFX.Range.X / span)) * 0.5f + 0.5f;
        charFX.Color = new Color (charFX.Color.R, charFX.Color.G, charFX.Color.B, alpha);

        return true;
    }
}
