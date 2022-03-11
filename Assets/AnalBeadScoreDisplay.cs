using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class AnalBeadScoreDisplay : MonoBehaviour {
    [SerializeField]
    private AnalBeadPool analBeadPool;
    private List<ScoreCard> packets;
    [SerializeField]
    private AnimationCurve scaleCurve;
    [SerializeField]
    private float beadsPerSecond = 1f;
    [SerializeField]
    private float timeScale = 1f;
    private float maxBeadsPerSecond = 5f;
    private float maxTimeScale = 5f;
    private float duration = 5f;
    [SerializeField]
    private Transform startTransform;
    [SerializeField]
    private Transform endTransform;
    private float spawnAccumulator;
    private int currentPacket;
    [SerializeField]
    private Vore targetVore;
    [SerializeField]
    private SkinnedMeshRenderer player;
    private Vector3[] positions;
    [SerializeField]
    private Transform[] vfxBindedPositions;
    private CatmullRomPositionSpline positionCurve;
    [SerializeField]
    private AnimationCurve buttSampleCurve;
    [HideInInspector]
    public float timer;
    private float buttCurveSampleTime = 0f;
    [SerializeField]
    private PenetrationTech.Penetrable penetrable;
    [SerializeField]
    private LineRenderer lineRenderer;
    private Vector3[] lineRendererPositions;
    [SerializeField]
    private VisualEffect effect;
    [SerializeField]
    private XPPanelDisplay panelDisplay;
    [SerializeField]
    private CanvasGroup damageShow;
    void Start() {
        currentPacket = 0;
        packets = Score.GetScores();
        Score.ClearScore();
        positions = new Vector3[5];
        positionCurve = new CatmullRomPositionSpline();
        lineRendererPositions = new Vector3[20];
        lineRenderer.positionCount = 20;
    }
    public void Begin() {
        enabled = true;
        effect.enabled = true;
        lineRenderer.enabled = true;
    }
    public void PacketReachedEnd(ScoreCard packet) {
        targetVore.Vaccum(null);
        panelDisplay.AddScore(packet);
    }
    public void Skip() {
        if (!enabled && Score.HasScore()) {
            Begin();
            return;
        }
        if (timeScale < maxTimeScale) {
            timeScale = maxTimeScale;
            return;
        }
        if (beadsPerSecond < maxBeadsPerSecond) {
            beadsPerSecond = maxBeadsPerSecond;
            return;
        }
        if (currentPacket < packets.Count && maxBeadsPerSecond != 0) {
            for(int i=currentPacket;i<packets.Count;i++) {
                PacketReachedEnd(packets[i]);
            }
            targetVore.Flush();
            timer = float.MaxValue;
            currentPacket = packets.Count;
            enabled = false;
            effect.enabled = false;
            lineRenderer.enabled = false;
            damageShow.alpha = 1f;
            return;
        }
        // If we're all done
        if (currentPacket >= packets.Count || maxBeadsPerSecond == 0) {
            LevelHandler.StartLevelStatic("MainMenu");
            return;
        }
    }
    void Update() {
        timeScale = Mathf.MoveTowards(timeScale, maxTimeScale, Time.deltaTime*0.1f);
        if (timeScale >= maxTimeScale) {
            beadsPerSecond = Mathf.MoveTowards(beadsPerSecond, maxBeadsPerSecond, Time.deltaTime*0.1f);
        }
        timer += Time.deltaTime*timeScale;
        float dist = Vector3.Distance(startTransform.position, endTransform.position);
        positions[0] = startTransform.position;
        positions[1] = startTransform.position - startTransform.up*0.4f;
        float jiggle = Mathf.Lerp((Mathf.Abs(Mathf.Sin(Time.time*3f))*Mathf.Abs(Mathf.Sin(Time.time*0.5f)-0.5f)+0.1f), 1f, 0.75f);
        positions[2] = (startTransform.position*0.6f + endTransform.position*0.4f) + Vector3.down*dist*0.5f*jiggle;
        positions[3] = endTransform.position + endTransform.up*1.5f;
        positions[4] = endTransform.position;
        for(int i=0;i<vfxBindedPositions.Length && i < positions.Length;i++) {
            vfxBindedPositions[i].position = positions[i];
        }

        positionCurve.SetTargetPositions(positions);
        for(int i=0;i<lineRendererPositions.Length;i++) {
            float f = (float)i/20f;
            lineRendererPositions[i] = positionCurve.Evaluate(f);
        }
        lineRenderer.SetPositions(lineRendererPositions);
        spawnAccumulator += beadsPerSecond*Time.deltaTime*timeScale;
        while (spawnAccumulator>1f) {
            AnalBead bead;
            analBeadPool.TryInstantiate(out bead);
            bead.SetUpBead(packets[currentPacket], positionCurve, this, duration);
            spawnAccumulator-=1f;
            currentPacket++;
            if (currentPacket>=packets.Count) {
                beadsPerSecond = 0f;
                maxBeadsPerSecond = 0f;
                damageShow.alpha = 1f;
            }
            buttCurveSampleTime = timer;
            penetrable.enabled = false;
        }
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("OpenMouth"), buttSampleCurve.Evaluate(Mathf.Clamp01((timer-buttCurveSampleTime)/0.75f))*100f);
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("NeckBulge"), buttSampleCurve.Evaluate(Mathf.Clamp01((timer-buttCurveSampleTime)/0.75f))*100f);
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("Fatten"), (1f-currentPacket/packets.Count)*100f);
    }
}
