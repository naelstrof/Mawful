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
    public virtual MapTileEdge GetSubTile(Vector2Int p) {
        return edges[p.x+p.y*size];
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
        Vector2Int edgeNormal = (new Vector2Int(otherx,othery) - new Vector2Int(px,py));
        Vector2Int startEdgeA = new Vector2Int(Mathf.Max(edgeNormal.x,0)*(size-1), Mathf.Max(edgeNormal.y,0)*(size-1));
        Vector2Int otherStartEdgeA = new Vector2Int(Mathf.Max(-edgeNormal.x,0)*(size-1), Mathf.Max(-edgeNormal.y,0)*(size-1));
        Vector2Int edgeTangent = new Vector2Int(Mathf.Abs(edgeNormal.y), Mathf.Abs(edgeNormal.x));
        for (int i=0;i<size;i++ ) {
            Vector2Int edgeA = startEdgeA + edgeTangent*i;
            Vector2Int edgeB = otherStartEdgeA + edgeTangent*i;
            if (!generator.IsValidNeighbor(GetSubTile(edgeA), other.GetSubTile(edgeB))) {
                return false;
            }
        }
        return true;
    }
    public virtual bool CanPlace(MapGenerator generator, MapGenerator.MapGrid grid, int px, int py) {
        if (!CanPlace(generator, px, py, grid.GetTile(px+1,py).tile, px+1, py)) {
            return false;
        }
        if (!CanPlace(generator, px, py, grid.GetTile(px-1,py).tile, px-1, py)) {
            return false;
        }
        if (!CanPlace(generator, px, py, grid.GetTile(px,py+1).tile, px, py+1)) {
            return false;
        }
        if (!CanPlace(generator, px, py, grid.GetTile(px,py-1).tile, px, py-1)) {
            return false;
        }
        return true;
    }
    public virtual void Place(MapGenerator.GridMapTile targetTile, Transform parentTransform) {
        GameObject p = GameObject.Instantiate(prefab, parentTransform);
        p.transform.localPosition = new Vector3((float)targetTile.x*2.5f*size,0f,(float)targetTile.y*2.5f*size);
        p.transform.localRotation = Quaternion.AngleAxis(rotationAngle, Vector3.up);// * Quaternion.AngleAxis(-90f,Vector3.right);
        targetTile.tile = this;
        targetTile.spawnedPrefabs.Add(p);
    }
}
