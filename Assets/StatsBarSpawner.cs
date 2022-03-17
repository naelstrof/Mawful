using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StatsBarSpawner : MonoBehaviour {
    [SerializeField]
    private Character target;
    [SerializeField]
    private GameObject barPrefab;
    private Dictionary<Attribute, StatBar> bars;
    private Dictionary<AttributeModifier, StatBar> modBars;
    public Sprite healthSprite;
    public Sprite walkSpeedSprite;
    public Sprite luckSprite;
    public Sprite grabRangeSprite;
    public Sprite damageSprite;
    public Sprite projectileCooldownSprite;
    public Sprite projectileCountSprite;
    public Sprite projectilePenetrationSprite;
    public Sprite projectileRadiusSprite;
    public Sprite projectileSpeedSprite;
    public Sprite knockbackSprite;
    void Start() {
        bars = new Dictionary<Attribute, StatBar>();
        modBars = new Dictionary<AttributeModifier, StatBar>();
        if (target != null) {
            Setup(target.stats);
            target.stats.health.changed += OnStatsChanged;
            target.stats.walkSpeed.changed += OnStatsChanged;
            target.stats.luck.changed += OnStatsChanged;
            target.stats.grabRange.changed += OnStatsChanged;
            target.stats.damage.changed += OnStatsChanged;
            target.stats.projectileCooldown.changed += OnStatsChanged;
            target.stats.projectileCount.changed += OnStatsChanged;
            target.stats.projectilePenetration.changed += OnStatsChanged;
            target.stats.projectileRadius.changed += OnStatsChanged;
            target.stats.projectileSpeed.changed += OnStatsChanged;
            target.stats.knockback.changed += OnStatsChanged;
        }
    }
    void OnDestroy() {
        if (target != null) {
            target.stats.health.changed -= OnStatsChanged;
            target.stats.walkSpeed.changed -= OnStatsChanged;
            target.stats.luck.changed -= OnStatsChanged;
            target.stats.grabRange.changed -= OnStatsChanged;
            target.stats.damage.changed -= OnStatsChanged;
            target.stats.projectileCooldown.changed -= OnStatsChanged;
            target.stats.projectileCount.changed -= OnStatsChanged;
            target.stats.projectilePenetration.changed -= OnStatsChanged;
            target.stats.projectileRadius.changed -= OnStatsChanged;
            target.stats.projectileSpeed.changed -= OnStatsChanged;
            target.stats.knockback.changed -= OnStatsChanged;
        }
    }
    void OnStatsChanged(float newValue) {
        Setup(target.stats);
    }
    void CreateBar(Attribute attr, Sprite sprite) {
        if (bars.ContainsKey(attr)) {
            bars[attr].Setup(sprite, attr);
            return;
        }
        GameObject obj = GameObject.Instantiate(barPrefab, transform);
        StatBar bar = obj.GetComponent<StatBar>();
        bar.Setup(sprite,attr);
        bars.Add(attr, bar);
    }
    public void Cleanup() {
        foreach(var pair in bars) {
            Destroy(pair.Value.gameObject);
        }
        foreach(var pair in modBars) {
            Destroy(pair.Value.gameObject);
        }
        modBars.Clear();
        bars.Clear();
    }
    void CreateBar(AttributeModifier attrMod, Sprite sprite) {
        if (attrMod == null) {
            return;
        }
        if (modBars.ContainsKey(attrMod)) {
            modBars[attrMod].Setup(sprite, attrMod);
            return;
        }
        GameObject obj = GameObject.Instantiate(barPrefab, transform);
        StatBar bar = obj.GetComponent<StatBar>();
        bar.Setup(sprite,attrMod);
        modBars.Add(attrMod, bar);
    }
    public void Setup(StatBlock block) {
        CreateBar(block.health, healthSprite);
        CreateBar(block.walkSpeed, walkSpeedSprite);
        CreateBar(block.luck, luckSprite);
        CreateBar(block.grabRange, grabRangeSprite);
        CreateBar(block.damage, damageSprite);
        CreateBar(block.projectileCooldown, projectileCooldownSprite);
        CreateBar(block.projectileCount, projectileCountSprite);
        CreateBar(block.projectilePenetration, projectilePenetrationSprite);
        CreateBar(block.projectileRadius, projectileRadiusSprite);
        CreateBar(block.projectileSpeed, projectileSpeedSprite);
        CreateBar(block.knockback, knockbackSprite);
    }
    public void Setup(StatBlockModifier modifier) {
        Cleanup();
        // Full cleanup on modifiers, since some don't even exist!
        CreateBar(modifier.health, healthSprite);
        CreateBar(modifier.walkSpeed, walkSpeedSprite);
        CreateBar(modifier.luck, luckSprite);
        CreateBar(modifier.grabRange, grabRangeSprite);
        CreateBar(modifier.damage, damageSprite);
        CreateBar(modifier.projectileCooldown, projectileCooldownSprite);
        CreateBar(modifier.projectileCount, projectileCountSprite);
        CreateBar(modifier.projectilePenetration, projectilePenetrationSprite);
        CreateBar(modifier.projectileRadius, projectileRadiusSprite);
        CreateBar(modifier.projectileSpeed, projectileSpeedSprite);
        CreateBar(modifier.knockback, knockbackSprite);
    }
}
