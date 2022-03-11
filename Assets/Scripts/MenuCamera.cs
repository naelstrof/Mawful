using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityScriptableSettings;

[RequireComponent(typeof(Camera))]
public class MenuCamera : MonoBehaviour {
    [System.Serializable]
    public class MenuCameraTarget {
        public Transform transform;
        public Vector3 screenSpacePosition;
        public Vector3 GetWorldDesiredPoint(Camera cam) {
            float screenZ = (cam.farClipPlane-cam.nearClipPlane)*screenSpacePosition.z;
            Vector3 desiredPoint = cam.ScreenToWorldPoint(new Vector3(screenSpacePosition.x*cam.pixelWidth, screenSpacePosition.y*cam.pixelHeight, screenZ));
            return desiredPoint;
        }
    }
    public MenuCameraTarget targetA;
    public MenuCameraTarget targetB;
    public AudioListener listener;
    [Range(0f,1f)]
    public float listenerDistance01;
    private Camera cam;
    private Vector3 vel;
    [SerializeField]
    private VolumeSettingListener depth;
    void Awake() {
        cam = GetComponent<Camera>();
    }
    void Update() {
        Vector3 desiredTargetPointA = targetA.GetWorldDesiredPoint(cam);
        Vector3 desiredTargetPointB = targetB.GetWorldDesiredPoint(cam);
        float dist = Vector3.Distance(desiredTargetPointA, desiredTargetPointB);

        Vector3 realPointA = targetA.transform.position;
        Vector3 realPointB = targetB.transform.position;
        float realDist = Vector3.Distance(realPointA, realPointB);

        cam.fieldOfView += (realDist-dist)*Time.deltaTime*8f;

        Vector3 movementA = desiredTargetPointA-realPointA;
        Vector3 movementB = desiredTargetPointB-realPointB;

        Vector3 diff = (movementA + movementB)*0.5f;
        transform.position = Vector3.SmoothDamp(transform.position, transform.position - diff, ref vel, 1f);
        listener.transform.position = Vector3.Lerp(transform.position, realPointA, listenerDistance01);
        Shader.SetGlobalFloat("PlayerDistance", targetA.screenSpacePosition.z*0.8f);
        depth.SetDepth(Vector3.Distance(realPointA, transform.position));
    }
}
