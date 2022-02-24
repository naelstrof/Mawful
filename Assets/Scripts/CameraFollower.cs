using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraFollower : MonoBehaviour {
    private static CameraFollower instance;
    public bool main = true;
    public static Camera GetCamera() => instance.cam;
    public static Quaternion GetInputRotation() {
        Vector3 euler = instance.cam.transform.rotation.eulerAngles;
        return Quaternion.Euler(0f,euler.y,0f);
    }
    [SerializeField]
    private Vector3 screenSpacePosition;
    private Camera cam;
    private Vector3 vel;
    void Awake() {
        cam = GetComponent<Camera>();
        if (main) {
            instance = this;
        }
    }
    void Update() {
        if (PlayerCharacter.player == null) {
            return;
        }
        Vector3 position = PlayerCharacter.playerPosition;
        float screenZ = (cam.farClipPlane-cam.nearClipPlane)*screenSpacePosition.z;
        Vector3 desiredPoint = cam.ScreenToWorldPoint(new Vector3(screenSpacePosition.x*cam.pixelWidth, screenSpacePosition.y*cam.pixelHeight, screenZ));
        Vector3 diff = position-desiredPoint;
        transform.position = Vector3.SmoothDamp(transform.position, transform.position + diff, ref vel, 0.1f);
        //transform.rotation = Quaternion.LookRotation((position-transform.position).normalized, Vector3.up);
    }
}
