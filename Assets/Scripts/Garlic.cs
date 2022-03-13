using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class Garlic : Weapon {
    [SerializeField]
    private AudioPack hitSound;
    private AudioSource source;
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    [SerializeField]
    private Transform garlicVisuals;
    public override void Start() {
        source = GetComponent<AudioSource>();
        cooldown.changed += OnCooldownChanged;
        radius.changed += OnRadiusChanged;
        OnCooldownChanged(cooldown.GetValue());
        OnRadiusChanged(radius.GetValue());
        perProjectileWait = new WaitForSeconds(0.05f);
        base.Start();
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = new WaitForSeconds(1f/newCooldown);
    }
    void OnRadiusChanged(float newRadius) {
        garlicVisuals.transform.localScale = Vector3.Scale(Vector3.one * newRadius, new Vector3(2f,0.1f,2f));
    }
    public override IEnumerator FireRoutine() {
        while(isActiveAndEnabled) {
            while(Pauser.GetPaused()) {
                yield return null;
            }
            yield return timeToWait;
            bool hit = false;
            for (int i=0;i<projectileCount.GetValue();i++) {
                foreach(Character character in Character.characters) {
                    if (character == player) {
                        continue;
                    }
                    if (Vector3.Distance(character.position, player.position) <= radius.GetValue()+player.radius+character.radius && character.health.GetHealth() > 0f) {
                        float knockbackAmount = 0.001f;
                        character.BeHit(new Character.DamageInstance(weaponCard, damage.GetValue(), (character.position-player.position).normalized*knockbackAmount));
                        hit = true;
                    }
                }
                yield return perProjectileWait;
            }
            if (hit) {
                hitSound.PlayOneShot(source);
            }
        }
    }
}
