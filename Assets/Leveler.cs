using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Leveler : MonoBehaviour {
    public delegate void XPChangedAction(float xp, float neededXP);
    public event XPChangedAction xpChanged;
    public event LevelUpAction levelUp;
    public delegate void LevelUpAction();
    public static Leveler instance;
    [SerializeField]
    private string targetBlendshape;
    [SerializeField]
    private SkinnedMeshRenderer targetRenderer;
    private float currentXP = 0;
    private float currentTummyVolume = 0f;
    private float currentTummyVelocity = 0f;
    private float tummyVolume = 0f;
    private float xpScalingPower = 2f;
    private int currentLevel = 0;
    private float neededXP = 5;
    [SerializeField]
    private AnimationCurve bounceCurve;
    [SerializeField][Range(0.1f,2f)]
    private float bounceTime;
    private Coroutine bounceRoutine;
    [SerializeField]
    private Transform targetDickTransform;
    void Awake() {
        instance = this;
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    public static void AddXP(float xp) {
        instance.tummyVolume += xp;
        instance.currentXP += xp;
        if (instance.currentXP >= instance.neededXP) {
            instance.currentXP -= instance.neededXP;
            instance.levelUp?.Invoke();
            instance.currentLevel++;
            instance.neededXP = Mathf.Pow(instance.currentLevel,instance.xpScalingPower) + 5f;
            Debug.Log("Leveled up to " + instance.currentLevel + ", now need " + instance.neededXP + " XP");
        }
        instance.xpChanged?.Invoke(instance.currentXP, instance.neededXP);
    }
    void Update() {
        targetDickTransform.localScale = Vector3.one * (1f+currentTummyVolume*0.1f);
        targetRenderer.SetBlendShapeWeight(targetRenderer.sharedMesh.GetBlendShapeIndex(targetBlendshape), Mathf.Min(currentTummyVolume*8f,100f));
        currentTummyVelocity = Mathf.MoveTowards(currentTummyVelocity, 0f, Time.deltaTime);
        currentTummyVelocity += (tummyVolume - currentTummyVolume) * Time.deltaTime * 8f;
        currentTummyVolume += currentTummyVelocity;
        tummyVolume = Mathf.MoveTowards(tummyVolume, 0f, tummyVolume*Time.deltaTime*0.05f);
    }
    void Process(float xp, float maxXP) {
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
        bounceRoutine = null;
    }
}
