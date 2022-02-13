using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Leveler : MonoBehaviour {
    public delegate void LevelUpAction();
    public event LevelUpAction levelUp;
    public static Leveler instance;
    [SerializeField]
    private string targetBlendshape;
    [SerializeField]
    private SkinnedMeshRenderer targetRenderer;
    private float currentXP = 0;
    private float neededXP = 3;
    [SerializeField]
    private AnimationCurve bounceCurve;
    [SerializeField][Range(0.1f,2f)]
    private float bounceTime;
    private Coroutine bounceRoutine;
    void Awake() {
        instance = this;
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    public static void AddXP(float xp) {
        if (instance.bounceRoutine == null) {
            instance.StartCoroutine(instance.TweenXP(instance.currentXP, instance.neededXP));
        }
        instance.currentXP += xp;
        if (instance.currentXP >= instance.neededXP) {
            instance.currentXP -= instance.neededXP;
            instance.neededXP *= 1.5f;
            instance.levelUp?.Invoke();
        }
    }
    void Process(float xp, float maxXP) {
        float ratio = xp/maxXP;
        targetRenderer.SetBlendShapeWeight(targetRenderer.sharedMesh.GetBlendShapeIndex(targetBlendshape), ratio*100f);
    }
    IEnumerator TweenXP(float fromXP, float fromNeededXP) {
        float startTime = Time.time;
        while (Time.time < startTime+bounceTime && isActiveAndEnabled) {
            yield return null;
            float t = (Time.time-startTime)/bounceTime;
            Process(Mathf.Lerp(fromXP, currentXP, bounceCurve.Evaluate(t)), Mathf.Lerp(fromNeededXP, neededXP, bounceCurve.Evaluate(t)));
        }
        bounceRoutine = null;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
        bounceRoutine = null;
        if (enabled) {
            StartCoroutine(TweenXP(currentXP, neededXP));
        }
    }
}
