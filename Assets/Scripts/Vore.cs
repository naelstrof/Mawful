using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

[RequireComponent(typeof(AudioSource))]
public class Vore : MonoBehaviour {
    protected AudioSource source;
    [SerializeField]
    protected AudioPack gulp;
    [SerializeField]
    protected AudioPack travelSound;
    public delegate void VoreBumpAddedAction(VoreBump bumps);
    public event VoreBumpAddedAction bumpAdded;
    public delegate void VoreFinished (Character character);
    public event VoreFinished voreFinished;
    public class VoreBump {
        public VoreBump(float st, float dur, Character character) {
            startTime = st;
            duration = dur;
            this.character = character;
        }
        public Character character;
        public float startTime;
        public float duration;
    }
    [SerializeField]
    protected Transform mouth;
    [SerializeField]
    protected List<string> blends;
    protected List<int> blendIDs;
    [SerializeField]
    protected SkinnedMeshRenderer targetRenderer;
    protected Character player;
    protected HashSet<Character> vaccuming;
    protected HashSet<Character> readyToVore;
    [SerializeField]
    protected AnimationCurve voreBumpCurve;
    protected List<VoreBump> voreBumps;
    [SerializeField]
    protected float maxSimultaneousVores = 2.5f;
    public VisualEffect chompEffect;
    protected const float blendDistance = 0.5f;
    [SerializeField]
    [Range(0f,10f)]
    protected float minTimeRange = 1f;
    [SerializeField]
    [Range(0f,10f)]
    protected float maxTimeRange = 3f;
    protected virtual void Awake() {
        source = GetComponent<AudioSource>();
        vaccuming = new HashSet<Character>();
        voreBumps = new List<VoreBump>();
        readyToVore = new HashSet<Character>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    protected virtual void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    protected virtual void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    public virtual void FinishVore() {
        foreach(Character other in readyToVore) {
            other.Reset();
            other.gameObject.SetActive(false);
            voreBumps.Add(new VoreBump(Time.time,UnityEngine.Random.Range(minTimeRange, maxTimeRange), other));
            bumpAdded?.Invoke(voreBumps[voreBumps.Count-1]);
            vaccuming.Remove(other);
        }
        if (source.clip == null) {
            travelSound.Play(source);
        }
        gulp.PlayOneShot(source);
        readyToVore.Clear();
        chompEffect.Play();
    }
    public virtual void Vaccum(Character other) {
        if (other.StartVore()) {
            vaccuming.Add(other);
        }
    }
    protected virtual void StartVore(Character other) {
        readyToVore.Add(other);
        StartCoroutine(WaitForVore());
    }
    protected virtual IEnumerator WaitForVore() {
        yield return new WaitForSeconds(1f);
        FinishVore();
    }
    protected virtual void Start() {
        blendIDs = new List<int>();
        for (int i=0;i<blends.Count;i++) {
            blendIDs.Add(targetRenderer.sharedMesh.GetBlendShapeIndex(blends[i]));
        }
        player = GetComponentInParent<Character>();
    }
    protected virtual void Digest(Character character) {
        voreFinished?.Invoke(character);
    }
    protected virtual void Update() {
        for(int i=0;i<blendIDs.Count;i++) {
            float blendAmount = 0f;
            for(int j=voreBumps.Count-1;j>=0;j--) {
                float offset = blendDistance * (float)i;
                float t = (Time.time-(voreBumps[j].startTime+offset))/voreBumps[j].duration;
                float sample = voreBumpCurve.Evaluate(t);
                blendAmount = Mathf.Lerp(blendAmount, maxSimultaneousVores, sample/maxSimultaneousVores);
                if (t>1f && i == blendIDs.Count-1) {
                    gulp.PlayOneShot(source);
                    Digest(voreBumps[j].character);
                    voreBumps.RemoveAt(j);
                    if (voreBumps.Count == 0) {
                        // Stop the travelling sound
                        source.Stop();
                        source.clip = null;
                    }
                }
            }
            targetRenderer.SetBlendShapeWeight(blendIDs[i], Mathf.Min(blendAmount*100f, 250f));
        }
        Vector3 tailTarget = mouth.transform.position+mouth.transform.up*0.4f;
        foreach(Character character in vaccuming) {
            float dist = Vector3.Distance(character.transform.position, tailTarget);
            character.transform.position = Vector3.MoveTowards(character.transform.position, tailTarget, Time.deltaTime*8f + dist*Time.deltaTime*2f);
            character.transform.rotation = Quaternion.RotateTowards(character.transform.rotation, mouth.rotation, Time.deltaTime*360f*4f);
            if (Vector3.Distance(character.transform.position, tailTarget) < 0.1f && !readyToVore.Contains(character)) {
                StartVore(character);
            }
        }
    }
}
