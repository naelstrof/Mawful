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
            while(Pauser.GetPaused()) {
                yield return null;
            }
            yield return timeToWait;
            float arc = projectileCount.GetValue()*5f;
            Quaternion rot = Quaternion.AngleAxis(-arc*0.5f, Vector3.up);
            for (int i=0;i<projectileCount.GetValue();i++) {
                Vector3 updir = new Vector3(-1,0,1).normalized;
                float angle = Vector3.Angle(player.fireDir, updir);
                Vector3 aimDir = Vector3.RotateTowards(player.fireDir, updir, angle*0.8f*Mathf.Deg2Rad, 10f);

                Axe axe;
                if (!AxePool.StaticTryInstantiate(out axe)) { continue; }
                SetUpProjectile(axe);
                axe.SetPositionAndVelocity(player.interpolatedPosition, rot*aimDir*speed.GetValue());
                rot *= Quaternion.AngleAxis(5f, Vector3.up);
                yield return perProjectileWait;
            }
        }
    }
}
