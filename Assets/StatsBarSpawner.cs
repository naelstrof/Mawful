using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class StatsBarSpawner : MonoBehaviour {
    [SerializeField]
    private Character target;
    [SerializeField]
    private GameObject barPrefab;
    private Dictionary<Attribute, StatBar> bars = new Dictionary<Attribute, StatBar>();
    private HashSet<StatBar> modBars = new HashSet<StatBar>();
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
    private StatBlock subscribed;
    private StatBlock displayed;
    private bool isWeapon;
    //void Awake() {
        //bars = new Dictionary<Attribute, StatBar>();
        //modBars = new HashSet<StatBar>();
    //}
    void Start() {
        if (target != null) {
            Subscribe(target.stats, false);
        }
    }
    void OnDestroy() {
        if (subscribed != null) {
            Unsubscribe(subscribed);
        }
    }
    void OnStatsChanged(float newValue) {
        Setup(subscribed, isWeapon);
    }
    public void Subscribe(StatBlock block, bool weapon) {
        if (subscribed != null) {
            Unsubscribe(subscribed);
        }
        isWeapon = weapon;
        subscribed = block;
        if (!weapon) {
            block.health.changed += OnStatsChanged;
            block.walkSpeed.changed += OnStatsChanged;
            block.grabRange.changed += OnStatsChanged;
        }
        block.luck.changed += OnStatsChanged;
        block.damage.changed += OnStatsChanged;
        block.projectileCooldown.changed += OnStatsChanged;
        block.projectileCount.changed += OnStatsChanged;
        block.projectilePenetration.changed += OnStatsChanged;
        block.projectileRadius.changed += OnStatsChanged;
        block.projectileSpeed.changed += OnStatsChanged;
        block.knockback.changed += OnStatsChanged;
        Setup(block, weapon);
    }
    public void Unsubscribe(StatBlock block) {
        block.health.changed -= OnStatsChanged;
        block.walkSpeed.changed -= OnStatsChanged;
        block.luck.changed -= OnStatsChanged;
        block.grabRange.changed -= OnStatsChanged;
        block.damage.changed -= OnStatsChanged;
        block.projectileCooldown.changed -= OnStatsChanged;
        block.projectileCount.changed -= OnStatsChanged;
        block.projectilePenetration.changed -= OnStatsChanged;
        block.projectileRadius.changed -= OnStatsChanged;
        block.projectileSpeed.changed -= OnStatsChanged;
        block.knockback.changed -= OnStatsChanged;
        Cleanup();
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
        foreach(var bar in modBars) {
            Destroy(bar.gameObject);
        }
        bars.Clear();
        modBars.Clear();
    }
    void CreateBar(AttributeModifier attrMod, Sprite sprite) {
        if (attrMod == null) {
            return;
        }
        GameObject obj = GameObject.Instantiate(barPrefab, transform);
        StatBar bar = obj.GetComponent<StatBar>();
        bar.Setup(sprite,attrMod);
        modBars.Add(bar);
    }
    public void Setup(StatBlock block, bool weapon) {
        if (block != displayed) {
            Cleanup();
            displayed = block;
        }
        if (!weapon) {
            CreateBar(block.health, healthSprite);
            CreateBar(block.walkSpeed, walkSpeedSprite);
            CreateBar(block.grabRange, grabRangeSprite);
        }
        CreateBar(block.luck, luckSprite);
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
