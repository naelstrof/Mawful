using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

[CustomEditor(typeof(MapTile))]
public class MapTileEditor : Editor {
    public override void OnInspectorGUI() {
        MapTile tile = (MapTile)target;
        tile.rotationAngle = 0f;
        SerializedProperty edgesProps = serializedObject.FindProperty("edges");
        for (int i = edgesProps.arraySize;i<MapTile.size*MapTile.size;i++) {
            edgesProps.InsertArrayElementAtIndex(0);
        }
        EditorGUI.BeginChangeCheck();
        for(int y = MapTile.size-1;y>=0;y--) {
            EditorGUILayout.BeginHorizontal(GUILayout.MaxWidth(512));
            for(int x = 0;x<MapTile.size;x++) {
                SerializedProperty prop = edgesProps.GetArrayElementAtIndex(x+y*MapTile.size);
                EditorGUILayout.PropertyField(prop, GUIContent.none);
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUI.EndChangeCheck();
        serializedObject.ApplyModifiedProperties();
        DrawDefaultInspector();
    }
}
#endif

[CreateAssetMenu(fileName = "New MapTile", menuName = "VoreGame/MapTile", order = 1)]
public class MapTile : ScriptableObject {
    [SerializeField]
    protected GameObject prefab;
    [SerializeField]
    protected List<MapTileEdge> edges;
    [SerializeField]
    protected float initialProbability = 1f;

    [HideInInspector]
    public float probability = 1f;
    public float GetInitialProbability() => initialProbability;

    [HideInInspector]
    public float rotationAngle;
    [SerializeField]
    public bool canRotate = true;
    public const int size = 4;
    public void ApplyRotation() {
        List<MapTileEdge> newEdges = new List<MapTileEdge>(edges);
        for (int x=0;x<size;x++) {
            for (int y=0;y<size;y++) {
                newEdges[x + y*size] = GetRotatedSubTile(new Vector2(x,y));
            }
        }
        edges = newEdges;
    }
    public virtual MapTileEdge GetSubTile(Vector2 p) {
        return edges[(int)(p.x+p.y*size)];
    }
    protected virtual MapTileEdge GetRotatedSubTile(Vector2 p) {
        Vector2 offset = new Vector2((float)(size-1)*0.5f, (float)(size-1)*0.5f);
        Vector3 rotCheck = new Vector3(p.x-offset.x, p.y-offset.y, 0f);
        // Rotate them
        Vector3 rotation = Quaternion.AngleAxis(rotationAngle, Vector3.forward) * rotCheck;
        // Convert them back to indices.
        int x = Mathf.RoundToInt(rotation.x+offset.x);
        int y = Mathf.RoundToInt(rotation.y+offset.y);
        return edges[x+(y*size)];
    }
    public virtual bool CanPlace(MapGenerator generator, int px, int py, MapTile other, int otherx, int othery) {
        if (other == null || otherx < 0 || otherx >= generator.width || othery < 0 || othery >= generator.height) {
            return true;
        }
        float tileHalf = ((size-1)*0.5f);
        Vector2 edgeNormal = (new Vector2(otherx,othery) - new Vector2(px,py)).normalized;
        Vector2 edgeTangent = new Vector2(edgeNormal.y, edgeNormal.x);
        Vector2 center = new Vector2(tileHalf, tileHalf);

        // Won't work for even numbers.
        Vector2 startEdgeA = center+edgeNormal*tileHalf-edgeTangent*tileHalf;
        //Vector2 edgeB = center+edgeNormal*0.5f+edgeTangent*0.5f;
        Vector2 otherStartEdgeA = center-edgeNormal*tileHalf-edgeTangent*tileHalf;
        //Vector2 otherEdgeB = center-edgeNormal*0.5f+edgeTangent*0.5f;
        for (int i=0;i<size;i++ ) {
            Vector2 edgeA = startEdgeA + edgeTangent*(float)i;
            Vector2 edgeB = otherStartEdgeA + edgeTangent*(float)i;
            if (!generator.IsValidNeighbor(GetSubTile(edgeA), other.GetSubTile(edgeB))) {
                return false;
            }
        }
        return true;
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
        p.transform.localPosition = new Vector3((float)px*2.5f*size,0f,(float)py*2.5f*size);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up);// * Quaternion.AngleAxis(-90f,Vector3.right);
        generator.GetTile(px,py).tile = this;
        generator.GetTile(px,py).spawnedPrefabs.Add(p);
        generator.ConfirmPlacement(generator.GetTile(px,py));
    }
}
