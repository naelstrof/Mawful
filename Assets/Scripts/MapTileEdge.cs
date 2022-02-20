using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[CreateAssetMenu(fileName = "New MapTileEdge", menuName = "VoreGame/MapTileEdge", order = 1)]
public class MapTileEdge : ScriptableObject {
    [HideInInspector]
    public int validLookupCache;
}
