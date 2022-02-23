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
    public Image background;
    public Transform targetTransform;
    private List<Image> prefabs;
    private List<float> voreBumps;
    private int currentBump;
    void Start() {
        prefabs = new List<Image>();
        Leveler.instance.xpChanged += OnXPChanged;
        background.material = Material.Instantiate(background.material);
        voreBumps = new List<float>();
        for(int i=0;i<32;i++) {
            voreBumps.Add(i%2==0? float.MaxValue : 1f);
        }
        background.material.SetFloatArray("_Vores", voreBumps);
        VoreTail.instance.bumpAdded += OnVoreBumpsChanged;
        OnXPChanged(0f, 5f);
    }
    void OnVoreBumpsChanged(VoreTail.VoreBump bump) {
        voreBumps[currentBump*2] = bump.startTime;
        voreBumps[currentBump*2+1] = bump.duration;
        currentBump++;
        currentBump = currentBump%(voreBumps.Count/2);
        background.material.SetFloatArray("_Vores", voreBumps);
    }
    void OnDestroy() {
        Leveler.instance.xpChanged -= OnXPChanged;
        VoreTail.instance.bumpAdded -= OnVoreBumpsChanged;
    }
    void SpawnIfNeeded(int number) {
        for (int i=prefabs.Count;i<number;i++) {
            prefabs.Add(GameObject.Instantiate(prefab.gameObject, targetTransform).GetComponentInChildren<Image>());
            prefabs[i].material = Material.Instantiate(prefabs[i].material);
        }
        background.material.SetFloat("_ElementWidth", prefabs.Count*32+20);
    }
    void OnXPChanged(float xp, float neededXP) {
        int available = Mathf.Min((int)neededXP,numGut);
        SpawnIfNeeded(available);
        float ratio = xp/neededXP;
        for(int i=0;i<available;i++) {
            prefabs[i].sprite = (i+1) < available*ratio ? filled : unfilled;
            prefabs[i].material.SetFloat("_Strained", (i+1)<available*ratio ? 1f : 0f);
        }
        background.material.SetFloat("_ElementWidth", available*32+20);
    }
    void Update() {
        for(int i=0;i<prefabs.Count;i++) {
            prefabs[i].material.SetFloat("_UnscaledTime", Time.unscaledTime);
        }
    }
}
