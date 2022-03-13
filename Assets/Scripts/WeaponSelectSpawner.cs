using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization.Components;
using UnityEngine.UI;

public class WeaponSelectSpawner : MonoBehaviour {
    [SerializeField]
    private WeaponCard defaultWeapon;
    [SerializeField]
    private List<WeaponCard> availableWeapons;
    [SerializeField]
    private GameObject weaponDisplayPrefab;
    [SerializeField]
    private GameObject panel;
    [SerializeField]
    private GameObject nextPanel;

    private List<GameObject> createdObjects;
    void OnEnable() {
        if (createdObjects == null) {
            createdObjects = new List<GameObject>();
        }
        foreach(GameObject obj in createdObjects) {
            Destroy(obj);
        }
        foreach(WeaponCard card in availableWeapons) {
            GameObject obj = GameObject.Instantiate(weaponDisplayPrefab, transform);
            obj.transform.Find("Image").GetComponent<Image>().sprite = card.icon;
            obj.GetComponentInChildren<LocalizeStringEvent>().StringReference = card.localizedName;
            obj.GetComponentInChildren<Button>().onClick.AddListener(()=>{
                WeaponSet.SetStaringWeapons(new WeaponCard[] { card, defaultWeapon});
                panel.SetActive(false);
                nextPanel.SetActive(true);
            });
            createdObjects.Add(obj);
        }
        createdObjects[0].GetComponentInChildren<Selectable>().Select();
    }
}
