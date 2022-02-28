using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ResizeToWorldBounds : MonoBehaviour {
    void Start() {
        WorldGrid.instance.worldPathReady += Resize;
    }
    void OnDestroy() {
        WorldGrid.instance.worldPathReady -= Resize;
    }
    void Resize() {
        transform.localPosition = WorldGrid.instance.worldBounds.center;
        transform.localScale = WorldGrid.instance.worldBounds.size+Vector3.up;
    }
}
