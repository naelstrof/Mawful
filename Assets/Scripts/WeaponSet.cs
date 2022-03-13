using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponSet : MonoBehaviour {
    [SerializeField]
    private List<WeaponCard> localStartingWeapons;
    private static List<WeaponCard> startingWeapons;
    public static void SetStaringWeapons(WeaponCard[] cards) {
        startingWeapons = new List<WeaponCard>(cards);
    }
    private List<Weapon> weapons;
    [SerializeField]
    private List<Weapon> ultimateWeapons;
    private List<Weapon> activeWeapons;
    private PlayerCharacter player;
    public delegate void WeaponSetChangedAction(WeaponSet set);
    public WeaponSetChangedAction weaponSetChanged;
    void Awake() {
        if (startingWeapons == null) {
            startingWeapons = new List<WeaponCard>();
            startingWeapons.AddRange(localStartingWeapons);
        }
        activeWeapons = new List<Weapon>();
        weapons = new List<Weapon>(GetComponentsInChildren<Weapon>(true));
        foreach(var weapon in weapons) {
            weapon.gameObject.SetActive(startingWeapons.Contains(weapon.weaponCard));
        }
        // Can only have one ultimate weapon at a time...
        foreach(var weapon in ultimateWeapons) {
            if (!startingWeapons.Contains(weapon.weaponCard)) {
                weapons.Remove(weapon);
            }
        }
        weaponSetChanged?.Invoke(this);
        player = GetComponentInParent<PlayerCharacter>();
        player.died += OnDie;
    }
    public void OnDie() {
        foreach(Weapon weapon in weapons) {
            weapon.gameObject.SetActive(false);
        }
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
