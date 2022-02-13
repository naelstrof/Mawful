using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class VoreTail : MonoBehaviour {
    private class VoreBump {
        public VoreBump(float st, float dur) {
            startTime = st;
            duration = dur;
        }
        public float startTime;
        public float duration;
    }
    private Animator tailAnimator;
    [SerializeField]
    private Transform tailMouth;
    [SerializeField]
    private List<string> tailBlends;
    private List<int> tailBlendIDs;
    [SerializeField]
    private SkinnedMeshRenderer tailRenderer;
    private Character character;
    private HashSet<Character> readyToVore;
    [SerializeField]
    private AnimationCurve voreBumpCurve;
    private List<VoreBump> voreBumps;
    private const float tailBlendDistance = 0.5f;
    void VaccumDefeated(WorldGrid.CollisionGridElement element) {
        foreach(Character character in element.charactersInElement) {
            if (character.health.GetHealth() <= 0f) {
                Vector3 dir = tailMouth.position - character.position;
                character.position += dir * 0.2f;
                character.lastPosition = Vector3.Lerp(character.lastPosition, character.position, 0.8f);
                if (dir.magnitude < 0.5f) {
                    Vore(character);
                }
            }
        }
    }
    void Awake() {
        readyToVore = new HashSet<Character>();
        voreBumps = new List<VoreBump>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    void FinishVore() {
        foreach(Character other in readyToVore) {
            other.Reset();
            other.gameObject.SetActive(false);
            voreBumps.Add(new VoreBump(Time.time,UnityEngine.Random.Range(1.5f, 4f)));
        }
        readyToVore.Clear();
        tailAnimator.ResetTrigger("Chomp");
    }
    void Vore(Character other) {
        readyToVore.Add(other);
        tailAnimator.SetTrigger("Chomp");
    }
    void Start() {
        tailAnimator = GetComponent<Animator>();
        tailBlendIDs = new List<int>();
        for (int i=0;i<tailBlends.Count;i++) {
            tailBlendIDs.Add(tailRenderer.sharedMesh.GetBlendShapeIndex(tailBlends[i]));
        }
        character = GetComponentInParent<Character>();
    }
    void Update() {
        for(int i=0;i<tailBlendIDs.Count;i++) {
            float blendAmount = 0f;
            for(int j=voreBumps.Count-1;j>=0;j--) {
                float offset = tailBlendDistance * (float)i;
                float t = (Time.time-(voreBumps[j].startTime+offset))/voreBumps[j].duration;
                float sample = voreBumpCurve.Evaluate(t);
                blendAmount += sample;
                if (t>1f && i == tailBlendIDs.Count-1) {
                    // TODO: trigger some belly stuff here
                    Leveler.AddXP(1);
                    voreBumps.RemoveAt(j);
                }
            }
            tailRenderer.SetBlendShapeWeight(tailBlendIDs[i], Mathf.Min(blendAmount*100f, 250f));
        }
    }
    void FixedUpdate() {
        Vector3 position = tailMouth.position;
        int collisionX = Mathf.RoundToInt(position.x/WorldGrid.collisionGridSize);
        int collisionY = Mathf.RoundToInt(position.z/WorldGrid.collisionGridSize);
        int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(position.x/WorldGrid.collisionGridSize,1f))*2-1);
        int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(position.z/WorldGrid.collisionGridSize,1f))*2-1);
        VaccumDefeated(WorldGrid.GetCollisionGridElement(collisionX, collisionY));
        VaccumDefeated(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY));
        VaccumDefeated(WorldGrid.GetCollisionGridElement(collisionX, collisionY+collisionYOffset));
        VaccumDefeated(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset));
    }
}
