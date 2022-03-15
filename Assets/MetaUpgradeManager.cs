using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MetaUpgradeManager : MonoBehaviour {
    private static MetaUpgradeManager instance;
    public static List<MetaUpgrade> GetUpgrades() => instance.availableUpgrades;
    public List<MetaUpgrade> availableUpgrades;
    void Awake() {
        if (instance != null) {
            Destroy(gameObject);
            return;
        }
        instance = this;
        foreach(MetaUpgrade upgrade in availableUpgrades) {
            upgrade.Load();
        }
    }
}
