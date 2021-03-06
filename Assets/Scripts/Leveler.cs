using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class Leveler : MonoBehaviour {
    private AudioSource source;
    public AudioPack tummyGrumbles;
    public delegate void XPChangedAction(float xp, float neededXP);
    public event XPChangedAction xpChanged;
    public event LevelUpAction levelUp;
    public delegate void LevelUpAction();
    [SerializeField]
    private string targetBlendshape;
    [SerializeField]
    private SkinnedMeshRenderer targetRenderer;
    private float currentXP = 0;
    private float currentTummyVolume = 0f;
    private float currentTummyVelocity = 0f;
    private float tummyVolume = 0f;
    private float xpScalingPower = 2.5f;
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
        source = GetComponent<AudioSource>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    public void AddXP(float xp) {
        tummyVolume += xp;
        currentXP += xp;
        if (currentXP >= neededXP) {
            currentXP -= neededXP;
            levelUp?.Invoke();
            currentLevel++;
            neededXP = Mathf.Pow(currentLevel,xpScalingPower) + 4f;
            Debug.Log("Leveled up to " + currentLevel + ", now need " + neededXP + " XP");
        }
        xpChanged?.Invoke(currentXP, neededXP);
    }
    void Update() {
        //targetDickTransform.localScale = Vector3.one * (1f+currentTummyVolume*0.1f);
        targetRenderer.SetBlendShapeWeight(targetRenderer.sharedMesh.GetBlendShapeIndex(targetBlendshape), Mathf.Min(currentTummyVolume*8f,100f));
        currentTummyVelocity = Mathf.MoveTowards(currentTummyVelocity, 0f, Time.deltaTime*3f);
        currentTummyVelocity += (tummyVolume - currentTummyVolume) * Time.deltaTime * 7f;
        currentTummyVelocity = Mathf.Clamp(currentTummyVelocity, -5f, 5f);
        currentTummyVolume += currentTummyVelocity;
        tummyVolume = Mathf.MoveTowards(tummyVolume, 0f, tummyVolume*Time.deltaTime*0.05f);
        if (tummyVolume > 8f && !source.isPlaying) {
            tummyGrumbles.Play(source);
        }
    }
    void Process(float xp, float maxXP) {
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
        bounceRoutine = null;
    }
}
