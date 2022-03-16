using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class MagicWand : Weapon {
    private AudioSource source;
    [SerializeField]
    private AudioPack wandFire;
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    public override void Start() {
        source = GetComponent<AudioSource>();
        stats.projectileCooldown.changed += OnCooldownChanged;
        OnCooldownChanged(stats.projectileCooldown.GetValue());
        base.Start();
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = new WaitForSeconds(1f/newCooldown);
        perProjectileWait = new WaitForSeconds(0.1f*(1f/newCooldown));
    }
    Character AquireTarget() {
        float closestDist = float.MaxValue;
        Character target = null;
        foreach(Character character in Character.characters) {
            if (!(character is EnemyCharacter) || character.stats.health.GetHealth() <= 0f) {
                continue;
            }
            float dist = Vector3.Distance(character.position, player.position);
            if (dist < closestDist) {
                target = character;
                closestDist = dist;
            }
        }
        return target;
    }
    public override IEnumerator FireRoutine() {
        while(isActiveAndEnabled) {
            while(Pauser.GetPaused()) {
                yield return null;
            }
            yield return timeToWait;
            Character target = AquireTarget();
            for (int i=0;i<stats.projectileCount.GetValue();i++) {
                Projectile magicBolt;
                if (!ProjectilePool.StaticTryInstantiate(out magicBolt)) { continue; }
                wandFire.PlayOneShot(source);
                SetUpProjectile(magicBolt);
                if (target != null) {
                    Vector3 dir = target.position - player.position;
                    magicBolt.SetPositionAndVelocity(player.interpolatedPosition, dir.normalized*stats.projectileSpeed.GetValue());
                } else {
                    magicBolt.SetPositionAndVelocity(player.interpolatedPosition, player.fireDir*stats.projectileSpeed.GetValue());
                }
                yield return perProjectileWait;
            }
        }
    }
}
