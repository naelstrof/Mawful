using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimationIntSet : MonoBehaviour {
    public string intName;
    public void SetInt(int i) {
        GetComponent<Animator>().SetInteger(intName, i);
    }
}
