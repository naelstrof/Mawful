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
    private float startTime;
    private Character character;
    public BakedAnimation GetScoreAnimation() {
        return struggles[UnityEngine.Random.Range(0,struggles.Count)];
    }
    public void SetAnimation(BakedAnimation animation) {
        currentAnimation = animation;
        startTime = Time.time;
    }
    void Start() {
        startTime = UnityEngine.Random.Range(0f,10f);
        filter = GetComponent<MeshFilter>();
        defaultMaterial = GetComponent<Renderer>().sharedMaterial;
        character = GetComponentInParent<Character>();
        if (character != null) {
            character.health.depleted += OnDie;
            character.startedVore += OnVoreStart;
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
    void OnVoreStart() {
        if (defaultMaterial != null) {
            GetComponent<Renderer>().sharedMaterial = defaultMaterial;
        }
        currentAnimation = struggles[UnityEngine.Random.Range(0,struggles.Count)];
        startTime = Time.time;
    }
    void OnDie() {
        GetComponent<Renderer>().sharedMaterial = goopMaterial;
        currentAnimation = stunned;
        startTime = Time.time;
    }
    void Update() {
        float fFrames = (float)(currentAnimation.frames.Count-1);
        if (currentAnimation.loop) {
            int frame = Mathf.RoundToInt(Mathf.Repeat(Time.time - startTime, fFrames/currentAnimation.framesPerSecond)*currentAnimation.framesPerSecond);
            filter.sharedMesh = currentAnimation.frames[frame];
        } else {
            int frame = Mathf.RoundToInt(Mathf.Min(Time.time - startTime, fFrames/currentAnimation.framesPerSecond)*currentAnimation.framesPerSecond);
            filter.sharedMesh = currentAnimation.frames[frame];
        }
    }
    public override void Reset() {
        base.Reset();
        if (defaultMaterial != null) {
            GetComponent<Renderer>().sharedMaterial = defaultMaterial;
        }
        currentAnimation = walk;
        startTime = Time.time;
    }
}
