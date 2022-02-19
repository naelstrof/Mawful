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
    public float initialProbability = 0.5f;
    protected int width = 2;
    protected int height = 2;
    protected void Rotate(float rotationAngle, ref int x, ref int y) {
        Vector2 offset = new Vector2((float)(width-1)*0.5f, ((float)(height-1)*0.5f));
        Vector3 rotCheck = new Vector3((float)x-offset.x, (float)y-offset.y, 0f);
        // Rotate them
        Vector3 rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward) * rotCheck;
        // Convert them back to indices.
        x = Mathf.RoundToInt(rotation.x+offset.x);
        y = Mathf.RoundToInt(rotation.y+offset.y);
    }
    public virtual MapTileEdge GetSubTile(Vector2 p, float rotationAngle) {
        Vector2 offset = new Vector2((float)(width-1)*0.5f, ((float)(height-1)*0.5f));
        Vector3 rotCheck = new Vector3(p.x-offset.x, p.y-offset.y, 0f);
        // Rotate them
        Vector3 rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward) * rotCheck;
        // Convert them back to indices.
        int x = Mathf.RoundToInt(rotation.x+offset.x);
        int y = Mathf.RoundToInt(rotation.y+offset.y);
        return edges[x+(y*width)];
    }
    public virtual MapTileEdge GetSubTile(int x, int y, float rotationAngle) {
        Rotate(rotationAngle, ref x, ref y);
        return edges[x+(y*2)];
    }
    public bool CanPlace(MapGenerator generator, int px, int py) {
        for(float rotation = 0f; rotation < 361f; rotation += 90f) {
            if (CanPlace(generator, px, py, rotation)) {
                return true;
            }
        }
        return false;
    }
    public virtual bool CanPlace(MapGenerator generator, int px, int py, float rotationAngle, MapTile other, int otherx, int othery, float otherRotationAngle) {
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
        return generator.IsValidNeighbor(GetSubTile(edgeA, rotationAngle), other.GetSubTile(otherEdgeA, otherRotationAngle)) && generator.IsValidNeighbor(GetSubTile(edgeB, rotationAngle), other.GetSubTile(otherEdgeB, otherRotationAngle));
    }
    public virtual bool CanPlace(MapGenerator generator, int px, int py, float rotationAngle) {
        // Sub pixel locations
        int sx = px*width;
        int sy = py*height;

        bool valid = generator.GetTile(px,py).tile == null && px >= 0 && px < generator.width && py >=0 && py < generator.height;
        // West edge
        valid &= CanPlace(generator, px, py, rotationAngle, generator.GetTile(px+1,py).tile, px+1, py, generator.GetTile(px+1,py).rotation);
        valid &= CanPlace(generator, px, py, rotationAngle, generator.GetTile(px-1,py).tile, px-1, py, generator.GetTile(px-1,py).rotation);
        valid &= CanPlace(generator, px, py, rotationAngle, generator.GetTile(px,py+1).tile, px, py+1, generator.GetTile(px,py+1).rotation);
        valid &= CanPlace(generator, px, py, rotationAngle, generator.GetTile(px,py-1).tile, px, py-1, generator.GetTile(px,py-1).rotation);
        return valid;
    }
    public void Place(MapGenerator generator, int px, int py) {
        int rotationChoices = 0;
        for(float rotation=0f;rotation<361f;rotation+=90f) {
            if (CanPlace(generator, px, py, rotation)) {
                rotationChoices++;
            }
        }
        int randomRotationChoice = UnityEngine.Random.Range(0, rotationChoices);
        int currentRotationChoice = 0;
        for(float rotation=0f;rotation<361f;rotation+=90f) {
            if (CanPlace(generator, px, py, rotation)) {
                if (currentRotationChoice++ == randomRotationChoice) {
                    Place(generator, px, py, rotation);
                }
            }
        }
    }
    public virtual void Place(MapGenerator generator, int px, int py, float rotationAngle) {
        GameObject p = GameObject.Instantiate(prefab, generator.transform);
        p.transform.localPosition = new Vector3(((float)px+0.5f)*5f,0f,((float)py+0.5f)*5f);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up) * Quaternion.AngleAxis(-90f,Vector3.right);
        generator.GetTile(px,py).tile = this;
        generator.GetTile(px,py).rotation = rotationAngle;
        generator.GetTile(px,py).spawnedPrefabs.Add(p);
    }
}
