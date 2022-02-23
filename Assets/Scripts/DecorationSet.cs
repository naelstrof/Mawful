using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "New DecorationSet", menuName = "VoreGame/Map Decoration Set", order = 1)]
public class DecorationSet : ScriptableObject {
    [System.Serializable]
    public class DecorationPair {
        [Range(0f,1f)]
        public float density = 0.1f;
        public MapTileEdge targetEdge;
        public List<GameObject> prefabsToSpawn;
    }
    public DecorationPair GetDecoration(MapTileEdge edge) {
        for(int i=0;i<pairs.Count;i++) {
            if (pairs[i].targetEdge == edge) {
                return pairs[i];
            }
        }
        return null;
    }
    public List<DecorationPair> pairs;
}
