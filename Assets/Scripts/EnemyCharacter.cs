using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class EnemyCharacter : Character {
    [HideInInspector]
    public AudioSource audioSource;
    private bool stunned = false;
    [SerializeField]
    private AudioPack dieSound;
    public override void Awake() {
        base.Awake();
        audioSource = GetComponent<AudioSource>();
    }
    public override void LateUpdate() {
        base.LateUpdate();
        if (health.GetHealth()>0f && velocity.sqrMagnitude > 0.0001f) {
            transform.rotation = Quaternion.RotateTowards(transform.rotation,Quaternion.LookRotation(velocity.normalized, Vector3.up), Time.deltaTime*360f);
        }
    }
    public override void Die() {
        base.Die();
        stunned = true;
        phased = true;
        dieSound?.PlayOneShot(audioSource);
    }
    public override void BeHit(DamageInstance instance) {
        Score.AddDamage(instance.card, Mathf.Min(health.GetHealth(), instance.damage));
        base.BeHit(instance);
    }
    public override void FixedUpdate() {
        base.FixedUpdate();
        if (!stunned) {
            wishDir = WorldGrid.instance.GetPathTowardsPlayer(position);
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
