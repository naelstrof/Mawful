using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlayerDisplayController : MonoBehaviour {
    private Character character;
    private Animator animator;
    public delegate void StateTriggeredAction(string name);
    public event StateTriggeredAction eventTriggered;
    void Start() {
        character = GetComponentInParent<Character>();
        animator = GetComponent<Animator>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
        animator.enabled = !paused;
    }
    void Update() {
        animator.SetFloat("Speed", character.velocity.magnitude*14f);
    }
    void InvokeTrigger(string name) {
        eventTriggered?.Invoke(name);
    }
}
