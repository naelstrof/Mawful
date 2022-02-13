using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MagicWand : Weapon {
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    public override void Start() {
        cooldown.changed += OnCooldownChanged;
        OnCooldownChanged(cooldown.GetValue());
        perProjectileWait = new WaitForSeconds(0.10f);
        base.Start();
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = new WaitForSeconds(1f/newCooldown);
    }
    Character AquireTarget() {
        float closestDist = float.MaxValue;
        Character target = null;
        foreach(Character character in Character.characters) {
            if (character is PlayerCharacter || character.health.GetHealth() <= 0f) {
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
            yield return timeToWait;
            Character target = AquireTarget();
            for (int i=0;i<projectileCount.GetValue();i++) {
                Projectile magicBolt;
                if (!ProjectilePool.TryInstantiate(out magicBolt)) { continue; }
                SetUpProjectile(magicBolt);
                if (target != null) {
                    Vector3 dir = target.position - player.position;
                    magicBolt.SetPositionAndVelocity(player.interpolatedPosition, dir.normalized*speed.GetValue());
                } else {
                    magicBolt.SetPositionAndVelocity(player.interpolatedPosition, player.fireDir*speed.GetValue());
                }
                yield return perProjectileWait;
            }
        }
    }
}
