using System.Collections;
using System.Collections.Generic;
using JigglePhysics;
using UnityEngine;

public class JiggleRigController : MonoBehaviour {
    private JiggleRigBuilder builder;
    [Range(0f,1f)]
    public float blend = 0f;
    // Start is called before the first frame update
    void Start() {
        builder = GetComponent<JiggleRigBuilder>();
    }
    void Update() {
        (builder.jiggleRigs[0].jiggleSettings as JiggleSettingsBlend).normalizedBlend = blend;
    }
}
