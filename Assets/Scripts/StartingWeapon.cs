using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StartingWeapon : MonoBehaviour {
    [SerializeField]
    private Weapon startingWeapon;
    void Start() {
        foreach(Weapon weapon in Weapon.weapons) {
            if (weapon != startingWeapon) {
                weapon.gameObject.SetActive(false);
            }
        }
    }
}
