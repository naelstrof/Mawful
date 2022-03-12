using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ExtraHeart : Weapon {
    public AttributeModifier cooldownModifier;
    public AttributeModifier damageModifier;
    public AttributeModifier speedModifier;
    public AttributeModifier radiusModifer;
    private int addCount;
    public override string GetUpgradeText() {
        string line = "";
        line += GenerateUpgradeLine(cooldownText, cooldownModifier);
        line += GenerateUpgradeLine(damageText, damageModifier);
        line += GenerateUpgradeLine(speedText, speedModifier);
        line += GenerateUpgradeLine(radiusText, radiusModifer);
        return line;
    }
    protected override void OnEnable() {
        base.OnEnable();
        player.projectileCooldown.AddModifier(cooldownModifier);
        player.damage.AddModifier(damageModifier);
        player.speed.AddModifier(speedModifier);
        player.projectileRadius.AddModifier(radiusModifer);
        addCount++;
    }
    public override void Upgrade() {
        player.projectileCooldown.AddModifier(cooldownModifier);
        player.damage.AddModifier(damageModifier);
        player.speed.AddModifier(speedModifier);
        player.projectileRadius.AddModifier(radiusModifer);
        addCount++;
    }
    public override int GetUpgradeLevel() {
        return addCount;
    }
    public override int GetUpgradeTotal() {
        return 2;
    }
    protected override void OnDisable() {
        for(int i=0;i<addCount;i++) {
            player.projectileCooldown.RemoveModifier(cooldownModifier);
            player.damage.RemoveModifier(damageModifier);
            player.speed.RemoveModifier(speedModifier);
            player.projectileRadius.RemoveModifier(radiusModifer);
        }
        addCount = 0;
    }
}
