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
    private float lastHitTime;
    private Vector3 lookSmooth;
    public override void BeHit(DamageInstance instance) {
        // 0.3 second damage boost
        if ((Time.time - lastHitTime > 0.5f || frozen) && !invulnerable) {
            base.BeHit(instance);
            lastHitTime = Time.time;
        }
    }
    protected override void HitResponse(Character other) {
        if (other.stats.health.GetValue() > 0f && other.stats.damage.GetValue() > 0f) {
            BeHit(new DamageInstance(null, other.stats.damage.GetValue(), Vector3.zero));
        }
    }
    // Do nothing, player hitstun suuucks
    public override void HitStun(float duration, float vibrationMag) {
    }
    public override void Awake() {
        base.Awake();
        player = this;
    }
    protected override void Start() {
        lastHitTime = Time.time;
        playerInput = GetComponent<PlayerInput>();
        playerInput.actions["Pause"].started += OnPausePerformed;
        playerInput.actions["GrabLook"].started += OnGrabLookStarted;
        playerInput.actions["GrabLook"].canceled += OnGrabLookFinished;
        WorldGrid.instance.worldPathReady += OnWorldPathReady;
        base.Start();
    }
    protected override void OnDestroy() {
        playerInput.actions["Pause"].started -= OnPausePerformed;
        playerInput.actions["GrabLook"].started -= OnGrabLookStarted;
        playerInput.actions["GrabLook"].canceled -= OnGrabLookFinished;
        Score.TriggerEndTime();
        base.OnDestroy();
    }
    void OnPausePerformed(InputAction.CallbackContext ctx) {
        MainMenuShower.ToggleShow();
    }
    void OnGrabLookStarted(InputAction.CallbackContext ctx) {
        if (Pauser.GetPaused() || stats.health.GetHealth() <= 0f) {
            return;
        }
        Cursor.lockState = CursorLockMode.Locked;
        Cursor.visible = false;
    }
    void OnGrabLookFinished(InputAction.CallbackContext ctx) {
        Cursor.lockState = CursorLockMode.None;
        Cursor.visible = true;
    }
    void OnWorldPathReady() {
        SetPositionAndVelocity(WorldGrid.instance.GetPathableGridElement().worldPosition, Vector3.zero);
        Score.ClearScore();
    }
    void Update() {
        // Only look if we're on gamepad, or if the player has clicked the mouse in
        if (Cursor.lockState == CursorLockMode.Locked || playerInput.currentControlScheme != "Keyboard&Mouse") {
            Vector2 look = playerInput.actions["Look"].ReadValue<Vector2>();
            if (playerInput.currentControlScheme != "Keyboard&Mouse") {
                look *= Time.deltaTime*100f;
            } else {
                look *= 0.08f;
            }
            CameraFollower.AddDeflection(look);
        }

        float zoom = playerInput.actions["Zoom"].ReadValue<float>();
        if (playerInput.currentControlScheme != "Keyboard&Mouse") {
            zoom *= Time.deltaTime;
        } else {
            zoom *= 0.1f;
        }
        CameraFollower.AddZoom(zoom);
        if (frozen) {
            return;
        }
        lookSmooth = Vector3.RotateTowards(lookSmooth, fireDir, Mathf.PI*8f*Time.deltaTime, 10f);
        transform.rotation = Quaternion.LookRotation(lookSmooth, Vector3.up);
    }
    public override void Die() {
        base.Die();
        enabled = false;
        Score.TriggerEndTime();
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
    protected override void OnPauseChanged(bool paused) {
        enabled = !paused && !beingVored && stats.health.GetHealth()>0f;
        if (paused) {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
    }
}
