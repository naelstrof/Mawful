using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;

[CreateAssetMenu(fileName = "NewBakedAnimation", menuName = "VoreGame/BakedAnimation", order = 1)]
public class BakedAnimation : ScriptableObject {
    public float framesPerSecond = 15f;
    [SerializeField]
    private AnimationClip animationClip;
    [SerializeField]
    private GameObject animatedMeshPrefab;
    public bool loop = true;
    public List<Mesh> frames;
    [ContextMenu("Bake")]
    void Bake() {
        frames = new List<Mesh>();
        GameObject prefab = GameObject.Instantiate(animatedMeshPrefab);
        SkinnedMeshRenderer renderer = prefab.GetComponentInChildren<SkinnedMeshRenderer>();
        string path = AssetDatabase.GetAssetPath(this);
        for (float time=0f;time<animationClip.length;time+=1f/framesPerSecond) {
            Mesh currentMesh = new Mesh();
            animationClip.SampleAnimation(prefab,time);
            renderer.BakeMesh(currentMesh);
            string assetName = Path.GetDirectoryName(path)+"/Mesh"+animationClip.name + frames.Count.ToString()+".mesh";
            AssetDatabase.CreateAsset(currentMesh, assetName);
            frames.Add(AssetDatabase.LoadAssetAtPath<Mesh>(assetName));
        }
        if (Application.isPlaying) {
            Destroy(prefab);
        } else {
            DestroyImmediate(prefab);
        }
    }
}
