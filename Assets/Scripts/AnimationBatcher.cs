using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class AnimationBatcher : PooledItem {
    private BakedAnimation currentAnimation;
    [SerializeField]
    private BakedAnimation walk;
    [SerializeField]
    private BakedAnimation stunned;
    [SerializeField]
    private List<BakedAnimation> struggles;
    private MeshFilter filter;
    private Material defaultMaterial;
    [SerializeField]
    private Material goopMaterial;
    private float timer;
    private Character character;
    public BakedAnimation GetScoreAnimation() {
        return struggles[UnityEngine.Random.Range(0,struggles.Count)];
    }
    public void SetAnimation(BakedAnimation animation) {
        currentAnimation = animation;
        timer = 0f;
    }
    void Start() {
        filter = GetComponent<MeshFilter>();
        defaultMaterial = GetComponent<Renderer>().sharedMaterial;
        character = GetComponentInParent<Character>();
        if (character != null) {
            character.health.depleted += OnDie;
            character.startedVore += OnVoreStart;
            character.stunChanged += OnStunChanged;
            currentAnimation = walk;
        }
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    void OnStunChanged(bool stunned) {
        enabled = !stunned;
    }
    void OnVoreStart() {
        if (defaultMaterial != null) {
            GetComponent<Renderer>().sharedMaterial = defaultMaterial;
        }
        currentAnimation = struggles[UnityEngine.Random.Range(0,struggles.Count)];
        timer = 0f;
    }
    void OnDie() {
        GetComponent<Renderer>().sharedMaterial = goopMaterial;
        currentAnimation = stunned;
        timer = 0f;
    }
    void Update() {
        if (currentAnimation == null) {
            return;
        }
        timer += Time.deltaTime;
        float fFrames = (float)(currentAnimation.frames.Count-1);
        if (currentAnimation.loop) {
            int frame = Mathf.RoundToInt(Mathf.Repeat(timer*currentAnimation.framesPerSecond, fFrames));
            filter.sharedMesh = currentAnimation.frames[frame];
        } else {
            int frame = Mathf.RoundToInt(Mathf.Min(timer*currentAnimation.framesPerSecond, fFrames));
            filter.sharedMesh = currentAnimation.frames[frame];
        }
    }
    public override void Reset(bool recurse = true) {
        base.Reset(recurse);
        if (defaultMaterial != null) {
            GetComponent<Renderer>().sharedMaterial = defaultMaterial;
        }
        currentAnimation = walk;
        timer = 0f;
    }
}
