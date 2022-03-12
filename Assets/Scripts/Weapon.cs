using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;

public class Weapon : MonoBehaviour {
    //public LocalizedString weaponName;
    [SerializeField]
    public WeaponCard weaponCard;
    public static HashSet<Weapon> weapons = new HashSet<Weapon>();
    public delegate void WeaponSetChangedAction(HashSet<Weapon> weapons);
    public static WeaponSetChangedAction weaponSetChanged;
    [SerializeField]
    private LocalizedString countText;
    [SerializeField]
    private LocalizedString damageText;
    [SerializeField]
    private LocalizedString cooldownText;
    [SerializeField]
    private LocalizedString penetrationText;
    [SerializeField]
    private LocalizedString radiusText;
    [SerializeField]
    private LocalizedString speedText;
    [System.Serializable]
    private class WeaponUpgrade {
        public AttributeModifier countModifier;
        public AttributeModifier damageModifier;
        public AttributeModifier cooldownModifier;
        public AttributeModifier penetrationModifier;
        public AttributeModifier radiusModifier;
        public AttributeModifier speedModifier;
    }
    [SerializeField]
    private List<WeaponUpgrade> upgrades;
    private int currentUpgrade = 0;
    public virtual int GetUpgradeLevel() {
        return currentUpgrade;
    }
    private string GenerateUpgradeLine(LocalizedString name, AttributeModifier modifier) {
        if (modifier == null) {
            return "";
        }
        string output = name.GetLocalizedString();
        if (modifier.baseValue != 0f || modifier.diminishingReturnUp != 0f || modifier.flatUp != 0f) {
            output += " +" +(modifier.baseValue+modifier.diminishingReturnUp+modifier.flatUp);
        }
        if (modifier.multiplier != 1f) {
            output += " x" +modifier.multiplier;
        }
        return output + "\n";
    }
    public virtual string GetUpgradeText() {
        string line = GenerateUpgradeLine(damageText, upgrades[currentUpgrade].damageModifier);
        line += GenerateUpgradeLine(countText, upgrades[currentUpgrade].countModifier);
        line += GenerateUpgradeLine(cooldownText, upgrades[currentUpgrade].cooldownModifier);
        line += GenerateUpgradeLine(penetrationText, upgrades[currentUpgrade].penetrationModifier);
        line += GenerateUpgradeLine(radiusText, upgrades[currentUpgrade].radiusModifier);
        line += GenerateUpgradeLine(speedText, upgrades[currentUpgrade].speedModifier);
        return line;
    }
    public virtual int GetUpgradeTotal() {
        return upgrades.Count;
    }
    public virtual bool CanUpgrade() {
        return currentUpgrade < upgrades.Count;
    }
    public virtual void Upgrade() {
        WeaponUpgrade upgrade = upgrades[currentUpgrade++];
        projectileCount.AddModifier(upgrade.countModifier);
        damage.AddModifier(upgrade.damageModifier);
        cooldown.AddModifier(upgrade.cooldownModifier);
        penetration.AddModifier(upgrade.penetrationModifier);
        radius.AddModifier(upgrade.radiusModifier);
        speed.AddModifier(upgrade.speedModifier);
        weaponSetChanged?.Invoke(weapons);
    }
    public Attribute projectileCount;
    public Attribute damage;
    public Attribute cooldown;
    public Attribute penetration;
    public Attribute radius;
    public Attribute speed;
    protected PlayerCharacter player;
    protected virtual void Awake() {
        weapons.Add(this);
        weaponSetChanged?.Invoke(weapons);
        Pauser.pauseChanged += OnPauseChanged;
    }
    protected virtual void OnEnable() {
        player = GetComponentInParent<PlayerCharacter>();
        StartCoroutine(FireRoutine());
    }
    protected virtual void OnDisable() {
        StopAllCoroutines();
    }
    protected virtual void OnDestroy() {
        weapons.Remove(this);
        weaponSetChanged?.Invoke(weapons);
        Pauser.pauseChanged -= OnPauseChanged;
    }
    protected virtual void OnPauseChanged(bool paused) {
    }
    public virtual void Start() {
        projectileCount.SetParentAttribute(player.projectileCount);
        damage.SetParentAttribute(player.damage);
        cooldown.SetParentAttribute(player.projectileCooldown);
        radius.SetParentAttribute(player.projectileRadius);
        penetration.SetParentAttribute(player.projectilePenetration);
        speed.SetParentAttribute(player.projectileSpeed);
    }
    public virtual IEnumerator FireRoutine() {
        while(Pauser.GetPaused()) {
            yield return null;
        }
        // Do things and don't break on inherited classes.
        yield break;
    }
    public virtual void SetUpProjectile(Projectile p) {
        p.damage = damage.GetValue();
        p.hitLimit = Mathf.CeilToInt(penetration.GetValue());
        p.radius = radius.GetValue();
        p.weaponCard = weaponCard;
    }
}
