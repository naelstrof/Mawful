using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[System.Serializable]
public class Attribute : ISerializationCallbackReceiver {
    public delegate void AttributeChangedAction(float newValue);
    public event AttributeChangedAction changed;
    private Attribute parentAttribute;
    private HashSet<Attribute> childAttributes;

    [SerializeField]

    private List<AttributeModifier> modifiers;
    private float baseValue;
    private float multiplier;
    private float diminishingReturnUp;
    private float flatUp;
    private float cachedValue;
    private void CacheData() {
        // Inherit our parent's data, only if we have one.
        if (parentAttribute == null) {
            baseValue = 0f;
            multiplier = 1f;
            diminishingReturnUp = 0f;
            flatUp = 0f;
        } else {
            baseValue = parentAttribute.baseValue;
            multiplier = parentAttribute.multiplier;
            diminishingReturnUp = parentAttribute.diminishingReturnUp;
            flatUp = parentAttribute.flatUp;
        }
        // Add up our modifiers on top
        foreach(AttributeModifier modifier in modifiers) {
            if (modifier == null) {
                continue;
            }
            baseValue += modifier.baseValue;
            diminishingReturnUp += modifier.diminishingReturnUp;
            flatUp += modifier.flatUp;
            multiplier *= modifier.multiplier;
        }
        cachedValue = CalculateValue();
        changed?.Invoke(GetValue());
        // Propagate down
        if (childAttributes != null) {
            foreach(Attribute childAttribute in childAttributes) {
                childAttribute.CacheData();
            }
        }
    }
    protected virtual float CalculateValue() {
        return (baseValue * Mathf.Sqrt(diminishingReturnUp + 1f) + flatUp)*multiplier;
    } 
    public void SetParentAttribute(Attribute parent) {
        if (parent != null && parent.childAttributes != null) {
            parent.childAttributes.Remove(this);
        }
        parentAttribute = parent;
        CacheData();
        if (parent == null) {
            return;
        }
        if (parent.childAttributes == null) {
            parent.childAttributes = new HashSet<Attribute>();
        }
        parent.childAttributes.Add(this);
    }
    public virtual void AddModifier(AttributeModifier modifier) {
        if (modifier == null) {
            return;
        }
        modifiers.Add(modifier);
        CacheData();
    }
    public virtual void RemoveModifier(AttributeModifier modifier) {
        modifiers.Remove(modifier);
        CacheData();
    }
    public float GetValue() {
        return cachedValue;
    }
    public void OnBeforeSerialize() {
    }

    public void OnAfterDeserialize() {
        CacheData();
    }
}

[System.Serializable]
public class HealthAttribute : Attribute {
    public delegate void AttributeAction();
    public event AttributeAction depleted;
    private float value;
    public override void AddModifier(AttributeModifier modifier) {
        float valueRatio = value/GetValue();
        base.AddModifier(modifier);
        value = valueRatio*GetValue();
    }
    public override void RemoveModifier(AttributeModifier modifier) {
        float valueRatio = value/GetValue();
        base.RemoveModifier(modifier);
        value = valueRatio*GetValue();
    }
    public void Damage(float amount) {
        if (value <= 0f) {
            return;
        }
        value = Mathf.Max(value-amount, 0f);
        if (value<=0f) {
            depleted?.Invoke();
        }
    }
    public void Heal(float amount) {
        value = Mathf.Min(value+amount, GetValue());
    }
    public float GetHealth() {
        return value;
    }
}