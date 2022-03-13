using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimatorTriggerLevelLoad : MonoBehaviour {
    public void BeginLevel() {
        LevelHandler.StartLevelStatic("City");
    }
}
