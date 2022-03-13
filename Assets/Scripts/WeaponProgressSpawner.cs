using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WeaponProgressSpawner : MonoBehaviour {
    [SerializeField]
    private WeaponSet weaponSet;
    [SerializeField]
    private GameObject weaponProgressPanelPrefab;
    private List<GameObject> weaponProgressPanels;
    void Start() {
        weaponSet.weaponSetChanged += OnWeaponSetChanged;
        weaponProgressPanels = new List<GameObject>();
        OnWeaponSetChanged(weaponSet);
    }
    void OnDestroy() {
        weaponSet.weaponSetChanged -= OnWeaponSetChanged;
    }
    void OnWeaponSetChanged(WeaponSet weaponSet) {
        foreach(GameObject obj in weaponProgressPanels) {
            Destroy(obj);
        }
        weaponProgressPanels.Clear();
        List<Weapon> aliveWeapons = weaponSet.GetAllActiveWeapons();
        for(int i=weaponProgressPanels.Count;i<aliveWeapons.Count;i++) {
            GameObject obj = GameObject.Instantiate(weaponProgressPanelPrefab, transform);
            weaponProgressPanels.Add(obj);
        }
        for(int i=0;i<aliveWeapons.Count;i++) {
            weaponProgressPanels[i].GetComponent<WeaponProgressPanel>().Setup(aliveWeapons[i]);
        }
    }
}
