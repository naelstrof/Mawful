using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Garlic : Weapon {
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    [SerializeField]
    private Transform garlicVisuals;
    public override void Start() {
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
            yield return timeToWait;
            for (int i=0;i<projectileCount.GetValue();i++) {
                foreach(Character character in Character.characters) {
                    if (character == player) {
                        continue;
                    }
                    if (Vector3.Distance(character.position, player.position) <= radius.GetValue()+player.radius+character.radius) {
                        float knockbackAmount = 0.05f;
                        character.BeHit(new Character.DamageInstance(damage.GetValue(), (character.position-player.position).normalized*knockbackAmount));
                    }
                }
                yield return perProjectileWait;
            }
        }
    }
}
