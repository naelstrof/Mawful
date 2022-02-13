using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Daggers : Weapon {
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
    public override IEnumerator FireRoutine() {
        while(isActiveAndEnabled) {
            yield return timeToWait;
            for (int i=0;i<projectileCount.GetValue();i++) {
                Projectile magicBolt;
                if (!ProjectilePool.TryInstantiate(out magicBolt)) { continue; }
                SetUpProjectile(magicBolt);
                magicBolt.SetPositionAndVelocity(player.interpolatedPosition, player.fireDir*speed.GetValue());
                yield return perProjectileWait;
            }
        }
    }
}
