using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

[CreateAssetMenu(fileName = "NewBakedFloaters", menuName = "VoreGame/BakedFloaters", order = 1)]
public class BakedNumbers : ScriptableObject {
    public int maxNumber = 999;
    [SerializeField]
    private GameObject textMeshProPrefab;
    public List<Mesh> numbers;
#if UNITY_EDITOR
    [ContextMenu("Bake")]
    void Bake() {
        numbers = new List<Mesh>();
        GameObject prefab = GameObject.Instantiate(textMeshProPrefab);
        MeshRenderer renderer = prefab.GetComponentInChildren<MeshRenderer>();
        TMPro.TextMeshPro text = prefab.GetComponentInChildren<TMPro.TextMeshPro>();
        string path = AssetDatabase.GetAssetPath(this);
        for(int i=0;i<maxNumber;i++) {
            text.text = i.ToString();
            text.ForceMeshUpdate(true, true);
            string assetName = Path.GetDirectoryName(path)+"/Mesh"+textMeshProPrefab.name + i.ToString()+".mesh";
            AssetDatabase.CreateAsset(Mesh.Instantiate(text.meshFilter.sharedMesh), assetName);
            numbers.Add(AssetDatabase.LoadAssetAtPath<Mesh>(assetName));
        }
        if (Application.isPlaying) {
            Destroy(prefab);
        } else {
            DestroyImmediate(prefab);
        }
    }
#endif
}