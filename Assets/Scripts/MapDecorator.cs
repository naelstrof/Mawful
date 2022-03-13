using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MapDecorator : MonoBehaviour {
    public DecorationSet decor;
    public float tileSize = 2.5f;
    public int pixelCount = 4;
    private MapGenerator generator;
    void Start() {
        generator = GetComponent<MapGenerator>();
        generator.generationFinished += Decorate;
    }
    void OnDestroy() {
        if (generator != null) {
            generator.generationFinished -= Decorate;
        }
    }
    void Decorate(MapGenerator.MapGrid grid) {
        for(int x=0;x<grid.width;x++) {
            for(int y=0;y<grid.height;y++) {
                Decorate(grid.GetTile(x,y));
            }
        }
    }
    void Decorate(MapGenerator.GridMapTile gridTile) {
        Vector3 gridPosition = new Vector3((float)gridTile.x*2.5f*pixelCount,0f,(float)gridTile.y*2.5f*pixelCount);
        for(int x=0;x<pixelCount;x++) {
            for(int y=0;y<pixelCount;y++) {
                Vector3 offset = new Vector3(x*2.5f, 0f, y*2.5f);
                Decorate(gridPosition+offset, gridTile.tile.GetSubTile(new Vector2Int(x,y)));
            }
        }
    }
    void Decorate(Vector3 position, MapTileEdge edge) {
        var decoration = decor.GetDecoration(edge);
        if (decoration == null) {
            return;
        }
        if (UnityEngine.Random.Range(0f, 1f) > decoration.density*decoration.density) {
            return;
        }
        GameObject obj = GameObject.Instantiate(decoration.prefabsToSpawn[UnityEngine.Random.Range(0,decoration.prefabsToSpawn.Count)], transform);
        obj.transform.localPosition = position+new Vector3(-5f+1.25f, 0f, -5f+1.25f);
        obj.transform.localRotation = Quaternion.AngleAxis(90f*UnityEngine.Random.Range(0,3), Vector3.up);
        Character character = obj.GetComponentInChildren<Character>();
        if (character != null) {
            character.SetPositionAndVelocity(obj.transform.position, Vector3.zero);
        }
    }
}
