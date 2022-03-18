using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponProgressSpawner : MonoBehaviour {
    [SerializeField]
    private WeaponSet weaponSet;
    [SerializeField]
    private GameObject weaponProgressPanelPrefab;
    private Dictionary<Weapon,GameObject> weaponProgressPanels;
    void Start() {
        weaponSet.weaponSetChanged += OnWeaponSetChanged;
        weaponProgressPanels = new Dictionary<Weapon, GameObject>();
        OnWeaponSetChanged(weaponSet);
    }
    void OnDestroy() {
        weaponSet.weaponSetChanged -= OnWeaponSetChanged;
    }
    void OnWeaponSetChanged(WeaponSet weaponSet) {
        List<Weapon> aliveWeapons = weaponSet.GetAllActiveWeapons();
        List<Weapon> allWeapons = weaponSet.GetAllWeapons();
        // Destroy weapon panels that were removed (shouldn't happen, but just being robust)
        foreach(Weapon weapon in allWeapons) {
            if (!aliveWeapons.Contains(weapon) && weaponProgressPanels.ContainsKey(weapon)) {
                Destroy(weaponProgressPanels[weapon]);
                weaponProgressPanels.Remove(weapon);
            }
        }
        // Create panels that are new
        foreach(Weapon weapon in aliveWeapons) {
            if (!weaponProgressPanels.ContainsKey(weapon)) {
                GameObject obj = GameObject.Instantiate(weaponProgressPanelPrefab, transform);
                weaponProgressPanels.Add(weapon, obj);
            }
            // Then update them
            weaponProgressPanels[weapon].GetComponent<WeaponProgressPanel>().Setup(weapon);
            weaponProgressPanels[weapon].GetComponent<SelectHandler>().onSelect += (callback) => {
                weaponProgressPanels[weapon].GetComponent<WeaponProgressPanel>().Show();
            };
        }
    }
}
