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
    private float lastHitTime;
    private Vector3 lookSmooth;
    public override void BeHit(DamageInstance instance) {
        // 0.3 second damage boost
        if (Time.time - lastHitTime > 0.33f) {
            base.BeHit(instance);
            lastHitTime = Time.time;
        }
    }
    public override void Awake() {
        base.Awake();
        player = this;
    }
    void Start() {
        lastHitTime = Time.time;
        playerInput = GetComponent<PlayerInput>();
        WorldGrid.instance.worldPathReady += OnWorldPathReady;
    }
    void OnWorldPathReady() {
        SetPositionAndVelocity(WorldGrid.instance.GetPathableGridElement().worldPosition, Vector3.zero);
    }
    void Update() {
        lookSmooth = Vector3.RotateTowards(lookSmooth, fireDir, Mathf.PI*8f*Time.deltaTime, 10f);
        transform.rotation = Quaternion.LookRotation(lookSmooth, Vector3.up);
    }
    public override void Die() {
        base.Die();
        enabled = false;
        //gameObject.SetActive(false);
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
