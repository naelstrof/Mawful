using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Events;

public class MetaUpgradeSpawner : MonoBehaviour {
    [SerializeField]
    private GameObject prefab;
    //[SerializeField]
    //private List<MetaUpgrade> availableUpgrades;

    [SerializeField]
    private UnityEvent onUpgrade;
    [SerializeField]
    private XPPanelAvailableDisplay xpDisplay;
    void Start() {
        List<MetaUpgrade> availableUpgrades = MetaUpgradeManager.GetUpgrades();
        for(int i=0;i<availableUpgrades.Count;i++) {
            GameObject obj = GameObject.Instantiate(prefab, transform);
            MetaUpgradePanel panel = obj.GetComponent<MetaUpgradePanel>();
            panel.Setup(availableUpgrades[i]);
            Button button = panel.GetComponentInChildren<Button>();
            int target = i;
            button.onClick.AddListener(()=>{
                if (availableUpgrades[target].AttemptLevelUp()) {
                    panel.Setup(availableUpgrades[target]);
                    onUpgrade.Invoke();
                    xpDisplay.Refresh();
                }
            });
        }
    }
}
