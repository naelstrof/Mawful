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
    public delegate void MapGenerationAction();
    public event MapGenerationAction generationFinished;
    private static Dictionary<GridMapTile, int> tempVisitGraph = new Dictionary<GridMapTile, int>();
    //private static GridMapTile.ProbabilitySet tempProbabilitySet = new GridMapTile.ProbabilitySet();
    [SerializeField] [Range(1,100)]
    private int interationsPerFrame = 100;
    [SerializeField]
    private List<bool> validNeighbors;
    public class GridMapTile {
        public GridMapTile(int x, int y) {
            this.x = x;
            this.y = y;
            neighbors = 0;
            tile = null;
            tileProbabilities = new ProbabilitySet();
            spawnedPrefabs = new HashSet<GameObject>();
        }
        public int x, y;
        public int neighbors;
        public MapTile tile;
        public class ProbabilitySet : Dictionary<MapTile, float> {
            public void Normalize(List<MapTile> tiles) {
                float sum = 0f;
                foreach(float v in this.Values) {
                    sum += v;
                }
                // Re-Normalize
                foreach(var key in tiles) {
                    this[key] /= Mathf.Max(sum,0.00001f);
                }
            }
            // Similar values mean that we don't really know what to place, stability is a measure of how much we know we should place something!
            // Opposite of entropy
            public void UpdateStability() {
                float max = 0f;
                foreach(var pair in this) {
                    max = Mathf.Max(max, pair.Value);
                }
                float diff = 0f;
                foreach(var pair in this) {
                    diff += Mathf.Abs(pair.Value-max);
                }
                float maxDiff = max*(this.Count-1);
                stability = diff/Mathf.Max(maxDiff,0.00001f);
            }
            public float stability;
            public override string ToString() {
                string blah = "Probability Set Stability " + stability.ToString() + "\n";
                foreach( var pair in this) {
                    blah += pair.Key.ToString();
                    blah += " :: ";
                    blah += pair.Value.ToString() + "\n";
                }
                return blah;
            }
        }
        public ProbabilitySet tileProbabilities;
        public HashSet<GameObject> spawnedPrefabs;
    }
    public bool IsValidNeighbor(MapTileEdge a, MapTileEdge b) {
        //int x = possibleTiles.IndexOf(a);
        //int y = possibleTiles.IndexOf(b);
        return validNeighbors[a.validLookupCache + b.validLookupCache * possibleTiles.Count];
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
    [SerializeField]
    private List<MapTile> mapTiles;
    [SerializeField]
    public int width;
    [SerializeField]
    public int height;
    void ExpandChoices() {
        HashSet<MapTile> newTiles = new HashSet<MapTile>();
        foreach(MapTile tile in mapTiles) {
            tile.rotationAngle = 0f;
            tile.probability = tile.GetInitialProbability();
            if (tile.canRotate) {
                tile.probability = tile.GetInitialProbability()*0.25f;
                for(float rot=90f;rot<271f;rot+=90f) {
                    MapTile newTile = MapTile.Instantiate(tile);
                    newTile.name = newTile.name.Substring(0,newTile.name.Length-7)+rot.ToString();
                    newTile.rotationAngle = rot;
                    newTile.ApplyRotation();
                    newTiles.Add(newTile);
                }
            }
        }
        mapTiles.AddRange(newTiles);
    }
    void Start() {
        // Get all our possible rotations
        ExpandChoices();
        // Cache some lookup data
        foreach(MapTileEdge edge in possibleTiles) {
            edge.validLookupCache = possibleTiles.IndexOf(edge);
        }
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
                GetTile(x,y).tileProbabilities = FindChoicesForPoint(x,y);
            }
        }
        //Prime();
        mapTiles[0].Place(this, 0, 0);
        UpdatePossibles(0,0);
        undecidedSet.Remove(GetTile(0,0));
        StartCoroutine(Solve());
    }
    float GetTotalChoices() {
        float choices = 0;
        foreach(GridMapTile t in undecidedSet) {
            if (t.tile != null) {
                continue;
            }
            // Probabilities are almost always normalized. If they're completed zero'd, their stability would also be zero. No need to iterate.
            choices += 1f * t.tileProbabilities.stability * t.neighbors;
            //foreach(var pair in t.tileProbabilities) {
                //choices += pair.Value*t.tileProbabilities.stability*t.neighbors;
            //}
        }
        return choices;
    }
    public void ConfirmPlacement(GridMapTile tile) {
        if (tile.tile == null) {
            Debug.LogError("Failed to place!");
        } else {
            undecidedSet.Remove(tile);
        }
        UpdatePossibles(tile.x, tile.y);

        GetTile(tile.x+1,tile.y).neighbors+=1;
        GetTile(tile.x-1,tile.y).neighbors+=1;
        GetTile(tile.x,tile.y-1).neighbors+=1;
        GetTile(tile.x,tile.y+1).neighbors+=1;
        int neighbors = 0;
        if (GetTile(tile.x+1,tile.y).tile != null) {
            neighbors+=1;
        }
        if (GetTile(tile.x-1,tile.y).tile != null) {
            neighbors+=1;
        }
        if (GetTile(tile.x,tile.y+1).tile != null) {
            neighbors+=1;
        }
        if (GetTile(tile.x,tile.y-1).tile != null) {
            neighbors+=1;
        }
        tile.neighbors = neighbors;
    }
    void ApplyChoice(float which) {
        // Find the choice
        float currentChoice = 0;
        GridMapTile selectedGridPoint = null;
        MapTile selectedPlacement = null;
        foreach(GridMapTile t in undecidedSet) {
            if (t.tile != null) {
                continue;
            }
            foreach(var pair in t.tileProbabilities) {
                currentChoice += pair.Value*t.tileProbabilities.stability*t.neighbors;
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
        //Debug.Log("Placing " + selectedPlacement + " at " + selectedGridPoint.x + ", " + selectedGridPoint.y + " with " + selectedGridPoint.tileProbabilities);
        selectedPlacement.Place(this, selectedGridPoint.x, selectedGridPoint.y);
        // Update the surrounding possible tiles
    }
    void UpdatePossibles(int px, int py) {
        GridMapTile tile = GetTile(px,py);
        if (tile.tile == null) {
            tile.tileProbabilities = FindChoicesForPoint(px,py);
            return;
        }
        tempVisitGraph.Clear();
        tempVisitGraph.Add(tile, -1);
        UpdatePossibles(px+1, py,   tile.x, tile.y, tile.tile, 1, 1f, 1, tempVisitGraph);
        UpdatePossibles(px-1, py,   tile.x, tile.y, tile.tile, 1, 1f, 1, tempVisitGraph);
        UpdatePossibles(px,   py-1, tile.x, tile.y, tile.tile, 1, 1f, 1, tempVisitGraph);
        UpdatePossibles(px,   py+1, tile.x, tile.y, tile.tile, 1, 1f, 1, tempVisitGraph);
    }
    void UpdatePossibles(int px, int py, int lastx, int lasty, MapTile lastTile, int iterations, float weight, int maxIterations, Dictionary<GridMapTile, int> visitGraph) {
        if (px < 0 || px >= width || py < 0 || py >= height) {
            return;
        }
        GridMapTile tile = GetTile(px,py);
        if (tile.tile != null) {
            //GetTile(px,py).ZeroProbabilities();
            return;
        }
        // Already been visited by a parent
        if (visitGraph.ContainsKey(tile) && visitGraph[tile] < maxIterations-iterations) {
            return;
        }

        if (!visitGraph.ContainsKey(tile)) {
            visitGraph.Add(tile, maxIterations-iterations);
        }
        int possibleTiles = 0;
        foreach(MapTile testTile in mapTiles) {
            if (testTile.CanPlace(this, px, py, lastTile, lastx, lasty)) {
                possibleTiles++;
            } else {
                float v = tile.tileProbabilities[testTile];
                v = Mathf.Lerp(v, 0f, weight);
                tile.tileProbabilities[testTile] = v;
            }
        }
        tile.tileProbabilities.Normalize(mapTiles);
        tile.tileProbabilities.UpdateStability();

        foreach(MapTile testTile in mapTiles) {
            if (testTile.CanPlace(this, px, py, lastTile, lastx, lasty)) {
                if (iterations > 0) {
                    UpdatePossibles(px+1, py, px, py, testTile, iterations-1, weight*(1f/(float)possibleTiles), maxIterations, visitGraph);
                    UpdatePossibles(px-1, py, px, py, testTile, iterations-1, weight*(1f/(float)possibleTiles), maxIterations, visitGraph);
                    UpdatePossibles(px, py+1, px, py, testTile, iterations-1, weight*(1f/(float)possibleTiles), maxIterations, visitGraph);
                    UpdatePossibles(px, py-1, px, py, testTile, iterations-1, weight*(1f/(float)possibleTiles), maxIterations, visitGraph);
                }
            }
        }
    }
    GridMapTile.ProbabilitySet FindChoicesForPoint(int x, int y) {
        GridMapTile.ProbabilitySet probabilities = new GridMapTile.ProbabilitySet();
        float sum = 0;
        foreach(MapTile tile in mapTiles) {
            if (tile.CanPlace(this,x,y)) {
                probabilities.Add(tile, tile.probability);
                sum += tile.probability;
            } else {
                probabilities.Add(tile, 0f);
            }
        }
        foreach(var key in mapTiles) {
            probabilities[key] /= Mathf.Max(sum,0.0001f);
        }
        probabilities.UpdateStability();
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
    void BackTrack() {
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
                undecidedSet.Add(GetTile(x,y));
                foreach(GameObject g in GetTile(x,y).spawnedPrefabs) {
                    Destroy(g);
                }
                GetTile(x,y).spawnedPrefabs.Clear();
            }
        }
        // Regenerate possible choices
        for(int x=selectedTile.x-1;x<selectedTile.x+2;x++) {
            for(int y=selectedTile.y-1;y<selectedTile.y+2;y++) {
                GetTile(x,y).tileProbabilities = FindChoicesForPoint(x,y);
            }
        }
    }
    IEnumerator Solve() {
        int interation=0;
        while(undecidedSet.Count > 0) {
            float totalChoices = GetTotalChoices();
            if (totalChoices > 0f) {
                float randomChoice = UnityEngine.Random.Range(0f,totalChoices);
                ApplyChoice(randomChoice);
            } else {
                BackTrack();
            }
            if (interation++%interationsPerFrame == 0) {
                yield return null;
                interation = 1;
            }
        }
        generationFinished?.Invoke();
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
                //Gizmos.color = undecidedSet.Contains(tile)?Color.red:Color.green;
                Gizmos.color = Color.Lerp(Color.black,Color.red,tile.tileProbabilities.stability*tile.tileProbabilities.stability);
                Gizmos.DrawCube(new Vector3(x*5f,0,y*5f), Vector3.one);
            }
        }
    }
}
