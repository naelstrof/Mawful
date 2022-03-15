using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;
using UnityEngine.UI;

[CreateAssetMenu(fileName = "New Meta Upgrade", menuName = "VoreGame/Meta Upgrade", order = 1)]
public class MetaUpgrade : ScriptableObject {
    public Sprite sprite;
    public LocalizedString description;
    public ScoreCard resource;
    public int defaultValue;
    public int min;
    public int max;
    [System.NonSerialized]
    public int value;
    public void Load() {
        value = PlayerPrefs.GetInt("MetaUpgrade"+name, defaultValue);
        //value = defaultValue;
    }
    public void Save() {
        PlayerPrefs.SetInt("MetaUpgrade"+name, value);
    }
    public int GetCost() {
        // 2^(value+6)+10
        return (2<<(value+6)) + 10;
    }
    public bool AttemptLevelUp() {
        int cost = GetCost();
        float resourceCount = Score.GetXP(resource);
        if (resourceCount > cost && value < max) {
            Score.SetXP(resource, resourceCount-cost);
            value = Mathf.Clamp(value+1,min,max);
            Save();
            return true;
        }
        return false;
    }
}
