using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Unity.Mathematics;

public class WorldGrid : MonoBehaviour {
    public delegate void WorldPathReadyAction(List<List<PathGridElement>> pathGrid);
    public event WorldPathReadyAction worldPathReady;
    [SerializeField]
    private MapGenerator mapGeneration;
    private Bounds bounds;
    private Coroutine pathRoutine;
    public Bounds worldBounds => instance.bounds;
    public static WorldGrid instance;
    public BoxCollider pathCollider => instance.boxCollider;
    public BoxCollider boxCollider;
    public bool debugBox = false;
    [Range(1f,10f)]
    public float collisionGridSize = 2f;
    public float pathGridSize = 5f;
    public delegate void CharacterAction(Character character);
    private List<List<CollisionGridElement>> collisionGrid = new List<List<CollisionGridElement>>();
    private List<List<PathGridElement>> pathGrid = new List<List<PathGridElement>>();
    private static Collider[] staticColliders = new Collider[4];
    private HashSet<PathGridElement> openGraph;
    private PathGridElement lastElement;
    //private  HashSet<GridElement> closedGraph;
    public List<List<PathGridElement>> GetPathGrid() => pathGrid;
    public class GridElement {
        public float gridSize;
        public Vector3 worldPosition {
            get { return new Vector3(position.x, position.y, position.z)*gridSize; }
        }
        public int3 position;
        public virtual void Initialize(int3 pos, float gridSize) {
            this.position = pos;
            this.gridSize = gridSize;
        }
        public override int GetHashCode() {
            return position.GetHashCode();
        }
        public override bool Equals(object obj) {
            return obj.GetHashCode() == GetHashCode();
        }
    }
    public class CollisionGridElement : GridElement {
        public HashSet<Character> charactersInElement;
        public override void Initialize(int3 pos, float gridSize) {
            base.Initialize(pos, gridSize);
            charactersInElement = new HashSet<Character>();
        }
    }
    public class PathGridElement : GridElement {
        public bool passable;
        public bool visited;
        public GridElement cameFrom;
        public override void Initialize(int3 pos, float gridSize) {
            base.Initialize(pos, gridSize);
            passable = Physics.OverlapBoxNonAlloc(new Vector3(pos.x,pos.y,pos.z)*gridSize, Vector3.one*0.5f*gridSize, staticColliders, Quaternion.identity, LayerMask.GetMask("World"), QueryTriggerInteraction.Ignore) == 0;
            visited = false;
            cameFrom = null;
        }
        public void Refresh() {
            passable = Physics.OverlapBoxNonAlloc(new Vector3(position.x,position.y,position.z)*gridSize, Vector3.one*0.5f*gridSize, staticColliders, Quaternion.identity, LayerMask.GetMask("World"), QueryTriggerInteraction.Ignore) == 0;
        }
        public override int GetHashCode() {
            return position.GetHashCode();
        }
        public override bool Equals(object obj) {
            return obj.GetHashCode() == GetHashCode();
        }
    }
    public Vector3 GetPathTowardsPlayer(Vector3 fromPosition) {
        PathGridElement element = GetElement<PathGridElement>(fromPosition, pathGrid, pathGridSize);
        if (element.cameFrom == null) {
            return (fromPosition-element.worldPosition).normalized;
        }
        if (element == lastElement) {
            return (PlayerCharacter.playerPosition - fromPosition).normalized;
        }
        return (element.cameFrom.worldPosition-element.worldPosition).normalized;
    }
    private void PrimeGrid<T>(int count, List<List<T>> grid, float gridSize) where T : GridElement, new() {
        grid.Clear();
        for(int x=0;x<count;x++) {
            grid.Add(new List<T>());
            for(int y=0;y<count;y++) {
                T element = new T();
                element.Initialize(new int3(x,0,y), gridSize);
                grid[x].Add(element);
            }
        }
    }
    public CollisionGridElement GetCollisionGridElement(int x, int y) {
        return collisionGrid[x][y];
    }
    public PathGridElement GetPathGridElement(int x, int y) {
        return pathGrid[x][y];
    }
    public  PathGridElement GetPathGridElement(Vector3 position) {
        return GetElement<PathGridElement>(position, pathGrid, pathGridSize);
    }
    private T GetElement<T>(Vector3 position, List<List<T>> grid, float gridSize) where T : GridElement, new() {
        int x = Mathf.RoundToInt(position.x/gridSize);
        int y = Mathf.RoundToInt(position.z/gridSize);

        /*for (int i=grid.Count;i<=x;i++) {
            grid.Add(new List<T>());
        }
        for (int i=grid[x].Count;i<=y;i++) {
            T newElement = new T();
            newElement.Initialize(new int3(x,0,i), gridSize);
            grid[x].Add(newElement);
        }*/

        return grid[x][y];
    }
    void Awake() {
        instance = this;
    }
    void Start() {
        collisionGrid = new List<List<CollisionGridElement>>();
        pathGrid = new List<List<PathGridElement>>();
        openGraph = new HashSet<PathGridElement>();
        boxCollider.size = Vector3.one*pathGridSize;
        lastElement = null;
        PrimeGrid<PathGridElement>(40, pathGrid, pathGridSize);
        PrimeGrid<CollisionGridElement>(100, collisionGrid, collisionGridSize);
        bounds = new Bounds((Vector3.forward+Vector3.right)*Mathf.Max(pathGridSize, collisionGridSize), Vector3.up);
        float width = Mathf.Min((pathGrid.Count-2)*pathGridSize, (collisionGrid.Count-2)*collisionGridSize);
        float height = Mathf.Min((pathGrid[0].Count-2)*pathGridSize, (collisionGrid[0].Count-2)*collisionGridSize);
        bounds.Encapsulate(Vector3.right*width + Vector3.forward*height);
        mapGeneration.generationFinished += OnMapGenerationComplete;
    }
    void OnMapGenerationComplete(MapGenerator.MapGrid grid) {
        // Update colliders
        for(int x=0;x<pathGrid.Count;x++) {
            if (pathGrid[x] == null) {
                continue;
            }
            for(int y=0;y<pathGrid[x].Count;y++) {
                if (pathGrid[x][y] == null) {
                    continue;
                }
                pathGrid[x][y].Refresh();
            }
        }
        DeterminePlayableArea();
        worldPathReady?.Invoke(pathGrid);
        TryUpdatePaths(true);
    }
    void OnDestroy() {
        if (mapGeneration != null) {
            mapGeneration.generationFinished -= OnMapGenerationComplete;
        }
        collisionGrid.Clear();
        pathGrid.Clear();
    }
    private HashSet<PathGridElement> FloodFill(PathGridElement center) {
        HashSet<PathGridElement> flood = new HashSet<PathGridElement>();

        // Just chew through it immediately. 
        IEnumerator blah = ProcessPaths(center);
        while(blah.MoveNext()) {}

        foreach(List<PathGridElement> row in pathGrid) {
            foreach(PathGridElement element in row) {
                if (!element.visited) { continue; }
                flood.Add(element);
            }
        }
        return flood;
    }
    private void DeterminePlayableArea() {
        HashSet<PathGridElement> notFloodedSet = new HashSet<PathGridElement>();
        foreach(List<PathGridElement> row in pathGrid) {
            foreach(PathGridElement element in row) {
                if (!element.passable) { continue; }
                notFloodedSet.Add(element);
            }
        }
        List<HashSet<PathGridElement>> floods = new List<HashSet<PathGridElement>>();
        while (notFloodedSet.Count > 0) {
            int random = UnityEngine.Random.Range(0,notFloodedSet.Count);
            PathGridElement element = null;
            int i = 0;
            foreach(PathGridElement find in notFloodedSet) {
                element = find;
                if (i++==random) {
                    break;
                }
            }
            HashSet<PathGridElement> flooded = FloodFill(element);
            notFloodedSet.ExceptWith(flooded);
            floods.Add(flooded);
        }
        floods.Sort((a,b)=>{return b.Count.CompareTo(a.Count);});

        // Set all smaller enclosures as impassable, fill them as solid
        for(int i=1;i<floods.Count;i++) {
            foreach(PathGridElement element in floods[i]) {
                element.passable = false;
            }
        }
    }
    private IEnumerator ProcessPaths(PathGridElement center) {
        foreach(List<PathGridElement> row in pathGrid) {
            foreach(PathGridElement element in row) {
                element.visited = false;
            }
        }
        openGraph.Clear();
        openGraph.Add(center);
        int graphFramesProcessed = 0;
        while (openGraph.Count > 0) {
            int random = UnityEngine.Random.Range(0,openGraph.Count);
            PathGridElement element = null;
            int i = 0;
            foreach(PathGridElement find in openGraph) {
                element = find;
                if (i++==random) {
                    break;
                }
            }
            //GridElement element = openGraph[UnityEngine.Random.Range(0,openGraph.Count)];
            for (int x = element.position.x-1;x<=element.position.x+1;x++) {
                for (int y = element.position.z-1;y<=element.position.z+1;y++) {
                    if (x < 0 || x >= pathGrid.Count || y < 0 || y >= pathGrid[x].Count) {
                        continue;
                    }
                    PathGridElement target = pathGrid[x][y];
                    int xdiff = x-element.position.x;
                    int ydiff = y-element.position.z;
                    // If we're diagonal, we need to make sure not to path through "pinches"
                    if (xdiff != 0 && ydiff != 0) {
                        if (!pathGrid[x][y-ydiff].passable && !pathGrid[x-xdiff][y].passable) {
                            continue;
                        }
                    }
                    if ( !openGraph.Contains(target) && !target.visited && target.passable ) {
                        target.cameFrom = element;
                        openGraph.Add(target);
                    }
                }
            }
            openGraph.Remove(element);
            element.visited = true;
            if (graphFramesProcessed++%50 == 0) { yield return null; }
        }
    }
    public HashSet<Character> GetCharactersInCell(Vector3 position) {
        return GetElement<CollisionGridElement>(position, collisionGrid, collisionGridSize).charactersInElement;
    }
    void FixedUpdate() {
        foreach(List<CollisionGridElement> row in collisionGrid) {
            foreach(CollisionGridElement element in row) {
                element.charactersInElement.Clear();
            }
        }
        foreach(Character character in Character.characters) {
            GetElement<CollisionGridElement>(character.position, collisionGrid, collisionGridSize).charactersInElement.Add(character);
        }
        TryUpdatePaths(false);
    }
    void TryUpdatePaths(bool force) {
        if (PlayerCharacter.player == null) {
            return;
        }
        PathGridElement center = GetElement<PathGridElement>(PlayerCharacter.playerPosition, pathGrid, pathGridSize);
        if (center == null) {
            return;
        }
        if (force || lastElement == null || center != lastElement) {
            if (instance.pathRoutine != null) {
                instance.StopCoroutine(instance.pathRoutine);
            }
            instance.pathRoutine = instance.StartCoroutine(ProcessPaths(center));
            lastElement = center;
        }
    }
    void OnDrawGizmosSelected() {
        if (collisionGrid == null) {
            return;
        }
        Gizmos.color = Color.green;
        Gizmos.DrawWireCube(bounds.center, bounds.size);
        foreach(List<PathGridElement> row in pathGrid) {
            foreach(PathGridElement element in row) {
                if (element == null) {
                    continue;
                }
                Gizmos.color = element.passable ? Color.blue : Color.red;
                if (debugBox && !element.passable) {
                    Gizmos.DrawCube(element.worldPosition, Vector3.one*pathGridSize);
                }
                if (element.cameFrom == null) {
                    continue;
                }
                //Gizmos.color = Color.Lerp(new Color(0f,0f,1f,0.1f), Color.red, Mathf.Clamp01(((float)element.pathCost)/10f));
                Vector3 dir = (element.worldPosition-element.cameFrom.worldPosition).normalized;
                Gizmos.DrawLine(element.worldPosition-dir*0.25f, element.worldPosition+dir*0.5f);
            }
        }
    }
}
