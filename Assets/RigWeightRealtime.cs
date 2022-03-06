using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Animations.Rigging;

public class RigWeightRealtime : MonoBehaviour {
    private Rig rig;
    [Range(0f,1f)]
    public float weight;
    void Start() {
        rig = GetComponentInChildren<Rig>();
    }

    // Update is called once per frame
    void Update() {
        rig.weight = weight;
    }
}
