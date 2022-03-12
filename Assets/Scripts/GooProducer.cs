using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooProducer : Weapon {
    public AttributeModifier projectileCountModifier;
    private int addCount;
    public override string GetUpgradeText() {
        return GenerateUpgradeLine(countText, projectileCountModifier);
    }
    protected override void OnEnable() {
        base.OnEnable();
        player.projectileCount.AddModifier(projectileCountModifier);
        addCount++;
    }
    public override void Upgrade() {
        player.projectileCount.AddModifier(projectileCountModifier);
        addCount++;
    }
    public override int GetUpgradeLevel() {
        return addCount;
    }
    public override int GetUpgradeTotal() {
        return 8;
    }
    protected override void OnDisable() {
        for(int i=0;i<addCount;i++) {
            player.projectileCount.RemoveModifier(projectileCountModifier);
        }
        addCount = 0;
    }
}
