using Godot;
using Godot.Collections;
using System;
using System.Collections.Generic;
using System.Reflection;
using System.Linq;
using System.Globalization;

[Tool]
public partial class DialogueCore : Node
{	
    public bool IsRunning {get;set;}

    private DialogueUI dialogueUI;
    private DialogueManager dialogueManager;
	private DialogueData dialogueData;
	private Dictionary variables;
	private RegEx bbcodeRegex;
    private RichTextTransitionType transitionType;
    private System.Collections.Generic.Dictionary<string, Tuple<FieldInfo, object>> externalFields;
    private float punctuationPause;

    public void Initialize(DialogueManager dialogueManager, RichTextTransitionType transitionType, float punctuationPause)
    {   
        bbcodeRegex = new RegEx();
        bbcodeRegex.Compile("\\n|\\[img\\].*?\\[\\/img\\]|\\[.*?\\]");

        this.dialogueManager = dialogueManager;
        this.transitionType = transitionType;
        this.punctuationPause = punctuationPause;

        dialogueUI = dialogueManager.GetUIManager();
    }

    public void Start(DialogueData dialogueData, string startID) 
    {   
		this.dialogueData = dialogueData;
		
        if (errorChecks(ref startID)) return;

        IsRunning = true;
		initVariables();
        initCharacterList();
        ProcessNode(dialogueData.Starts[startID].AsString());
        dialogueManager.EmitDialogueStarted(startID);
    }

    public void ClearExternalVariables() 
    {
        externalFields?.Clear();
    }

    public void AddExternalVariables(object obj) 
    {   
        externalFields ??= new();

        bool objExists = externalFields.Values.Any(innerTuple => innerTuple.Item2 == obj);

        if (!objExists) 
        {   
            bool typeExist = externalFields.Values.Any(innerTuple => innerTuple.Item2.GetType() == obj.GetType());

            if (!typeExist) 
            {
                Type type = obj.GetType();
                FieldInfo[] publicFields = type.GetFields(BindingFlags.Instance | BindingFlags.Public);

                foreach (FieldInfo field in publicFields)
                {   
                    Tuple<FieldInfo, object> fieldDetails = new(field, obj);
                    externalFields.Add(field.Name, fieldDetails);
                }
            }
            else 
            {
                GD.PrintErr($"DialogueCore: There is already an instance of the {obj.GetType().Name} class within the external variables dictionary!");
            }
            
        }
        else 
        {
            GD.PrintErr($"DialogueCore: The {obj.GetType().Name} class is already part of the external variables dictionary!");
        }
    }

    public string GetExternalVariable(string text) 
    {
        if (text.StartsWith("{{") && externalFields?.Count > 0) 
        {   
            foreach (string fieldName in externalFields.Keys) 
            {   
                string keyCode = "{{" + fieldName + "}}";

                if (text.Contains(keyCode) && externalFields.TryGetValue(fieldName, out Tuple<FieldInfo, object> fieldDetails)) 
                {   
                    FieldInfo field = fieldDetails.Item1;
                    object fieldInstance = fieldDetails.Item2;

                    string formattedValue = (field.FieldType == typeof(float)) ? $"{field.GetValue(fieldInstance):0.00}" : field.GetValue(fieldInstance).ToString();
                    text = text.Replace(keyCode, formattedValue);
                }
            } 
        }
        return text;
    }

	private bool errorChecks(ref string startID) 
	{
		if (dialogueData == null) 
        {
            GD.PrintErr($"DialogueCore: No dialogue data!");
            return true;
        }
        else if (!dialogueData.Starts.ContainsKey(startID)) 
        {
             GD.PrintErr($"{dialogueData.FileName}: StartID \"{startID}\" is not present!");
             return true;
        }
		else if (dialogueUI == null) 
		{
			GD.PrintErr($"DialogueCore: DialogueUI wasn't found!");
            return true;
		}
		return false;
	}

	private void initCharacterList() 
    {   
        if (!string.IsNullOrEmpty(dialogueData.Characters))
        {
            Resource res = ResourceLoader.Load(dialogueData.Characters, "", ResourceLoader.CacheMode.Replace);

            if (res is CharacterList file) 
            {
                dialogueUI.SetCharacterList(file);
            }
            else 
            {
                GD.PrintErr($"{dialogueData.FileName}: Invalid Character List File");
            }
        }
    }

	private void initVariables() 
	{	
		if (dialogueData.Variables != null) 
		{
			variables ??= new Dictionary();
			variables.Clear();

			foreach (KeyValuePair<Variant, Variant> variant in dialogueData.Variables) 
			{   
				variant.Value.AsGodotDictionary().TryGetValue("value", out Variant value);
				setVariable(variant.Key, value);
			}
		}
	}

    private bool setExternalVariable(Variant varName, Variant value, int operatorInt) 
    {   
        if (externalFields != null && externalFields.TryGetValue(varName.AsString(), out Tuple<FieldInfo, object> fieldDetails))
        {
            FieldInfo field = fieldDetails.Item1;
            object fieldInstance = fieldDetails.Item2;
            object obj = variantAsDotNet(value);

            if (field.FieldType == obj.GetType()) 
            {
                switch (operatorInt)
                {
                    case 0:
                        // =
                        field.SetValue(fieldInstance, obj);
                        return true;
                    case 1:
                    case 2:
                    case 3:
                    case 4:
                        // +=, -=, *=, /= handle operations
                        if (field.FieldType == typeof(int)) 
                        {   
                            int currentValue = (int)field.GetValue(fieldInstance);
                            int factorInt = value.AsInt32();

                            int result = operatorInt switch 
                            {
                                1 => currentValue + factorInt,
                                2 => currentValue - factorInt,
                                3 => currentValue * factorInt,
                                4 => factorInt != 0 ? currentValue / factorInt : 0,
                                _ => -1
                            };

                            field.SetValue(fieldInstance, result);
                            return true;
                        }
                        else if (field.FieldType == typeof(float)) 
                        {
                            float currentValue = (float)field.GetValue(fieldInstance);
                            float factorFloat = value.AsInt32();

                            float result = operatorInt switch 
                            {
                                1 => currentValue + factorFloat,
                                2 => currentValue - factorFloat,
                                3 => currentValue * factorFloat,
                                4 => factorFloat != 0 ? currentValue / factorFloat : 0,
                                _ => -1
                            };

                            field.SetValue(fieldInstance, result);
                            return true;
                        }
                        else if (field.FieldType == typeof(string) && operatorInt == 1) 
                        {
                            string stringValue = field.GetValue(fieldInstance).ToString();
                            stringValue += value.AsString();
                            field.SetValue(fieldInstance, stringValue);
                            return true;
                        }
                        else 
                        {
                            string stringOP = operatorInt switch 
                            {
                                1 => "+",
                                2 => "-",
                                3 => "*",
                                4 => "/",
                                _ => "invalid",
                            };

                            GD.PrintErr($"{dialogueData.FileName}: '{varName.AsString()}' is of type '{field.GetType()}' and '{value.AsString()}' is of type '{obj.GetType()}', they can't be used with the operator '{stringOP}'");
                            return false;
                        }
                    default:
                        string op = operatorInt switch 
                        {
                            1 => "+",
                            2 => "-",
                            3 => "*",
                            4 => "/",
                            _ => "invalid",
                        };
                        GD.PrintErr($"{dialogueData.FileName}: '{varName.AsString()}' is of type '{field.GetType()}' and '{value.AsString()}' is of type '{obj.GetType()}', they can't be used with the operator '{op}'");
                        return false;
                }
            }
            else 
            {   
                GD.PrintErr($"DialogueCore: External variable {varName.AsString()} is of type {field.FieldType} and is receiving a variable of type {value.VariantType}");
                return false;
            }
        }
        else 
        {
            return false;
        }
    }

	private bool setVariable(Variant varName, Variant value, int operatorInt = 0)
    {   
        switch(operatorInt) 
        {
            case 0:
                // =
                variables[varName] = value;
                return true;
            case 1:
            case 2:
            case 3:
            case 4:
                // +=, -=, *=, /= handle operations
                if (value.VariantType == Variant.Type.Int) 
                {   
                    int currentValue = variables.Keys.Contains(varName) ? variables[varName].AsInt32() : 0;
                    int factorInt = value.AsInt32();
                    
                    variables[varName] = operatorInt switch
                    {
                        1 => currentValue + factorInt,
                        2 => currentValue - factorInt,
                        3 => currentValue * factorInt,
                        4 => factorInt != 0 ? (float)currentValue / factorInt : 0,
                        _ => variables[varName],
                    };
                    return true;
                }
                else if (value.VariantType == Variant.Type.Float) 
                {   
                    float floatValue = variables.Keys.Contains(varName) ? (float)variables[varName] : 0.0f;
                    float valueFloat = value.AsSingle();

                    variables[varName] = operatorInt switch
                    {
                        1 => floatValue + valueFloat,
                        2 => floatValue - valueFloat,
                        3 => floatValue * valueFloat,
                        4 => valueFloat != 0 ? floatValue / valueFloat : 0,
                        _ => variables[varName],
                    };
                    return true;
                }
                else if (value.VariantType == Variant.Type.String && operatorInt == 1) 
                {   
                    string stringValue = variables.Keys.Contains(varName) ? variables[varName].AsString() : "";
                    variables[varName] = stringValue + value.AsString();
                    return true;
                }
                else 
                {   
                    string op = operatorInt switch 
                    {
                        1 => "+",
                        2 => "-",
                        3 => "*",
                        4 => "/",
                        _ => "invalid",
                    };

                    GD.PrintErr($"{dialogueData.FileName}: '{varName.AsString()}' is of type '{varName.VariantType}' and '{value.AsString()}' is of type '{value.VariantType}', they can't be used with the operator '{op}'");
                    return false;
                }
            default:
            GD.PrintErr($"{dialogueData.FileName}: {varName.AsString()} comes with an invalid operator, review the dialogueData file or the dialogue nodes plugin");
            return false;
        }
    }

	public void ProcessNode(string nodeID) 
    {   
        if (nodeID == "END" || !IsRunning) 
        {   
            dialogueManager.Stop();
            return;
        }

        string type = nodeID.Split('_')[0];

        switch(type) 
        {
            case "0":
                //start
                dialogueUI.Display(true);
                dialogueData.Nodes[nodeID].AsGodotDictionary().TryGetValue("link", out Variant linkValue);
                ProcessNode(linkValue.AsString());
            break;
            case "1":
                //dialogue
                dialogueUI.SetDialogue(dialogueData.Nodes[nodeID].AsGodotDictionary());
            break;
            case "3":
                //signal
                Dictionary dict = dialogueData.Nodes[nodeID].AsGodotDictionary();

                dict.TryGetValue("signalValue", out Variant signalValue);
                dict.TryGetValue("link", out Variant link);

                dialogueManager.EmitDialogueSignal(signalValue.AsString());
                ProcessNode(link.AsString());
            break;
            case "4":
                //set
                Dictionary varDict = dialogueData.Nodes[nodeID].AsGodotDictionary();
                
                varDict.TryGetValue("value", out Variant value);
                varDict.TryGetValue("type", out Variant operatorVariant);
                varDict.TryGetValue("variable", out Variant varName);
                varDict.TryGetValue("link", out Variant varLink);

                if (!setExternalVariable(varName, value, operatorVariant.AsInt32()) && setVariable(varName, value, operatorVariant.AsInt32())) 
                {
                    dialogueManager.EmitInternalVariableChanged(varName, variables[varName]);
                }

                ProcessNode(varLink.AsString());
            break;
            case "5":
                //condition
                    bool result = CheckCondition(dialogueData.Nodes[nodeID].AsGodotDictionary());
                    dialogueData.Nodes[nodeID].AsGodotDictionary().TryGetValue(result.ToString().ToLower(), out Variant linkCondition);
                    ProcessNode(linkCondition.AsString());
            break;
            default:

                if (dialogueData.Nodes[nodeID].AsGodotDictionary().TryGetValue("link", out Variant defaultLink)) 
                {
                    ProcessNode(defaultLink.AsString());
                }
                else
                {   
                    dialogueManager.Stop();
                }
            break;
        }

        dialogueManager.EmitDialogueProceeded(type);
    }

	public bool CheckCondition(Dictionary conditionDict) 
    {   
        int operatorInt = conditionDict["operator"].AsInt32();

        conditionDict.TryGetValue("value1", out Variant varName);
        conditionDict.TryGetValue("value2", out Variant value);

        return checkExternalCondition(varName, value, operatorInt) || checkInternalCondition(varName, value, operatorInt);
    }

	public string ProcessText(string text, bool isDialogue = true) 
    {   
        if (string.IsNullOrEmpty(text) && isDialogue) 
        {
            text = " ";
        }

        if (text.Contains("{{"))
        {
            if (variables != null) 
            {   
                foreach (Variant key in variables.Keys) 
                {   
                    string keyCode = "{{" + key + "}}";

                    if (text.Contains(keyCode)) 
                    {   
                        string formattedValue = (variables[key].VariantType == Variant.Type.Float) ? $"{variables[key].AsSingle():0.00}" : variables[key].ToString();
                        text = text.Replace(keyCode, formattedValue);
                    }
                }
            }

            if (externalFields?.Count > 0) 
            {   
                foreach (string fieldName in externalFields.Keys) 
                {   
                    string keyCode = "{{" + fieldName + "}}";

                    if (text.Contains(keyCode) && externalFields.TryGetValue(fieldName, out Tuple<FieldInfo, object> fieldDetails)) 
                    {   
                        FieldInfo field = fieldDetails.Item1;
                        object fieldInstance = fieldDetails.Item2;

                        string formattedValue = (field.FieldType == typeof(float)) ? $"{field.GetValue(fieldInstance):0.00}" : field.GetValue(fieldInstance).ToString();
                        text = text.Replace(keyCode, formattedValue);
                    }
                } 
            }
        }
        
	    text = text.Replace("[br]", "\n");

        if (isDialogue && transitionType != RichTextTransitionType.None) 
        {
            text = processTransitionFX(text);
        }

        return text;
    }

    private bool checkExternalCondition(Variant varName, Variant value, int operatorInt) 
    {
        if (externalFields == null || !externalFields.ContainsKey(varName.AsString())) 
        {
            return false;
        }

        Tuple<FieldInfo, object> varDetails = externalFields[varName.AsString()];

        dynamic variableValue = varDetails.Item1.GetValue(varDetails.Item2);
        dynamic conditionValue = null;
    
        if (value.VariantType == Variant.Type.String) 
        {
            string stringValue = value.AsString();
            if (stringValue.StartsWith("{{") && stringValue.EndsWith("}}")) 
            {
                stringValue = stringValue.Substring(2, stringValue.Length - 4);

                if (!externalFields.ContainsKey(stringValue)) 
                {   
                    if (!variables.Keys.Contains(stringValue)) 
                    {
                        GD.PrintErr($"{dialogueData.FileName}: Variable {stringValue} is not part of any dictionary");
                        return false;
                    }
                    else 
                    {
                        conditionValue = variantAsDotNet(variables[stringValue]);
                    }
                }
                else 
                {   
                    Tuple<FieldInfo, object> fieldDetails = externalFields[stringValue];
                    conditionValue = fieldDetails.Item1.GetValue(fieldDetails.Item2);
                }
            }
        }
        else 
        {
            conditionValue = variantAsDotNet(value);
        }

        if (variableValue.GetType() != conditionValue.GetType()) 
        {
            GD.PrintErr($"{dialogueData.FileName}: {varName.AsString().ToUpper()} is of type {variableValue.GetType().ToString().ToUpper()} while incoming value is of type {conditionValue.GetType().ToString().ToUpper()}");
            return false;
        }

        return conditionValue.GetType() switch
        {
            Type t when t == typeof(string) || t == typeof(bool) =>
                operatorInt switch
                {
                    0 => variableValue == conditionValue,
                    1 => variableValue != conditionValue,
                    _ => false,
                },
            Type t when t == typeof(int) || t == typeof(float) =>
                operatorInt switch
                {
                    0 => variableValue == conditionValue,
                    1 => variableValue != conditionValue,
                    2 => variableValue > conditionValue,
                    3 => variableValue < conditionValue,
                    4 => variableValue >= conditionValue,
                    5 => variableValue <= conditionValue,
                    _ => false,
                },
            _ => false,
        };
    }

    private bool checkInternalCondition(Variant varName, Variant value, int operatorInt) 
    {
        if (!variables.Keys.Contains(varName)) 
        {   
            GD.PrintErr($"{dialogueData.FileName}: Variable {varName.AsString()} is not part of the internal variables dictionary");
            return false;
        }
        else if (value.VariantType == Variant.Type.String) 
        {
            string stringValue = value.AsString();
            if (stringValue.StartsWith("{{") && stringValue.EndsWith("}}")) 
            {
                stringValue = stringValue.Substring(2, stringValue.Length - 4);
                if (!variables.Keys.Contains(stringValue)) 
                {   
                    if (externalFields == null || !externalFields.ContainsKey(stringValue)) 
                    {
                        GD.PrintErr($"{dialogueData.FileName}: Variable {stringValue} is not part of any dictionary");
                        return false;
                    }
                    else 
                    {
                        Tuple<FieldInfo, object> fieldDetails = externalFields[stringValue];
                        dynamic valueDotNet = fieldDetails.Item1.GetValue(fieldDetails.Item2);
                        value = Variant.CreateFrom(valueDotNet);
                    }
                }
                else 
                {
                    value = variables[stringValue];
                }
            }
        }

        if (variables[varName].VariantType != value.VariantType) 
        {
            GD.PrintErr($"{dialogueData.FileName}: {varName.AsString().ToUpper()} is of type {variables[varName].VariantType.ToString().ToUpper()} while incoming value is of type {value.VariantType.ToString().ToUpper()}");
            return false;
        }

        return value.VariantType switch
        {
            Variant.Type.String => operatorInt switch
            {
                0 => variables[varName].AsString() == value.AsString(),
                1 => variables[varName].AsString() != value.AsString(),
                _ => false,
            },
            Variant.Type.Bool => operatorInt switch
            {
                0 => variables[varName].AsBool() == value.AsBool(),
                1 => variables[varName].AsBool() != value.AsBool(),
                _ => false,
            },
            Variant.Type.Int => operatorInt switch
            {
                0 => variables[varName].AsInt32() == value.AsInt32(),
                1 => variables[varName].AsInt32() != value.AsInt32(),
                2 => variables[varName].AsInt32() > value.AsInt32(),
                3 => variables[varName].AsInt32() < value.AsInt32(),
                4 => variables[varName].AsInt32() >= value.AsInt32(),
                5 => variables[varName].AsInt32() <= value.AsInt32(),
                _ => false,
            },
            Variant.Type.Float => operatorInt switch
            {
                0 => variables[varName].AsSingle() == value.AsSingle(),
                1 => variables[varName].AsSingle() != value.AsSingle(),
                2 => variables[varName].AsSingle() > value.AsSingle(),
                3 => variables[varName].AsSingle() < value.AsSingle(),
                4 => variables[varName].AsSingle() >= value.AsSingle(),
                5 => variables[varName].AsSingle() <= value.AsSingle(),
                _ => false,
            },
            _ => false,
        };
    }

    private string processTransitionFX(string text) 
    {   
        List<string> tags = new();

        if (transitionType == RichTextTransitionType.Console) 
        {
            text += " ";
        }

        text = sanitizeCustomTags("pause", text, ref tags);
        text = sanitizeCustomTags("speed", text, ref tags);
        text = sanitizeWaitTags(text, ref tags);
        
        return text;
    }

    private string sanitizeWaitTags(string text, ref List<string> tags) 
    {
        text = $"[wait]" + text + $"[/wait]";

        string textWithoutBBCode = bbcodeRegex.Sub(text, "", true);
        int textLength = textWithoutBBCode.Length;

        int openTagStart = text.IndexOf($"[wait", 0);
        int openTagEnd = text.IndexOf(']', 0);

        tags.Add($"start={openTagStart}");
        tags.Add($"length={textLength}");

        string insertText = "";

        foreach (string s in tags) 
        {
            insertText += " " + s;
        }

        return text.Insert(openTagEnd, insertText);
    }

    private string sanitizeCustomTags(string codeTag, string text, ref List<string> tags) 
    {
        int openTagIndex = text.IndexOf($"[{codeTag}=", 0);

        if (openTagIndex != -1)
        {
            System.Collections.Generic.Dictionary<int, float> pausesDict = new();

            while (openTagIndex != -1)
            {
                int endTagIndex = text.IndexOf(']', openTagIndex);

                if (endTagIndex != -1)
                {
                    int start = openTagIndex + $"[{codeTag}=".Length;
                    int length = endTagIndex - start;

                    if (length > 0 && float.TryParse(text.Substring(start, length), out float tagValue))
                    {
                        pausesDict.Add(openTagIndex, tagValue);
                        text = text.Remove(openTagIndex, endTagIndex - openTagIndex + 1);
                        
                        openTagIndex = text.IndexOf($"[{codeTag}=", openTagIndex);
                    }
                    else 
                    {
                        GD.PrintErr($"DialogueCore: Impossible to get {codeTag} value at index {openTagIndex}");
                        openTagIndex = -1;
                    }
                }
            }

            if (pausesDict.Count > 0)
            {
                string positionsTag = $"{codeTag}Positions=" + string.Join(",", pausesDict.Keys);
                string valuesTag = $"{codeTag}Values=" + string.Join(",", pausesDict.Values.Select(f => f.ToString(CultureInfo.InvariantCulture)));

                tags.Add(positionsTag);
                tags.Add(valuesTag);
            }
        }
        return text;
    }

	public void EndDialogue()
	{
		ProcessNode("END");
	}

    private object variantAsDotNet(Variant value)
    {
        switch (value.VariantType)
        {   
            case Variant.Type.String:
                return value.AsString();
            case Variant.Type.Int:
                return value.AsInt32();
            case Variant.Type.Float:
                return value.AsSingle();
            case Variant.Type.Bool:
                return value.AsBool();
            default:
                GD.PrintErr($"DialogueCore: Unsupported Godot Variant type");
                return false;
        }
    }
}
