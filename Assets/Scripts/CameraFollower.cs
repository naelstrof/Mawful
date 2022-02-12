using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
public class CameraFollower : MonoBehaviour {
    private static CameraFollower instance;
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
        instance = this;
    }
    void Start() {
        cam = GetComponent<Camera>();
    }
    void Update() {
        if (PlayerCharacter.player == null) {
            return;
        }
        Vector3 position = PlayerCharacter.playerPosition;
        float screenZ = (cam.farClipPlane-cam.nearClipPlane)*screenSpacePosition.z;
        Vector3 desiredPoint = cam.ScreenToWorldPoint(new Vector3(screenSpacePosition.x*Screen.width, screenSpacePosition.y*Screen.height, screenZ));
        Vector3 diff = position-desiredPoint;
        transform.position = Vector3.SmoothDamp(transform.position, transform.position + diff, ref vel, 0.1f);
        //transform.rotation = Quaternion.LookRotation((position-transform.position).normalized, Vector3.up);
    }
}
