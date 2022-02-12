using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Weapon : MonoBehaviour {
    public Attribute projectileCount;
    public Attribute damage;
    public Attribute cooldown;
    public Attribute penetration;
    public Attribute radius;
    public Attribute speed;
    protected PlayerCharacter character;
    public virtual void Start() {
        character = GetComponentInParent<PlayerCharacter>();
        projectileCount.SetParentAttribute(character.projectileCount);
        damage.SetParentAttribute(character.damage);
        cooldown.SetParentAttribute(character.projectileCooldown);
        radius.SetParentAttribute(character.projectileRadius);
        penetration.SetParentAttribute(character.projectilePenetration);
        speed.SetParentAttribute(character.projectileSpeed);
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
