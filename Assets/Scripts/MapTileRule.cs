using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MapTileRule : ScriptableObject {
    public float GetProbability(MapGenerator.GridMapTile a, MapGenerator.GridMapTile b) {
        return 1f;
    }
    public bool GetValid(MapGenerator.GridMapTile a, MapGenerator.GridMapTile b) {
        return false;
    }
}
