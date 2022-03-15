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
        WeaponUpgrade upgrade = upgrades[currentUpgrade++];
        player.projectileCount.AddModifier(upgrade.countModifier);
        player.damage.AddModifier(upgrade.damageModifier);
        player.projectileCooldown.AddModifier(upgrade.cooldownModifier);
        player.projectilePenetration.AddModifier(upgrade.penetrationModifier);
        player.projectileRadius.AddModifier(upgrade.radiusModifier);
        player.projectileSpeed.AddModifier(upgrade.speedModifier);
        player.speed.AddModifier(upgrade.playerSpeedModifier);
        realUpgradeLevel++;
    }
    public override int GetUpgradeLevel() {
        return realUpgradeLevel;
    }
    public override int GetUpgradeTotal() {
        return upgrades.Count-1;
    }
    protected override void OnDisable() {
        for(int i=0;i<realUpgradeLevel;i++) {
            WeaponUpgrade upgrade = upgrades[i];
            player.projectileCount.RemoveModifier(upgrade.countModifier);
            player.damage.RemoveModifier(upgrade.damageModifier);
            player.projectileCooldown.RemoveModifier(upgrade.cooldownModifier);
            player.projectilePenetration.RemoveModifier(upgrade.penetrationModifier);
            player.projectileRadius.RemoveModifier(upgrade.radiusModifier);
            player.projectileSpeed.RemoveModifier(upgrade.speedModifier);
            player.speed.RemoveModifier(upgrade.playerSpeedModifier);
        }
        realUpgradeLevel = 0;
        currentUpgrade = 0;
    }
}
