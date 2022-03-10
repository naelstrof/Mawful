using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;

[CreateAssetMenu(fileName = "WeaponCard", menuName = "VoreGame/WeaponCard", order = 1)]
public class WeaponCard : ScriptableObject {
    public Sprite icon;
    public LocalizedString localizedName;
    public LocalizedString localizedDescription;
}
