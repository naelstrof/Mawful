using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
using UnityEngine.VFX;

public class AnalVoreWeapon : Weapon {
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
    private int attackCount = 0;
    private Vector3 originalBarScale;
    private Color originalBarColor;
    [SerializeField]
    private Renderer bar;
    [SerializeField]
    private Renderer barContainer;
    private float timeout;
    private bool paused;
    private bool doneAttacking = false;
    [SerializeField]
    private VisualEffect poofEffect;
    public override void Start() {
        cooldown.changed += OnCooldownChanged;
        OnCooldownChanged(cooldown.GetValue());
        base.Start();
        lastFireTime = Time.time - timeToWait;
        originalBarScale = bar.transform.localScale;
        originalBarColor = bar.material.color;
    }
    void OnPostSlam() {
        if (attackCount >= Mathf.RoundToInt(projectileCount.GetValue())) {
            doneAttacking = true;
        }
        foreach(Character character in Character.characters) {
            if (character is PlayerCharacter || character.health.GetHealth() <= 0f) {
                continue;
            }
            float blowbackDist = radius.GetValue()*3f;
            // Blowback!!
            Vector3 diff = (character.position-player.position);
            float dist = diff.magnitude;
            if (dist > blowbackDist) {
                continue;
            }
            float scale = (blowbackDist-Mathf.Min(dist,blowbackDist))/blowbackDist;
            Vector3 dir = diff.normalized;
            character.BeHit(new Character.DamageInstance(weaponCard, damage.GetValue()*scale, dir*0.2f*scale));
        }
        poofEffect.SetFloat("Radius", radius.GetValue());
        poofEffect.Play();
    }
    void OnStateTriggered(string name) {
        if (name == "AnalAttacked") {
            if (attackCount < projectileCount.GetValue()) {
                Character target = AquireTarget();
                attackCount++;
                if (target == null) {
                    OnPostSlam();
                    return;
                }
                // Hack, just keep things from slurping in too early-- let them stack up.
                animator.SetTrigger("ButtChomp");
                animator.SetBool("AnalVore", true);
                waiting++;
                Score.AddDamage(weaponCard, target.health.GetHealth());
                voreTarget.Vaccum(target);
                //player.SetFreeze(true);
                player.invulnerable = true;
                //float progress= (float)i/(projectileCount.GetValue());
                //yield return new WaitForSeconds((1f-progress)+0.8f);
            }
            OnPostSlam();
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
        attackCount = 0;
        doneAttacking = false;
        //player.SetFreeze(false);
        player.invulnerable = false;
        CameraFollower.SetGloryVore(false);
        animator.SetBool("AnalAttack", false);
    }
    void OnVoreComplete(Character other) {
        waiting--;
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = (1f/newCooldown)*defaultCooldown+3f;
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
            if (character is PlayerCharacter || character.health.GetHealth() <= 0f) {
                continue;
            }
            float dist = Vector3.Distance(character.position, player.position);
            if (dist < closestDist) {
                target = character;
                closestDist = dist;
            }
        }
        if (closestDist > radius.GetValue()) {
            return null;
        }
        return target;
    }
    public IEnumerator UltimateRoutine() {
        attackCount = 0;
        doneAttacking = false;
        foreach(AttributeModifier modifier in speed.modifiers) {
            player.speed.AddModifier(modifier);
        }
        animator.SetBool("AnalAttack", true);
        player.invulnerable = true;
        while(!doneAttacking) {
            yield return null;
        }
        CameraFollower.SetGloryVore(true);
        animator.SetBool("AnalAttack", false);
        player.SetFreeze(true);
        timeout = Time.time + 5f*projectileCount.GetValue();
        while((waiting!=0 || !isActiveAndEnabled || paused) && Time.time < timeout) {
            yield return null;
        }
        foreach(AttributeModifier modifier in speed.modifiers) {
            player.speed.RemoveModifier(modifier);
        }
        attackCount = 0;
        doneAttacking = false;
        player.SetFreeze(false);
        player.invulnerable = false;
        CameraFollower.SetGloryVore(false);
        animator.SetBool("AnalVore", false);
        OnPostSlam();
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
        yield break;
    }
    protected override void OnPauseChanged(bool paused) {
        this.paused = paused;
    }
}
