using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Axes : Weapon {
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    private AudioSource audioSource;
    [SerializeField]
    private AudioPack pack;
    public override void Start() {
        stats.projectileCooldown.changed += OnCooldownChanged;
        OnCooldownChanged(stats.projectileCooldown.GetValue());
        perProjectileWait = new WaitForSeconds(0.10f);
        audioSource = GetComponentInParent<AudioSource>();
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
            float arc = stats.projectileCount.GetValue()*5f;
            Quaternion rot = Quaternion.AngleAxis(-arc*0.5f, Vector3.up);
            for (int i=0;i<stats.projectileCount.GetValue();i++) {
                Vector3 updir = Vector3.ProjectOnPlane(CameraFollower.GetCamera().transform.forward, Vector3.up).normalized;
                float angle = Vector3.Angle(player.fireDir, updir);
                Vector3 aimDir;
                if (angle < 140f) {
                    aimDir = Vector3.RotateTowards(player.fireDir, updir, angle*0.8f*Mathf.Deg2Rad, 10f);
                } else {
                    aimDir = updir;
                }

                Axe axe;
                if (!AxePool.StaticTryInstantiate(out axe)) { continue; }
                SetUpProjectile(axe);
                axe.gravityDir = -updir*9.81f;
                axe.SetPositionAndVelocity(player.interpolatedPosition, rot*aimDir*stats.projectileSpeed.GetValue());
                pack.PlayOneShot(audioSource);
                rot *= Quaternion.AngleAxis(5f, Vector3.up);
                yield return perProjectileWait;
            }
        }
    }
}
