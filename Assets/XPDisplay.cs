using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class XPDisplay : MonoBehaviour {
    [Range(1,32)]
    public int numGut;
    public Image prefab;
    public Sprite unfilled;
    public Sprite filled;
    private List<Image> prefabs;
    void Start() {
        prefabs = new List<Image>();
        Leveler.instance.xpChanged += OnXPChanged;
        OnXPChanged(0f, 5f);
    }
    void OnDestroy() {
        Leveler.instance.xpChanged -= OnXPChanged;
    }
    void SpawnIfNeeded(int number) {
        for (int i=prefabs.Count;i<number;i++) {
            prefabs.Add(GameObject.Instantiate(prefab.gameObject, transform).GetComponentInChildren<Image>());
            prefabs[i].material = Material.Instantiate(prefabs[i].material);
        }
    }
    void OnXPChanged(float xp, float neededXP) {
        int available = Mathf.Min((int)neededXP,numGut);
        SpawnIfNeeded(available);
        float ratio = xp/neededXP;
        for(int i=0;i<available;i++) {
            prefabs[i].sprite = (i+1) < available*ratio ? filled : unfilled;
            prefabs[i].material.SetFloat("_Strained", (i+1)<available*ratio ? 1f : 0f);
        }
    }
    void Update() {
        for(int i=0;i<prefabs.Count;i++) {
            prefabs[i].material.SetFloat("_UnscaledTime", Time.unscaledTime);
        }
    }
}
