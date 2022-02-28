using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Localization;
using UnityEngine.Localization.Components;

public class UpgradeSpawner : MonoBehaviour {
    [SerializeField]
    private GameObject buttonPrefab;
    private List<GameObject> buttons;
    private HashSet<int> takenChoices;
    [SerializeField]
    private Sprite newWeapon;
    [SerializeField]
    private Sprite upgradeWeapon;
    void Awake() {
        takenChoices = new HashSet<int>();
        buttons = new List<GameObject>();
    }
    void Start() {
        Leveler.instance.levelUp += OnLevelUp;
        gameObject.SetActive(false);
    }
    int GetAllChoices() {
        int count = 0;
        foreach(Weapon weapon in Weapon.weapons) {
            if (!weapon.gameObject.activeSelf || weapon.CanUpgrade()) {
                count++;
            }
        }
        return count;
    }
    GameObject ComputeChoice() {
        int maxChoices = GetAllChoices();
        if (maxChoices == 0) {
            return null;
        }
        bool allTaken = true;
        for(int i=0;i<maxChoices;i++) {
            if (!takenChoices.Contains(i)) {
                allTaken = false;
            }
        }
        if (allTaken) {
            return null;
        }

        int choice = UnityEngine.Random.Range(0, maxChoices);
        while(takenChoices.Contains(choice)) {
            choice = UnityEngine.Random.Range(0, maxChoices);
        }
        takenChoices.Add(choice);
        GameObject newButton = GameObject.Instantiate(buttonPrefab, transform);
        int currentChoice = 0;
        foreach(Weapon weapon in Weapon.weapons) {
            if (!weapon.gameObject.activeSelf) {
                if (currentChoice++ == choice) {
                    newButton.transform.Find("Image").GetComponent<Image>().sprite = newWeapon;
                    newButton.GetComponentInChildren<LocalizeStringEvent>().StringReference = weapon.weaponName;
                    //newButton.GetComponentInChildren<TMPro.TMP_Text>().text = weapon.weaponName.GetLocalizedString();//"Weapon " + weapon.gameObject.name;
                    newButton.GetComponent<Button>().onClick.AddListener(()=>{
                        weapon.gameObject.SetActive(true);
                        gameObject.SetActive(false);
                        Pauser.SetPaused(false);
                    });
                    return newButton;
                }
                continue;
            }
            if (weapon.CanUpgrade()) {
                if (currentChoice++ == choice) {
                    newButton.GetComponentInChildren<LocalizeStringEvent>().StringReference = weapon.weaponName;
                    //newButton.GetComponentInChildren<TMPro.TMP_Text>().text = "Upgrade " + weapon.gameObject.name;
                    newButton.transform.Find("Image").GetComponent<Image>().sprite = upgradeWeapon;
                    newButton.GetComponent<Button>().onClick.AddListener(()=>{
                        weapon.Upgrade();
                        gameObject.SetActive(false);
                        Pauser.SetPaused(false);
                    });
                    return newButton;
                }
            }
        }
        return newButton;
    }
    void OnLevelUp() {
        Pauser.SetPaused(true);
        foreach(GameObject button in buttons) {
            Destroy(button);
        }
        buttons.Clear();
        gameObject.SetActive(true);
        for(int i=0;i<3;i++) {
            GameObject newButton = ComputeChoice();
            if (newButton != null) {
                buttons.Add(newButton);
            }
        }
        takenChoices.Clear();
        buttons[0].GetComponent<Button>().Select();
    }
}
