using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class VoreCock : Vore {
    private Animator cockAnimator;
    [SerializeField]
    private string triggerName;
    [SerializeField]
    private string listenName;
    [SerializeField]
    private AttributeModifier damageModifier;
    private const float tailBlendDistance = 0.5f;
    protected override void Awake() {
        base.Awake();
        cockAnimator = GetComponentInParent<Animator>();
        GetComponentInParent<PlayerDisplayController>().eventTriggered += OnEventTriggered;
    }
    void OnEventTriggered(string name) {
        if (name == listenName) {
            FinishVore();
        }
    }
    protected override void Digest(Character character) {
        base.Digest(character);
        GetComponentInParent<PlayerCharacter>().damage.AddModifier(damageModifier);
    }
    protected override void StartVore(Character other) {
        readyToVore.Add(other);
        cockAnimator.SetTrigger(triggerName);
    }
}
