using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponDamageSpawner : MonoBehaviour {
    public GameObject panelPrefab;
    void Start() {
        var damageData = Score.GetDamageData();
        foreach(var pair in damageData) {
            GameObject obj = GameObject.Instantiate(panelPrefab, transform);
            DamagePanel panel = obj.GetComponent<DamagePanel>();
            panel.Setup(pair.Key, pair.Value);
        }
    }
}
