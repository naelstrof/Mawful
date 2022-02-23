using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CharacterImmobilize : MonoBehaviour {
    private Character targetCharacter;
    private Vector3 targetPosition;
    void OnEnable() {
        targetCharacter = GetComponent<Character>();
        targetPosition = targetCharacter.position;
        targetCharacter.positionSet += OnPositionSet;
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
}
