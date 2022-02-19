using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;

[CustomEditor(typeof(MapGenerator))]
public class MapGeneratorEditor : Editor {
    public override void OnInspectorGUI() {
        MapGenerator gen = (MapGenerator)target;
        SerializedProperty validNeighbors = serializedObject.FindProperty("validNeighbors");
        for (int i=validNeighbors.arraySize;i<gen.possibleTiles.Count*gen.possibleTiles.Count;i++) {
            validNeighbors.InsertArrayElementAtIndex(Mathf.Max(validNeighbors.arraySize-1,0));
        }

        EditorGUI.BeginChangeCheck();
        for(int y=0;y<gen.possibleTiles.Count;y++) {
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(gen.possibleTiles[y] == null ? "" : gen.possibleTiles[y].name, GUILayout.MaxWidth(128f));
            for(int x=0;x<gen.possibleTiles.Count;x++) {
                int ind = x+y*gen.possibleTiles.Count;
                if (x>y) {
                    EditorGUI.BeginDisabledGroup(true);
                    validNeighbors.GetArrayElementAtIndex(ind).boolValue =  EditorGUILayout.Toggle(validNeighbors.GetArrayElementAtIndex(ind).boolValue, GUILayout.MaxWidth(100f));
                    EditorGUI.EndDisabledGroup();
                    continue;
                }
                validNeighbors.GetArrayElementAtIndex(ind).boolValue =  EditorGUILayout.Toggle(validNeighbors.GetArrayElementAtIndex(ind).boolValue, GUILayout.MaxWidth(100f));
            }
            EditorGUILayout.EndHorizontal();
        }
        EditorGUILayout.BeginHorizontal();
        EditorGUILayout.LabelField("", GUILayout.MaxWidth(128f));
        for(int y=0;y<gen.possibleTiles.Count;y++) {
            EditorGUILayout.LabelField(gen.possibleTiles[y] == null ? "" : gen.possibleTiles[y].name, GUILayout.MaxWidth(100f));
        }
        EditorGUILayout.EndHorizontal();
        EditorGUI.EndChangeCheck();
        serializedObject.ApplyModifiedProperties();
        DrawDefaultInspector();
    }
}
#endif

public class MapGenerator : MonoBehaviour {
    [SerializeField]
    private List<bool> validNeighbors;
    public class GridMapTile {
        public GridMapTile(int x, int y) {
            this.x = x;
            this.y = y;
            tile = null;
            tileProbabilities = new ProbabilitySet();
            spawnedPrefabs = new HashSet<GameObject>();
        }
        public void ZeroProbabilities() {
            foreach(var key in tileProbabilities.Keys) {
                tileProbabilities[key].probability = 0f;
            }
        }
        public void MultiplyProbabilities(ProbabilitySet other, float weight) {
            float sum = 0f;
            foreach(var pair in other) {
                tileProbabilities[pair.Key].probability = Mathf.Lerp(tileProbabilities[pair.Key].probability, tileProbabilities[pair.Key].probability*pair.Value.probability, weight);
                sum += tileProbabilities[pair.Key].probability;
            }

            // Must select something...
            if (sum == 0) {
                foreach(var pair in other) {
                    tileProbabilities[pair.Key].probability += UnityEngine.Random.Range(0f,1f);
                    sum += tileProbabilities[pair.Key].probability;
                }
            }
            // Re-Normalize
            foreach(var pair in other) {
                tileProbabilities[pair.Key].probability = tileProbabilities[pair.Key].probability/sum;
            }
        }
        public int x, y;
        public float rotation;
        public MapTile tile;
        public class ProbabilitySet : Dictionary<MapTile, Probability> {
            // Similar values mean that we don't really know what to place, stability is a measure of how much we know we should place something!
            // Opposite of entropy
            public float stability {
                get {
                    float averageValue = 0f;
                    int count = 0;
                    foreach(var pair in this) {
                        averageValue += pair.Value.probability;
                        count++;
                    }
                    float sum = averageValue;
                    averageValue /= Mathf.Max(count,1);

                    float averageDiff = 0f;
                    foreach(var pair in this) {
                        averageDiff += Mathf.Abs(pair.Value.probability-averageValue);
                    }
                    return averageDiff/Mathf.Max(sum,0.001f);
                }
            }
            public override string ToString() {
                string blah = "Probability Set Stability " + stability.ToString() + "\n";
                foreach( var pair in this) {
                    blah += pair.Key.ToString();
                    blah += " :: ";
                    blah += pair.Value.probability.ToString() + "\n";
                }
                return blah;
            }
        }
        public class Probability {
            public Probability(float prob) {
                probability = prob;
            }
            public float probability;
        }
        public ProbabilitySet tileProbabilities;
        public HashSet<GameObject> spawnedPrefabs;
    }
    public bool IsValidNeighbor(MapTileEdge a, MapTileEdge b) {
        if (a == null || b == null) {
            return true;
        }
        int x = possibleTiles.IndexOf(a);
        int y = possibleTiles.IndexOf(b);
        return validNeighbors[x + y * possibleTiles.Count];
    }
    [SerializeField]
    public List<MapTileEdge> possibleTiles;
    private HashSet<GridMapTile> undecidedSet;
    private List<GridMapTile> grid;
    private void SetTile(int x, int y, GridMapTile tile) {
        int select = Mathf.Clamp(x,0,width-1)+(Mathf.Clamp(y,0,height-1)*width);
        grid[select] = tile;
    }
    public GridMapTile GetTile(int x, int y) {
        int select = Mathf.Clamp(x,0,width-1)+(Mathf.Clamp(y,0,height-1)*width);
        return grid[select];
    }
    public MapTileEdge GetSubTile(int sx, int sy) {
        int select = Mathf.Clamp(sx/2,0,width-1)+(Mathf.Clamp(sy/2,0,height-1)*width);
        int offsetX = Mathf.Max(sx,0) % 2;
        int offsetY = Mathf.Max(sy,0) % 2;
        if (grid[select].tile == null) {
            return null;
        }
        return grid[select].tile.GetSubTile(offsetX,offsetY,grid[select].rotation);
    }
    [SerializeField]
    private List<MapTile> mapTiles;
    [SerializeField]
    public int width;
    [SerializeField]
    public int height;
    void Start() {
        // Create unintialized grid
        grid = new List<GridMapTile>();
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                grid.Add(null);
            }
        }
        // Zero it
        undecidedSet = new HashSet<GridMapTile>();
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                SetTile(x,y,new GridMapTile(x,y));
                undecidedSet.Add(GetTile(x,y));
            }
        }
        // Fill it full of possible choices
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                GetTile(x,y).tileProbabilities = FindChoicesForPoint(x,y,mapTiles);
            }
        }
        Prime();
        StartCoroutine(Solve());
    }
    bool HasValidPlacement() {
        foreach(GridMapTile t in undecidedSet) {
            foreach(var pair in t.tileProbabilities) {
                if (pair.Value.probability*t.tileProbabilities.stability> 0f) {
                    return true;
                }
            }
        }
        return false;
    }
    float GetTotalChoices() {
        float choices = 0;
        foreach(GridMapTile t in undecidedSet) {
            foreach(var pair in t.tileProbabilities) {
                choices += pair.Value.probability*t.tileProbabilities.stability;
            }
        }
        return choices;
    }
    void ApplyChoice(float which) {
        // Find the choice
        float currentChoice = 0;
        GridMapTile selectedGridPoint = null;
        MapTile selectedPlacement = null;
        foreach(GridMapTile t in undecidedSet) {
            foreach(var pair in t.tileProbabilities) {
                currentChoice += pair.Value.probability*t.tileProbabilities.stability;
                if (currentChoice >= which) {
                    selectedGridPoint = t;
                    selectedPlacement = pair.Key;
                    break;
                }
            }
            if (currentChoice > which) {
                break;
            }
        }
        // Place at random valid rotation
        selectedPlacement.Place(this, selectedGridPoint.x, selectedGridPoint.y);
        // Update the surrounding possible tiles
        UpdatePossibles(selectedGridPoint.x, selectedGridPoint.y);
    }
    void UpdatePossibles(int px, int py) {
        GridMapTile tile = GetTile(px,py);
        if (tile.tile == null) {
            tile.tileProbabilities = FindChoicesForPoint(px,py, mapTiles);
            return;
        }
        tile.ZeroProbabilities();
        UpdatePossibles(px+1, py,   tile.x, tile.y, tile.rotation, tile.tile, 1, 1f);
        UpdatePossibles(px-1, py,   tile.x, tile.y, tile.rotation, tile.tile, 1, 1f);
        UpdatePossibles(px,   py-1, tile.x, tile.y, tile.rotation, tile.tile, 1, 1f);
        UpdatePossibles(px,   py+1, tile.x, tile.y, tile.rotation, tile.tile, 1, 1f);
    }
    void UpdatePossibles(int px, int py, int lastx, int lasty, float lastRot, MapTile lastTile, int iterations, float weight) {
        if (px < 0 || px >= width || py < 0 || py >= height) {
            return;
        }
        if (GetTile(px,py).tile != null) {
            //GetTile(px,py).ZeroProbabilities();
            return;
        }
        GridMapTile.ProbabilitySet probabilities = new GridMapTile.ProbabilitySet();
        int count = 0;
        foreach(MapTile testTile in mapTiles) {
            probabilities[testTile] = new GridMapTile.Probability(0f);
            for(float rot = 0f;rot<361f;rot+=90f) {
                if (testTile.CanPlace(this, px, py, rot, lastTile, lastx, lasty, lastRot)) {
                    if (iterations > 0) {
                        int xdir = px-lastx;
                        if (xdir != 0) {
                            UpdatePossibles(px+xdir, py, px, py, rot, testTile, iterations-1, weight*0.5f);
                        }
                        int ydir = py-lasty;
                        if (ydir != 0) {
                            UpdatePossibles(px, py+ydir, px, py, rot, testTile, iterations-1, weight*0.5f);
                        }
                    }
                    probabilities[testTile].probability += 1f;
                    count++;
                }
            }
        }
        foreach(var pair in probabilities) {
            pair.Value.probability /= Mathf.Max(count,1);
        }
        GetTile(px,py).MultiplyProbabilities(probabilities, weight);
    }
    GridMapTile.ProbabilitySet FindChoicesForPoint(int x, int y, IEnumerable<MapTile> testTiles) {
        GridMapTile.ProbabilitySet probabilities = new GridMapTile.ProbabilitySet();
        int count = 0;
        foreach(MapTile tile in testTiles) {
            if (tile.CanPlace(this,x,y)) {
                probabilities.Add(tile, new GridMapTile.Probability(tile.initialProbability));
                count++;
            } else {
                probabilities.Add(tile, new GridMapTile.Probability(0f));
            }
        }
        foreach(var pair in probabilities) {
            probabilities[pair.Key].probability /= Mathf.Max(count,1);
        }
        return probabilities;
    }
    /*public void Clear(int x, int y) {
        if (x < 0 || x >= width || y < 0 || y >= height) {
            return;
        }
        GetTile(x,y).tile = null;
        GetTile(x,y).rotation = 0f;
        undecidedSet.Add(GetTile(x,y));
        foreach(GameObject g in GetTile(x,y).spawnedPrefabs) {
            Destroy(g);
        }
        GetTile(x,y).spawnedPrefabs.Clear();
        GetTile(x,y).tileProbabilities = FindChoicesForPoint(x,y,mapTiles);
    }*/
    void Prime() {
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                if (x==0 || y == 0 || x==width-1 || y==height-1) {
                    mapTiles[0].Place(this, x, y);
                    UpdatePossibles(x,y);
                }
            }
        }
    }
    /*void BackTrack() {
        // Count our backtrack choices
        int backtrackChoices = 0;
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                if (GetTile(x,y).tile == null) {
                    backtrackChoices++;
                }
            }
        }
        // Randomly pick one
        int randomBackTrackChoice = UnityEngine.Random.Range(0,backtrackChoices);
        int selection = 0;
        GridMapTile selectedTile = null;
        for(int x=0;x<width;x++) {
            for(int y=0;y<height;y++) {
                if (GetTile(x,y).tile == null) {
                    if (selection++ == randomBackTrackChoice) {
                        selectedTile = GetTile(x,y);
                        break;
                    }
                }
            }
            if (selectedTile != null) {
                break;
            }
        }
        if (selectedTile == null) {
            throw new UnityException("Failed to find choice " + randomBackTrackChoice + " out of " + backtrackChoices);
        }
        // Finally execute the backtrack, deleting prefabs, and setting grid points to undecided.
        for(int x=selectedTile.x-1;x<selectedTile.x+2;x++) {
            for(int y=selectedTile.y-1;y<selectedTile.y+2;y++) {
                GetTile(x,y).tile = null;
                GetTile(x,y).rotation = 0f;
                undecidedSet.Add(GetTile(x,y));
                foreach(GameObject g in GetTile(x,y).spawnedPrefabs) {
                    Destroy(g);
                }
                GetTile(x,y).spawnedPrefabs.Clear();
            }
        }
        // Regenerate possible choices
        for(int x=selectedTile.x-2;x<selectedTile.x+2;x++) {
            for(int y=selectedTile.y-2;y<selectedTile.y+2;y++) {
                GetTile(x,y).tileProbabilities = FindChoicesForPoint(x,y, mapTiles);
            }
        }
    }*/
    IEnumerator Solve() {
        while(undecidedSet.Count > 0) {
            float totalChoices = GetTotalChoices();
            float randomChoice = UnityEngine.Random.Range(0f,totalChoices);
            ApplyChoice(randomChoice);
            yield return null;
        }
        Debug.Log("Done!");
    }
    void OnValidate() {
        for(int x=0;x<possibleTiles.Count;x++) {
            for(int y=0;y<possibleTiles.Count;y++) {
                if (x>y) {
                    validNeighbors[x+y*possibleTiles.Count] = validNeighbors[y+x*possibleTiles.Count];
                }
            }
        }
    }
    void OnDrawGizmosSelected() {
        if (grid == null) {
            return;
        }
        for (int x=0;x<width;x++) {
            for (int y=0;y<height;y++) {
                var tile = GetTile(x,y);
                Gizmos.color = Color.Lerp(Color.black, Color.red, Mathf.Clamp01(tile.tileProbabilities.stability));
                Gizmos.DrawCube(new Vector3(x*5f,0,y*5f), Vector3.one);
            }
        }
    }
}
