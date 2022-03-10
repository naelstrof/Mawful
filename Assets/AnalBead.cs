using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnalBead : PooledItem {
    private float startTime;
    private float duration;
    private new MeshRenderer renderer;
    private Vector3 offset;
    private AnimationBatcher batcher;
    private IPositionCurve positionCurve;
    [SerializeField]
    private AnimationCurve scaleCurve;
    private AnalBeadScoreDisplay timerSource;
    private ScoreCard packet;
    private bool triggered = false;
    public override void Awake() {
        base.Awake();
        batcher = GetComponent<AnimationBatcher>();
        renderer = GetComponent<MeshRenderer>();
    }
    public void SetUpBead(ScoreCard packet, IPositionCurve curve, AnalBeadScoreDisplay timerSource, float duration) {
        this.packet = packet;
        positionCurve = curve;
        this.timerSource = timerSource;
        startTime = timerSource.timer+0.2f;
        this.duration = duration;
        transform.rotation = Quaternion.Euler(UnityEngine.Random.Range(0,2)*180f,UnityEngine.Random.Range(-20f,20f), UnityEngine.Random.Range(0f,360f));
        //filter.sharedMesh = packet.mesh;
        batcher.SetAnimation(packet.GetStruggleAnimation());
        renderer.sharedMaterial = packet.material;
        offset = renderer.bounds.center-transform.position;
        triggered = false;
    }
    void Update() {
        if (timerSource==null) {
            return;
        }
        float t = Mathf.Clamp01((timerSource.timer-startTime)/duration);
        float scale = scaleCurve.Evaluate(t);
        transform.position = positionCurve.Evaluate(t) - offset*scale;
        transform.localScale = Vector3.one * scale;
        if (!triggered && t>0.7f) {
            timerSource.PacketReachedEnd(packet);
            triggered = true;
        }
        if (t>=1f) {
            gameObject.SetActive(false);
            Reset();
        }
    }
}
