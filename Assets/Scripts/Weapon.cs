using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;

public class Weapon : MonoBehaviour {
    public LocalizedString weaponName;
    public static HashSet<Weapon> weapons = new HashSet<Weapon>();
    [System.Serializable]
    public class WeaponUpgrade {
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
    }
    public Attribute projectileCount;
    public Attribute damage;
    public Attribute cooldown;
    public Attribute penetration;
    public Attribute radius;
    public Attribute speed;
    protected PlayerCharacter player;
    void Awake() {
        weapons.Add(this);
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        weapons.Remove(this);
        Pauser.pauseChanged -= OnPauseChanged;
    }
    protected virtual void OnPauseChanged(bool paused) {
        enabled = !paused;
        if (!paused && isActiveAndEnabled) {
            StopAllCoroutines();
            StartCoroutine(FireRoutine());
        }
    }
    public virtual void Start() {
        player = GetComponentInParent<PlayerCharacter>();
        projectileCount.SetParentAttribute(player.projectileCount);
        damage.SetParentAttribute(player.damage);
        cooldown.SetParentAttribute(player.projectileCooldown);
        radius.SetParentAttribute(player.projectileRadius);
        penetration.SetParentAttribute(player.projectilePenetration);
        speed.SetParentAttribute(player.projectileSpeed);
        StartCoroutine(FireRoutine());
    }
    public virtual IEnumerator FireRoutine() {
        yield break;
    }
    public virtual void SetUpProjectile(Projectile p) {
        p.damage = damage.GetValue();
        p.hitLimit = Mathf.CeilToInt(penetration.GetValue());
        p.radius = radius.GetValue();
    }
}
