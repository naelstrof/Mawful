using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshFloater : PooledItem {
    [SerializeField]
    private BakedNumbers numbers;
    [SerializeField]
    private AnimationCurve bouncyCurve;
    [SerializeField]
    private Gradient damageColors;
    private MeshFilter filter;
    private new Renderer renderer;
    private float startTime;
    private int display;
    private Color displayColor;
    public override void Awake() {
        base.Awake();
        filter = GetComponent<MeshFilter>();
        renderer = GetComponent<Renderer>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    public void SetDisplay(int display) {
        this.display = display;
        display = Mathf.Clamp(display, 0, numbers.maxNumber-1);
        filter.sharedMesh = numbers.numbers[display];
        startTime = Time.time;
        displayColor = damageColors.Evaluate((float)display/(float)numbers.maxNumber);
        renderer.material.SetColor("_FaceColor", displayColor);
        renderer.material.SetColor("_UnderlayColor", Color.black);
        renderer.material.SetColor("_OutlineColor", Color.black);
        transform.localScale = Vector3.one*Mathf.Max(bouncyCurve.Evaluate(0f)*Mathf.Lerp(0.08f, 0.25f, (float)display/(float)numbers.maxNumber),0.01f);
        transform.rotation = CameraFollower.GetCamera().transform.rotation;
    }
    public void Update() {
        float duration = 1.25f;
        float t = (Time.time-startTime)/duration;
        transform.localScale = Vector3.one*Mathf.Max(bouncyCurve.Evaluate(t)*Mathf.Lerp(0.08f, 0.25f, (float)display/(float)numbers.maxNumber),0.01f);
        renderer.material.SetColor("_FaceColor", new Color(displayColor.r, displayColor.g, displayColor.b, 1f-t));
        renderer.material.SetColor("_UnderlayColor", new Color(0,0,0,1f-t));
        renderer.material.SetColor("_UnderlayColor", new Color(0,0,0,1f-t));
        renderer.material.SetColor("_OutlineColor", new Color(0,0,0,1f-t));
        transform.position += Vector3.up * Time.deltaTime * t;
        if (t>=1f) {
            Reset();
            gameObject.SetActive(false);
        }
    }
    public override void Reset(bool recurse = true) {
        base.Reset(recurse);
    }
}
