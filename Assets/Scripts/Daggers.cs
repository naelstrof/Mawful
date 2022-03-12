using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class Daggers : Weapon {
    private AudioSource source;
    [SerializeField]
    private AudioPack daggerFire;
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    public override void Start() {
        source = GetComponent<AudioSource>();
        cooldown.changed += OnCooldownChanged;
        OnCooldownChanged(cooldown.GetValue());
        base.Start();
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = new WaitForSeconds(1f/newCooldown);
        perProjectileWait = new WaitForSeconds(0.1f*(1f/newCooldown));
    }
    public override IEnumerator FireRoutine() {
        while(isActiveAndEnabled) {
            while(Pauser.GetPaused()) {
                yield return null;
            }
            yield return timeToWait;
            for (int i=0;i<projectileCount.GetValue();i++) {
                Projectile magicBolt;
                if (!ProjectilePool.StaticTryInstantiate(out magicBolt)) { continue; }
                daggerFire.PlayOneShot(source);
                SetUpProjectile(magicBolt);
                // Give it a little spread... Otherwise really hard to aim
                Vector3 firedir = Quaternion.AngleAxis(UnityEngine.Random.Range(-7f,7f), Vector3.up)*player.fireDir;
                magicBolt.SetPositionAndVelocity(player.interpolatedPosition, firedir*speed.GetValue());
                yield return perProjectileWait;
            }
        }
    }
}
