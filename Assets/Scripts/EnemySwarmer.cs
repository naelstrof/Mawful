using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class EnemySwarmer : Character {
    private bool stunned = false;
    public int pathChoice;
    public override void LateUpdate() {
        base.LateUpdate();
        if (stats.health.GetHealth()>0f && velocity.sqrMagnitude > 0.0001f) {
            transform.rotation = Quaternion.RotateTowards(transform.rotation,Quaternion.LookRotation(velocity.normalized, Vector3.up), Time.deltaTime*360f);
        }
    }
    public override void Die() {
        base.Die();
        stunned = true;
        phased = true;
    }
    public override void BeHit(DamageInstance instance) {
        Score.AddDamage(instance.card, Mathf.Min(stats.health.GetHealth(), instance.damage));
        base.BeHit(instance);
    }
    public override void FixedUpdate() {
        base.FixedUpdate();
        if (!stunned) {
            wishDir = WorldGrid.instance.GetPath(position, pathChoice);
            if (wishDir.magnitude == 0f) {
                Reset();
                gameObject.SetActive(false);
            }
        } else {
            wishDir = Vector3.zero;
        }
    }
    public override void Reset(bool recurse = true) {
        base.Reset(recurse);
        stunned = false;
        phased = false;
    }
}
