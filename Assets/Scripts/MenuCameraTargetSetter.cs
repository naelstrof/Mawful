using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(MenuCamera))]
public class MenuCameraTargetSetter : MonoBehaviour {
    [System.Serializable]
    public class MenuCameraTargetGroup {
        public MenuCamera.MenuCameraTarget targetA;
        public MenuCamera.MenuCameraTarget targetB;
    }
    public List<MenuCameraTargetGroup> groups;
    private MenuCamera cam;
    void Start() {
        cam = GetComponent<MenuCamera>();
    }
    public void SetGroup(int id) {
        cam.targetA = groups[id].targetA;
        cam.targetB = groups[id].targetB;
    }

}
