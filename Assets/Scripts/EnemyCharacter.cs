using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyCharacter : Character {
    private bool stunned = false;
    public override void LateUpdate() {
        base.LateUpdate();
        if (velocity.sqrMagnitude > 0.001f) {
            transform.rotation = Quaternion.LookRotation(velocity.normalized, Vector3.up);
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
            wishDir = WorldGrid.GetPathTowardsPlayer(position);
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
