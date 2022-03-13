using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HideOnGloryMode : MonoBehaviour
{
    // Start is called before the first frame update
    void Start() {
        CameraFollower.instance.gloryModeChanged += OnGloryModeChanged;
    }
    void OnGloryModeChanged(bool glory) {
        gameObject.SetActive(!glory);
    }
    void OnDestroy() {
        CameraFollower.instance.gloryModeChanged -= OnGloryModeChanged;
    }
}
