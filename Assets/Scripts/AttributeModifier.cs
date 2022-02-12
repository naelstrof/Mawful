using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "New Attribute Modifier", menuName = "VoreGame/AttributeModifier", order = 1)]
public class AttributeModifier : ScriptableObject {
    public float baseValue;
    public float diminishingReturnUp;
    public float flatUp;
    public float multiplier = 1f;
}