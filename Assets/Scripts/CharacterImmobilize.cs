using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterImmobilize : PooledItem {
    private Character targetCharacter;
    private Vector3 targetPosition;
    void OnEnable() {
        targetCharacter = GetComponent<Character>();
        targetCharacter.SetFreeze(true);
        targetPosition = targetCharacter.position;
        targetCharacter.positionSet += OnPositionSet;
        targetCharacter.startedVore += OnVore;
    }
    void OnVore() {
        targetCharacter.SetFreeze(false);
        enabled = false;
    }
    void OnPositionSet(Vector3 newPosition) {
        targetPosition = newPosition;
    }
    void FixedUpdate() {
        targetCharacter.position = targetPosition;
    }
    void OnDisable() {
        targetCharacter.positionSet -= OnPositionSet;
    }
    void OnDestroy() {
        targetCharacter.startedVore -= OnVore;
    }
    public override void Reset() {
        base.Reset();
        enabled = true;
    }
}
