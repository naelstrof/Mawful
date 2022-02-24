using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;


public class UIShaderPixelSender : MonoBehaviour {
    [SerializeField]
    List<Image> imagesToUpdate;
    void Start() {
        foreach(Image img in imagesToUpdate) {
            img.material = Material.Instantiate(img.material);
        }
    }
    void Update() {
        foreach(Image img in imagesToUpdate) {
            img.material.SetFloat("_ElementWidth", img.GetComponent<RectTransform>().sizeDelta.x);
            img.material.SetFloat("_ElementHeight", img.GetComponent<RectTransform>().sizeDelta.y);
            img.material.SetFloat("_UnscaledTime", Time.unscaledTime);
        }
    }
}
