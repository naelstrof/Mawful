using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraFollower : MonoBehaviour {
    public delegate void GloryModeChangeAction(bool glory);
    public event GloryModeChangeAction gloryModeChanged;
    public static CameraFollower instance;
    public AudioListener listener;
    [Range(0f,1f)]
    public float listenerDistance01;
    public bool main = true;
    public Transform targetTransform;
    public static Camera GetCamera() => instance.cam;
    public static void SetGloryVore(bool glory) => instance.SetGloryVoreCam(glory);
    public static Vector3 StaticGetTargetScreenSpace() {
        return instance.GetTargetScreenSpace();
    }
    public static Quaternion GetInputRotation() {
        Vector3 euler = instance.cam.transform.rotation.eulerAngles;
        return Quaternion.Euler(0f,euler.y,0f);
    }
    [SerializeField]
    private Vector3 screenSpacePosition;
    [SerializeField]
    private bool controlRotation = false;
    [SerializeField]
    private Vector3 gloryScreenSpacePosition;
    private Camera cam;
    [SerializeField]
    private Renderer[] letterboxRenderers;
    private Vector3 vel;
    private float gloryTweenTarget;
    private float gloryTween;
    private float maxDeflection = 15f;
    private Vector2 deflection;
    private float zoom;
    void SetGloryVoreCam(bool glory) {
        gloryTweenTarget = glory?1f:0f;
        gloryModeChanged?.Invoke(glory);
    }
    public static void AddDeflection(Vector2 deflect) {
        instance.deflection += deflect;
        instance.deflection.x = Mathf.Repeat(instance.deflection.x,360f);
        instance.deflection.y = Mathf.Clamp(instance.deflection.y, -10f, 10f);
    }
    public static void AddZoom(float zoom) {
        instance.zoom += zoom;
        instance.zoom = Mathf.Clamp01(instance.zoom);
    }
    void Awake() {
        cam = GetComponent<Camera>();
        if (main) {
            instance = this;
        }
        if (targetTransform == null) {
            targetTransform = PlayerCharacter.player.transform;
        }
    }
    private Vector3 GetTargetScreenSpace() {
        Vector3 screenPosition = Vector3.Lerp(screenSpacePosition, gloryScreenSpacePosition, gloryTween);
        screenPosition.z = Mathf.Lerp(screenPosition.z, 0.15f, zoom);
        return screenPosition;
    }
    void Update() {
        gloryTween = Mathf.MoveTowards(gloryTween, gloryTweenTarget, Time.deltaTime*2f);
        if (letterboxRenderers != null) {
            foreach(Renderer r in letterboxRenderers) {
                r.material.SetFloat("_LetterBoxAmount", (1f-gloryTween*0.3f));
            }
        }
        Vector3 position = targetTransform.position;
        Vector3 screenPosition = GetTargetScreenSpace();
        float screenZ = (cam.farClipPlane-cam.nearClipPlane)*screenPosition.z;
        if (letterboxRenderers.Length >0) {
            letterboxRenderers[0].transform.localPosition = Vector3.forward*screenZ*1.1f;
        }
        Vector3 desiredPoint = cam.ScreenToWorldPoint(new Vector3(screenPosition.x*cam.pixelWidth, screenPosition.y*cam.pixelHeight, screenZ));
        Vector3 diff = position-desiredPoint;
        if (main && controlRotation) {
            transform.rotation = Quaternion.Lerp(Quaternion.Euler(60f-deflection.y,-45f+deflection.x,0f), Quaternion.Euler(30f-deflection.y,-45f+deflection.x,0f), gloryTween);
            Vector3 newDesiredPoint = cam.ScreenToWorldPoint(new Vector3(screenPosition.x*cam.pixelWidth, screenPosition.y*cam.pixelHeight, screenZ));
            transform.position -= newDesiredPoint-desiredPoint;
        }
        transform.position = Vector3.SmoothDamp(transform.position, transform.position + diff, ref vel, 0.1f);
        if (main) {
            listener.transform.position = Vector3.Lerp(transform.position, targetTransform.position, listenerDistance01);
            Shader.SetGlobalFloat("PlayerDistance", screenPosition.z*0.8f);
        }
    }
}
