using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponProgressSpawner : MonoBehaviour {
    [SerializeField]
    private GameObject weaponProgressPanelPrefab;
    private List<GameObject> weaponProgressPanels;
    void Start() {
        Weapon.weaponSetChanged += OnWeaponSetChanged;
        weaponProgressPanels = new List<GameObject>();
        OnWeaponSetChanged(Weapon.weapons);
    }
    void OnDestroy() {
        Weapon.weaponSetChanged -= OnWeaponSetChanged;
    }
    void OnWeaponSetChanged(HashSet<Weapon> weapons) {
        List<Weapon> aliveWeapons = new List<Weapon>();
        foreach(Weapon weapon in weapons) {
            // We check if the gameobject is active, since the monobehavior could be disabled from a pause.
            if (weapon.gameObject.activeInHierarchy) {
                aliveWeapons.Add(weapon);
            }
        }
        foreach(GameObject obj in weaponProgressPanels) {
            Destroy(obj);
        }
        weaponProgressPanels.Clear();

        for(int i=weaponProgressPanels.Count;i<aliveWeapons.Count;i++) {
            GameObject obj = GameObject.Instantiate(weaponProgressPanelPrefab, transform);
            weaponProgressPanels.Add(obj);
        }
        for(int i=0;i<aliveWeapons.Count;i++) {
            weaponProgressPanels[i].GetComponent<WeaponProgressPanel>().Setup(aliveWeapons[i]);
        }
    }
}
