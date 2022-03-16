using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;

[System.Serializable]
public class StatBlock {
    public HealthAttribute health;
    public Attribute walkSpeed;
    public LuckAttribute luck;
    public Attribute grabRange;
    public Attribute damage;
    public Attribute projectileCooldown;
    public Attribute projectileCount;
    public Attribute projectilePenetration;
    public Attribute projectileRadius;
    public Attribute projectileSpeed;
    public Attribute knockback;
    public void SetParent(StatBlock block) {
        health.SetParentAttribute(block.health);
        damage.SetParentAttribute(block.damage);
        projectileCooldown.SetParentAttribute(block.projectileCooldown);
        projectileCount.SetParentAttribute(block.projectileCount);
        projectilePenetration.SetParentAttribute(block.projectilePenetration);
        projectileRadius.SetParentAttribute(block.projectileRadius);
        projectileSpeed.SetParentAttribute(block.projectileSpeed);
        walkSpeed.SetParentAttribute(block.walkSpeed);
        luck.SetParentAttribute(block.luck);
        grabRange.SetParentAttribute(block.grabRange);
        knockback.SetParentAttribute(block.knockback);
    }
}

[System.Serializable]
public class StatBlockModifier {
    public AttributeModifier health;
    public AttributeModifier damage;
    public AttributeModifier walkSpeed;
    public AttributeModifier luck;
    public AttributeModifier grabRange;
    public AttributeModifier projectileCooldown;
    public AttributeModifier projectileCount;
    public AttributeModifier projectilePenetration;
    public AttributeModifier projectileRadius;
    public AttributeModifier projectileSpeed;
    public AttributeModifier knockback;
    public void Apply(StatBlock block) {
        block.health.AddModifier(health);
        block.damage.AddModifier(damage);
        block.projectileCooldown.AddModifier(projectileCooldown);
        block.projectileCount.AddModifier(projectileCount);
        block.projectilePenetration.AddModifier(projectilePenetration);
        block.projectileRadius.AddModifier(projectileRadius);
        block.projectileSpeed.AddModifier(projectileSpeed);
        block.walkSpeed.AddModifier(walkSpeed);
        block.luck.AddModifier(luck);
        block.grabRange.AddModifier(grabRange);
        block.knockback.AddModifier(knockback);
    }
    public void Revert(StatBlock block) {
        block.health.RemoveModifier(health);
        block.damage.RemoveModifier(damage);
        block.projectileCooldown.RemoveModifier(projectileCooldown);
        block.projectileCount.RemoveModifier(projectileCount);
        block.projectilePenetration.RemoveModifier(projectilePenetration);
        block.projectileRadius.RemoveModifier(projectileRadius);
        block.projectileSpeed.RemoveModifier(projectileSpeed);
        block.walkSpeed.RemoveModifier(walkSpeed);
        block.luck.RemoveModifier(luck);
        block.grabRange.RemoveModifier(grabRange);
        block.knockback.RemoveModifier(knockback);
    }
}