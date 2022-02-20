using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "New SmartMapBuildingTile", menuName = "VoreGame/Smart Building MapTile", order = 1)]
public class SmartMapBuildingTile : MapTile {
    public List<GameObject> tallPrefabs = new List<GameObject>();
    private float GetGroupEstimation(MapGenerator generator, int px, int py) {
        float group = 0f;
        MapTile west = generator.GetTile(px+1,py).tile;
        if (west != null && west == this) {
            group+=1f;
        }
        MapTile east = generator.GetTile(px-1,py).tile;
        if (east != null && east == this) {
            group+=1f;
        }
        MapTile south = generator.GetTile(px,py-1).tile;
        if (south != null && south == this) {
            group+=1f;
        }
        MapTile north = generator.GetTile(px,py+1).tile;
        if (north != null && north == this) {
            group+=1f;
        }
        return group;
    }
    private void PlaceDefault(MapGenerator generator, int px, int py) {
        GameObject p = GameObject.Instantiate(prefab, generator.transform);
        p.transform.localPosition = new Vector3(((float)px+0.5f)*5f,0f,((float)py+0.5f)*5f);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up) * Quaternion.AngleAxis(-90f,Vector3.right);
        p.layer = LayerMask.NameToLayer("World");
        if (blocksMovement) {
            BoxCollider boxCollider = p.AddComponent<BoxCollider>();
            boxCollider.center = Vector3.zero;
            boxCollider.size = Vector3.one*4.95f;
        }

        var tile = generator.GetTile(px,py);
        tile.tile = this;
        tile.spawnedPrefabs.Add(p);
        generator.ConfirmPlacement(tile);
    }
    private void PlaceTall(MapGenerator generator, int px, int py) {
        GameObject p = GameObject.Instantiate(tallPrefabs[UnityEngine.Random.Range(0,tallPrefabs.Count)], generator.transform);
        p.transform.localPosition = new Vector3(((float)px+0.5f)*5f,0f,((float)py+0.5f)*5f);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up) * Quaternion.AngleAxis(-90f,Vector3.right);
        p.layer = LayerMask.NameToLayer("World");
        if (blocksMovement) {
            BoxCollider boxCollider = p.AddComponent<BoxCollider>();
            boxCollider.center = Vector3.zero;
            boxCollider.size = Vector3.one*4.95f;
        }
        
        var tile = generator.GetTile(px,py);
        tile.tile = this;
        tile.spawnedPrefabs.Add(p);
        generator.ConfirmPlacement(tile);
    }
    public override void Place(MapGenerator generator, int px, int py) {
        if (!CanPlace(generator, px, py)) {
            return;
        }
        if (GetGroupEstimation(generator, px, py) >= 1f) {
            PlaceTall(generator,px,py);
        } else {
            PlaceDefault(generator, px, py);
        }
    }
}
