using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Localization;

public class Weapon : MonoBehaviour {
    //public LocalizedString weaponName;
    [SerializeField]
    public WeaponCard weaponCard;
    [SerializeField]
    protected List<StatBlockModifier> upgrades;
    [SerializeField]
    public StatBlock stats;
    protected int currentUpgrade = 0;
    public virtual int GetUpgradeLevel() {
        return currentUpgrade;
    }
    public virtual string GetUpgradeText() {
        return weaponCard.localizedDescription.GetLocalizedString();
    }
    public virtual int GetUpgradeTotal() {
        return upgrades.Count;
    }
    public bool CanUpgrade() {
        return GetUpgradeLevel() < GetUpgradeTotal();
    }
    public virtual StatBlockModifier GetCurrentUpgradeStatChange() {
        return upgrades[currentUpgrade];
    }
    public virtual void Upgrade() {
        StatBlockModifier upgrade = upgrades[currentUpgrade++];
        upgrade.Apply(stats);
    }
    protected PlayerCharacter player;
    protected virtual void Awake() {
        player = GetComponentInParent<PlayerCharacter>();
        stats.SetParent(player.stats);
        Pauser.pauseChanged += OnPauseChanged;
    }
    protected virtual void OnEnable() {
        StartCoroutine(FireRoutine());
    }
    protected virtual void OnDisable() {
        for(int i=0;i<GetUpgradeLevel();i++) {
            upgrades[i].Revert(stats);
        }
        StopAllCoroutines();
    }
    protected virtual void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    protected virtual void OnPauseChanged(bool paused) {
    }
    public virtual void Start() {
    }
    public virtual IEnumerator FireRoutine() {
        while(Pauser.GetPaused()) {
            yield return null;
        }
        // Do things and don't break on inherited classes.
        yield break;
    }
    public virtual void SetUpProjectile(Projectile p) {
        p.damage = stats.damage.GetValue();
        p.hitLimit = Mathf.CeilToInt(stats.projectilePenetration.GetValue())+1;
        p.radius = stats.projectileRadius.GetValue();
        p.knockback = stats.knockback.GetValue();
        p.weaponCard = weaponCard;
    }
}
