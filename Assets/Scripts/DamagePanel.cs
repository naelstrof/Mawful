using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DamagePanel : MonoBehaviour {
    public TMPro.TMP_Text dpsText;
    public TMPro.TMP_Text timeHeldText;
    public TMPro.TMP_Text totalDamageText;
    public Image weaponIcon;
    public void Setup(WeaponCard card, Score.WeaponDamage weaponDamage) {
        weaponIcon.sprite = card.icon;
        float timeHeld = (weaponDamage.endTime-weaponDamage.startTime);
        float dps = (weaponDamage.totalDamage/timeHeld)*10f;
        dpsText.text = "DPS " + dps.ToString("N0");
        timeHeldText.text = Mathf.FloorToInt(timeHeld/60f).ToString("N0") + Mathf.Repeat(timeHeld,60f).ToString("N0");
        totalDamageText.text = (weaponDamage.totalDamage*10f).ToString("N0");
    }
}
