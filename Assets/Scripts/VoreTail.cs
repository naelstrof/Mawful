using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class VoreTail : MonoBehaviour {
    public static VoreTail instance;
    public delegate void VoreBumpAddedAction(VoreBump bumps);
    public event VoreBumpAddedAction bumpAdded;
    public class VoreBump {
        public VoreBump(float st, float dur, float xp) {
            startTime = st;
            duration = dur;
            this.xp = xp;
        }
        public float xp;
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
    private Character player;
    private HashSet<Character> vaccuming;
    private HashSet<Character> readyToVore;
    [SerializeField]
    private AnimationCurve voreBumpCurve;
    private List<VoreBump> voreBumps;
    public VisualEffect chompEffect;
    private const float tailBlendDistance = 0.5f;
    void VaccumDefeated(WorldGrid.CollisionGridElement element) {
        foreach(Character character in element.charactersInElement) {
            if (character.health.GetHealth() <= 0f && character is EnemyCharacter) {
                if (Vector3.Distance(tailMouth.position, character.position) < 1.25f+character.radius) {
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
    void Awake() {
        instance = this;
        readyToVore = new HashSet<Character>();
        vaccuming = new HashSet<Character>();
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
            voreBumps.Add(new VoreBump(Time.time,UnityEngine.Random.Range(1f, 3f), Mathf.Lerp(other.health.GetValue(), 1f, 0.5f)));
            bumpAdded(voreBumps[voreBumps.Count-1]);
            vaccuming.Remove(other);
        }
        readyToVore.Clear();
        tailAnimator.ResetTrigger("Chomp");
        chompEffect.Play();
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
        player = GetComponentInParent<Character>();
    }
    void Update() {
        for(int i=0;i<tailBlendIDs.Count;i++) {
            float blendAmount = 0f;
            for(int j=voreBumps.Count-1;j>=0;j--) {
                float offset = tailBlendDistance * (float)i;
                float t = (Time.time-(voreBumps[j].startTime+offset))/voreBumps[j].duration;
                float sample = voreBumpCurve.Evaluate(t);
                blendAmount = Mathf.Lerp(blendAmount, 2.5f, sample/2.5f);
                if (t>1f && i == tailBlendIDs.Count-1) {
                    // TODO: trigger some belly stuff here
                    Leveler.AddXP(voreBumps[j].xp);
                    voreBumps.RemoveAt(j);
                }
            }
            tailRenderer.SetBlendShapeWeight(tailBlendIDs[i], Mathf.Min(blendAmount*100f, 250f));
        }
        Vector3 tailTarget = tailMouth.transform.position+tailMouth.transform.up*0.4f;
        foreach(Character character in vaccuming) {
            float dist = Vector3.Distance(character.transform.position, tailTarget);
            character.transform.position = Vector3.MoveTowards(character.transform.position, tailTarget, Time.deltaTime*8f + dist*Time.deltaTime*2f);
            character.transform.rotation = Quaternion.RotateTowards(character.transform.rotation, tailMouth.rotation, Time.deltaTime*360f*4f);
            if (Vector3.Distance(character.transform.position, tailTarget) < 0.1f) {
                Vore(character);
            }
        }
    }
    void FixedUpdate() {
        Vector3 position = WorldGrid.instance.worldBounds.ClosestPoint(tailMouth.position);
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
