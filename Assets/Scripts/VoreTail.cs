using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class VoreTail : Vore {
    private Animator tailAnimator;
    [SerializeField]
    private string triggerName;
    [SerializeField]
    private string listenName;
    [SerializeField]
    private Leveler leveler;
    private const float tailBlendDistance = 0.5f;
    protected override void Awake() {
        base.Awake();
        tailAnimator = GetComponentInParent<Animator>();
        GetComponent<PlayerDisplayController>().eventTriggered += OnEventTriggered;
    }
    void OnEventTriggered(string name) {
        if (name == listenName) {
            FinishVore();
        }
    }
    void VaccumDefeated(WorldGrid.CollisionGridElement element) {
        foreach(Character character in element.charactersInElement) {
            if (character.stats.health.GetHealth() <= 0f && !(character is PlayerCharacter)) {
                if (Vector3.Distance(mouth.position, character.position) < player.stats.grabRange.GetValue()+character.radius) {
                    if (!vaccuming.Contains(character)) {
                        character.StartVore();
                        // Disable all thinking, time to suck
                        character.enabled = false;
                        vaccuming.Add(character);
                    }
                }
            }
        }
    }
    protected override void Digest(Character character) {
        base.Digest(character);
        leveler.AddXP(Mathf.Lerp(character.stats.health.GetValue(), 1f, 0.5f));
    }
    protected override void StartVore(Character other) {
        readyToVore.Add(other);
        tailAnimator.SetTrigger(triggerName);
    }
    void FixedUpdate() {
        Vector3 position = WorldGrid.instance.worldBounds.ClosestPoint(mouth.position);
        int collisionX = Mathf.RoundToInt(position.x/WorldGrid.instance.collisionGridSize);
        int collisionY = Mathf.RoundToInt(position.z/WorldGrid.instance.collisionGridSize);
        int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(position.x/WorldGrid.instance.collisionGridSize,1f))*2-1);
        int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(position.z/WorldGrid.instance.collisionGridSize,1f))*2-1);
        VaccumDefeated(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY));
        VaccumDefeated(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY));
        VaccumDefeated(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY+collisionYOffset));
        VaccumDefeated(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset));
    }
}
