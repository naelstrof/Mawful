using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Passive : Weapon {
    private int realUpgradeLevel = 0;
    protected override void OnEnable() {
        base.OnEnable();
        currentUpgrade = 0;
        Upgrade();
        realUpgradeLevel = 0;
    }
    public override void Upgrade() {
        StatBlockModifier upgrade = upgrades[currentUpgrade++];
        upgrade.Apply(player.stats);
        realUpgradeLevel++;
    }
    public override int GetUpgradeLevel() {
        return realUpgradeLevel;
    }
    public override int GetUpgradeTotal() {
        return upgrades.Count-1;
    }
    protected override void OnDisable() {
        for(int i=0;i<currentUpgrade;i++) {
            StatBlockModifier upgrade = upgrades[i];
            upgrade.Revert(player.stats);
        }
        realUpgradeLevel = 0;
        currentUpgrade = 0;
    }
}
