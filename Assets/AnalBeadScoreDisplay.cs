using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class AnalBeadScoreDisplay : MonoBehaviour {
    [SerializeField]
    private AnalBeadPool analBeadPool;
    private List<Score.ScorePacket> packets;
    [SerializeField]
    private AnimationCurve scaleCurve;
    [SerializeField]
    private float beadsPerSecond = 1f;
    [SerializeField]
    private float timeScale = 1f;
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
    void Start() {
        currentPacket = 0;
        packets = Score.GetScores();
        packets.Sort((a,b)=>1-2*Random.Range(0,1));
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
    public void PacketReachedEnd(Score.ScorePacket packet) {
        targetVore.Vaccum(null);
    }
    void Update() {
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
            }
            buttCurveSampleTime = timer;
            penetrable.enabled = false;
        }
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("OpenMouth"), buttSampleCurve.Evaluate(Mathf.Clamp01((timer-buttCurveSampleTime)/0.75f))*100f);
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("NeckBulge"), buttSampleCurve.Evaluate(Mathf.Clamp01((timer-buttCurveSampleTime)/0.75f))*100f);
        player.SetBlendShapeWeight(player.sharedMesh.GetBlendShapeIndex("Fatten"), (1f-currentPacket/packets.Count)*100f);
    }
}
