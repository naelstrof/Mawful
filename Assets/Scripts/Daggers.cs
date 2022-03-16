using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class Daggers : Weapon {
    private AudioSource source;
    [SerializeField]
    private AudioPack daggerFire;
    private WaitForSeconds timeToWait;
    public override void Start() {
        source = GetComponent<AudioSource>();
        stats.projectileCooldown.changed += OnCooldownChanged;
        OnCooldownChanged(stats.projectileCooldown.GetValue());
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
            for (int i=0;i<stats.projectileCount.GetValue();i++) {
                Projectile magicBolt;
                if (!ProjectilePool.StaticTryInstantiate(out magicBolt)) { continue; }
                daggerFire.PlayOneShot(source);
                SetUpProjectile(magicBolt);
                // Give it a little spread... Otherwise really hard to aim
                Vector3 firedir = Quaternion.AngleAxis(UnityEngine.Random.Range(-8f,8f), Vector3.up)*player.fireDir;
                magicBolt.SetPositionAndVelocity(player.interpolatedPosition, firedir*stats.projectileSpeed.GetValue());
            }
        }
    }
}
