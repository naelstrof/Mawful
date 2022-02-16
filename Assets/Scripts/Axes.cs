using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Axes : Weapon {
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
                Axe axe;
                if (!AxePool.StaticTryInstantiate(out axe)) { continue; }
                SetUpProjectile(axe);
                axe.SetPositionAndVelocity(player.interpolatedPosition, (Vector3.Scale(UnityEngine.Random.insideUnitSphere,new Vector3(0.4f,0,0.4f))+new Vector3(-0.5f,0f,0.5f))*speed.GetValue());
                yield return perProjectileWait;
            }
        }
    }
}
