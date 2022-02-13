using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(PlayerInput))]
public class PlayerCharacter : Character {
    public static PlayerCharacter player;
    public static Vector3 playerPosition => player.position;
    private PlayerInput playerInput;
    [HideInInspector]
    public Vector3 fireDir = Vector3.forward;
    public Attribute projectileCooldown;
    public Attribute projectileCount;
    public Attribute projectilePenetration;
    public Attribute projectileRadius;
    public Attribute projectileSpeed;
    public Attribute luck;
    public override void Awake() {
        base.Awake();
        player = this;
    }
    void Start() {
        playerInput = GetComponent<PlayerInput>();
    }
    void Update() {
        if (velocity.sqrMagnitude > 0.0001f) {
            transform.rotation = Quaternion.LookRotation(velocity.normalized, Vector3.up);
        }
    }
    public override void Die() {
        base.Die();
        gameObject.SetActive(false);
    }
    public override void FixedUpdate() {
        base.FixedUpdate();
        Vector2 dir = playerInput.actions["Move"].ReadValue<Vector2>();
        Vector3 flatDir = CameraFollower.GetInputRotation() * new Vector3(dir.x, 0f, dir.y);
        if (flatDir.sqrMagnitude > 0.0001f) {
            fireDir = flatDir.normalized;
        }
        wishDir = flatDir;
    }
}
