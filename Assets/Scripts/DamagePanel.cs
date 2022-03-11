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
        float dps = (weaponDamage.totalDamage*10f/timeHeld);
        dpsText.text = "DPS " + dps.ToString("0.00");
        timeHeldText.text = Mathf.FloorToInt(timeHeld/60f).ToString("N0") + ":" + Mathf.Repeat(timeHeld,60f).ToString("00");
        totalDamageText.text = (weaponDamage.totalDamage*10f).ToString("N0");
    }
}
