using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerDisplayController : MonoBehaviour {
    private Character character;
    private Animator animator;
    void Start() {
        character = GetComponentInParent<Character>();
        animator = GetComponent<Animator>();
    }
    void Update() {
        animator.SetFloat("Speed", character.velocity.magnitude*10f);
    }
}
