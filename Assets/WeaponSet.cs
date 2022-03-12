using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponSet : MonoBehaviour {
    [SerializeField]
    private WeaponCard startingWeapon;
    private List<Weapon> weapons;
    private List<Weapon> activeWeapons;
    public delegate void WeaponSetChangedAction(WeaponSet set);
    public WeaponSetChangedAction weaponSetChanged;
    void Awake() {
        activeWeapons = new List<Weapon>();
        weapons = new List<Weapon>(GetComponentsInChildren<Weapon>(true));
        foreach(var weapon in weapons) {
            weapon.gameObject.SetActive(weapon.weaponCard == startingWeapon);
        }
        weaponSetChanged?.Invoke(this);
    }
    public List<Weapon> GetAllWeapons() {
        return weapons;
    }
    public List<Weapon> GetAllActiveWeapons() {
        activeWeapons.Clear();
        foreach(var weapon in weapons) {
            if (weapon.gameObject.activeInHierarchy) {
                activeWeapons.Add(weapon);
            }
        }
        return activeWeapons;
    }
    public void ActivateWeapon(Weapon weapon) {
        weapon.gameObject.SetActive(true);
        weaponSetChanged?.Invoke(this);
    }
    public void UpgradeWeapon(Weapon weapon) {
        weapon.Upgrade();
        weaponSetChanged?.Invoke(this);
    }
}
