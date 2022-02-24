using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyCharacter : Character {
    private bool stunned = false;
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
    }
    public override void FixedUpdate() {
        base.FixedUpdate();
        if (!stunned) {
            wishDir = WorldGrid.instance.GetPathTowardsPlayer(position);
        } else {
            wishDir = Vector3.zero;
        }
    }
    public override void Reset() {
        base.Reset();
        stunned = false;
        phased = false;
    }
}
