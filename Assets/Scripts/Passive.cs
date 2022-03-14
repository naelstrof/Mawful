using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Passive : Weapon {
    protected override void OnEnable() {
        base.OnEnable();
        Upgrade();
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
    }
    public override int GetUpgradeLevel() {
        return currentUpgrade-1;
    }
    public override int GetUpgradeTotal() {
        return upgrades.Count;
    }
    protected override void OnDisable() {
        for(int i=0;i<currentUpgrade;i++) {
            WeaponUpgrade upgrade = upgrades[i];
            player.projectileCount.RemoveModifier(upgrade.countModifier);
            player.damage.RemoveModifier(upgrade.damageModifier);
            player.projectileCooldown.RemoveModifier(upgrade.cooldownModifier);
            player.projectilePenetration.RemoveModifier(upgrade.penetrationModifier);
            player.projectileRadius.RemoveModifier(upgrade.radiusModifier);
            player.projectileSpeed.RemoveModifier(upgrade.speedModifier);
            player.speed.RemoveModifier(upgrade.playerSpeedModifier);
        }
        currentUpgrade = 0;
    }
}
