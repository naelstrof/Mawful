using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "New MapTile", menuName = "VoreGame/MapTile", order = 1)]
public class MapTile : ScriptableObject {
    [SerializeField]
    protected GameObject prefab;
    [SerializeField]
    protected List<MapTileEdge> edges;

    public bool blocksMovement = false;
    [SerializeField]
    protected float initialProbability = 1f;

    [HideInInspector]
    public float probability = 1f;
    public float GetInitialProbability() => initialProbability;

    [HideInInspector]
    public float rotationAngle;
    [SerializeField]
    public bool canRotate = true;
    protected int width = 2;
    protected int height = 2;
    public void ApplyRotation() {
        List<MapTileEdge> newEdges = new List<MapTileEdge>(edges);
        for (int x=0;x<width;x++) {
            for (int y=0;y<height;y++) {
                newEdges[x + y*width] = GetRotatedSubTile(new Vector2(x,y));
            }
        }
        edges = newEdges;
    }
    public virtual MapTileEdge GetSubTile(Vector2 p) {
        return edges[(int)(p.x+p.y*width)];
    }
    protected virtual MapTileEdge GetRotatedSubTile(Vector2 p) {
        Vector2 offset = new Vector2((float)(width-1)*0.5f, ((float)(height-1)*0.5f));
        Vector3 rotCheck = new Vector3(p.x-offset.x, p.y-offset.y, 0f);
        // Rotate them
        Vector3 rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward) * rotCheck;
        // Convert them back to indices.
        int x = Mathf.RoundToInt(rotation.x+offset.x);
        int y = Mathf.RoundToInt(rotation.y+offset.y);
        return edges[x+(y*width)];
    }
    public virtual bool CanPlace(MapGenerator generator, int px, int py, MapTile other, int otherx, int othery) {
        if (other == null || otherx < 0 || otherx >= generator.width || othery < 0 || othery >= generator.height) {
            return true;
        }
        Vector2 edgeNormal = (new Vector2(otherx,othery) - new Vector2(px,py)).normalized;
        Vector2 edgeTangent = new Vector2(edgeNormal.y, edgeNormal.x);
        Vector2 center = new Vector2(0.5f, 0.5f);
        Vector2 edgeA = center+edgeNormal*0.5f-edgeTangent*0.5f;
        Vector2 edgeB = center+edgeNormal*0.5f+edgeTangent*0.5f;
        Vector2 otherEdgeA = center-edgeNormal*0.5f-edgeTangent*0.5f;
        Vector2 otherEdgeB = center-edgeNormal*0.5f+edgeTangent*0.5f;
        return generator.IsValidNeighbor(GetSubTile(edgeA), other.GetSubTile(otherEdgeA)) && generator.IsValidNeighbor(GetSubTile(edgeB), other.GetSubTile(otherEdgeB));
    }
    public virtual bool CanPlace(MapGenerator generator, int px, int py) {
        if (!CanPlace(generator, px, py, generator.GetTile(px+1,py).tile, px+1, py)) {
            return false;
        }
        if (!CanPlace(generator, px, py, generator.GetTile(px-1,py).tile, px-1, py)) {
            return false;
        }
        if (!CanPlace(generator, px, py, generator.GetTile(px,py+1).tile, px, py+1)) {
            return false;
        }
        if (!CanPlace(generator, px, py, generator.GetTile(px,py-1).tile, px, py-1)) {
            return false;
        }
        return true;
    }
    public virtual void Place(MapGenerator generator, int px, int py) {
        //if (!CanPlace(generator, px, py)) {
            //return;
        //}
        GameObject p = GameObject.Instantiate(prefab, generator.transform);
        p.transform.localPosition = new Vector3(((float)px+0.5f)*5f,0f,((float)py+0.5f)*5f);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up) * Quaternion.AngleAxis(-90f,Vector3.right);
        p.layer = LayerMask.NameToLayer("World");
        if (blocksMovement) {
            BoxCollider boxCollider = p.AddComponent<BoxCollider>();
            boxCollider.center = Vector3.zero;
            boxCollider.size = Vector3.one*4.9f;
        }
        generator.GetTile(px,py).tile = this;
        generator.GetTile(px,py).spawnedPrefabs.Add(p);
        generator.ConfirmPlacement(generator.GetTile(px,py));
    }
}
