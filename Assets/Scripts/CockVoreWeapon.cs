using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;

public class CockVoreWeapon : Weapon {
    [SerializeField]
    [Range(1f,60f)]
    private float defaultCooldown = 30f;
    [SerializeField]
    private Vore voreTarget;
    float timeToWait;
    private float lastFireTime;
    private PlayerInput input;
    public Animator animator;
    public PlayerDisplayController controller;
    private int waiting;
    private Vector3 originalBarScale;
    private Color originalBarColor;
    [SerializeField]
    private Renderer bar;
    [SerializeField]
    private Renderer barContainer;
    private float timeout;
    private bool paused;
    [SerializeField]
    private StatBlockModifier playerBuff;
    [SerializeField]
    private float mergeChance = 0.05f;
    private bool attacking = false;
    [SerializeField]
    private AnimationCurve timingCurve;
    public override void Start() {
        stats.projectileCooldown.changed += OnCooldownChanged;
        OnCooldownChanged(stats.projectileCooldown.GetValue());
        base.Start();
        lastFireTime = Time.time - timeToWait;
        originalBarScale = bar.transform.localScale;
        originalBarColor = bar.material.color;
    }
    void OnStateTriggered(string name) {
        if (name == "DickAttacked") {
            attacking = true;
        }
    }
    protected override void OnEnable() {
        base.OnEnable();
        voreTarget.voreFinished += OnVoreComplete;
        controller.eventTriggered += OnStateTriggered;
        input = GetComponentInParent<PlayerInput>();
        input.actions["Ultimate"].performed += OnUltimateButton;
    }
    protected override void OnDisable() {
        base.OnDisable();
        voreTarget.voreFinished -= OnVoreComplete;
        controller.eventTriggered -= OnStateTriggered;
        input.actions["Ultimate"].performed -= OnUltimateButton;
        waiting = 0;
        attacking = false;
        player.SetFreeze(false);
        CameraFollower.SetGloryVore(false);
        animator.SetBool("DickAttack", false);
    }
    void OnVoreComplete(Character other) {
        if (stats.luck.Roll(mergeChance)) {
            playerBuff.Apply(player.stats);
        }
        waiting--;
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = (1f/newCooldown)*defaultCooldown+10f;
    }
    void OnUltimateButton(InputAction.CallbackContext context) {
        if (Time.time - lastFireTime > timeToWait) {
            lastFireTime = Time.time;
            StartCoroutine(UltimateRoutine());
        }
    }
    Character AquireTarget() {
        float closestDist = float.MaxValue;
        Character target = null;
        foreach(Character character in Character.characters) {
            if (character is PlayerCharacter || character.stats.health.GetHealth() <= 0f) {
                continue;
            }
            float dist = Vector3.Distance(character.position, player.position);
            if (dist < closestDist) {
                target = character;
                closestDist = dist;
            }
        }
        return target;
    }
    public IEnumerator UltimateRoutine() {
        animator.SetBool("DickAttack", true);
        while(!attacking) {
            yield return null;
        }
        float totalTime = 2f/stats.projectileCount.GetValue();
        for (int i=0;i<stats.projectileCount.GetValue();i++) {
            Character target = AquireTarget();
            if (target == null) {
                continue;
            }
            waiting++;
            CameraFollower.SetGloryVore(true);
            Score.AddDamage(weaponCard, target.stats.health.GetHealth());
            voreTarget.Vaccum(target);
            player.SetFreeze(true);
            float progress= (float)i/(stats.projectileCount.GetValue());
            yield return new WaitForSeconds(timingCurve.Evaluate(progress)*totalTime);
        }
        timeout = Time.time + 8f;
        while((waiting!=0 || !isActiveAndEnabled || paused) && Time.time < timeout) {
            yield return null;
        }
        attacking = false;
        player.SetFreeze(false);
        CameraFollower.SetGloryVore(false);
        animator.SetBool("DickAttack", false);
        foreach(Character character in Character.characters) {
            if (character is PlayerCharacter || character.stats.health.GetHealth() <= 0f) {
                continue;
            }
            // Blowback!!
            Vector3 dir = (character.position-player.position).normalized;
            character.position += dir*0.7f;
        }
    }
    public void Update() {
        float pastTime = Time.time-lastFireTime;
        float ratio = Mathf.Clamp01(pastTime/timeToWait);
        bar.transform.localScale = Vector3.Scale(originalBarScale, new Vector3(Mathf.Max(ratio,0.01f),1f,1f));
        bar.transform.localPosition = Vector3.left*(1f-ratio)*originalBarScale.x*0.5f;
        if (ratio == 1f) {
            bar.material.color = Color.Lerp(originalBarColor, Color.white, Mathf.Abs(Mathf.Sin(Time.time*6f)));
            barContainer.material.color = Color.black;
        } else {
            bar.material.color = Color.Lerp(originalBarColor, Color.clear, Mathf.Clamp01(Time.time-0.5f-lastFireTime));
            barContainer.material.color = Color.Lerp(Color.black, Color.clear, Mathf.Clamp01(Time.time-0.5f-lastFireTime));
        }
    }
    public override IEnumerator FireRoutine() {
        // Animator should trigger a "DickAttack" state trigger on the PlayerDisplayController, which we're listening for.
        /*animator.SetBool("DickAttack", true);
        waiting = true;
        while(waiting || !isActiveAndEnabled) {
            yield return null;
        }
        player.SetFreeze(false);
        animator.SetBool("DickAttack", false);*/
        yield break;
    }
    protected override void OnPauseChanged(bool paused) {
        this.paused = paused;
    }
}
