using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateOverTime : MonoBehaviour {
    void Update() {
        transform.rotation = Quaternion.AngleAxis(Time.time*40f, Vector3.up);
    }
}
