using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class AnimationBatcher : PooledItem {
    private BakedAnimation currentAnimation;
    [SerializeField]
    private float fps;
    [SerializeField]
    private BakedAnimation walk;
    [SerializeField]
    private BakedAnimation stunned;
    private MeshFilter filter;
    private float startTime;
    private Character character;
    void Start() {
        startTime = UnityEngine.Random.Range(0f,10f);
        filter = GetComponent<MeshFilter>();
        character = GetComponentInParent<Character>();
        character.health.depleted += OnDie;
        currentAnimation = walk;
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    void OnDie() {
        currentAnimation = stunned;
        startTime = Time.time;
    }
    void Update() {
        float fFrames = (float)(currentAnimation.frames.Count-1);
        if (currentAnimation.loop) {
            int frame = Mathf.RoundToInt(Mathf.Repeat(Time.time - startTime, fFrames/fps)*fps);
            filter.sharedMesh = currentAnimation.frames[frame];
        } else {
            int frame = Mathf.RoundToInt(Mathf.Min(Time.time - startTime, fFrames/fps)*fps);
            filter.sharedMesh = currentAnimation.frames[frame];
        }
    }
    public override void Reset() {
        base.Reset();
        currentAnimation = walk;
        startTime = Time.time;
    }
}
