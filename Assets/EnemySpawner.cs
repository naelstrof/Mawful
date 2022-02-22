using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemySpawner : MonoBehaviour {
    [SerializeField]
    private int count = 1000;
    [SerializeField]
    private EnemyPool kobolds;
    [SerializeField]
    private EnemyPool rats;
    [SerializeField]
    private EnemyPool nagas;
    [SerializeField]
    private EnemyPool slimes;
    [SerializeField]
    private EnemyPool wolves;
    [SerializeField]
    private EnemyPool kangaroos;
    [SerializeField]
    private EnemyPool frennedy;
    [SerializeField]
    private EnemyPool shark;
    void Start() {
        int current = 0;
        for(int i=0;i<count;i++) {
            Vector3 position = new Vector3(UnityEngine.Random.Range(0f,200f), 0f, UnityEngine.Random.Range(0f, 200f));
            position = WorldGrid.worldBounds.ClosestPoint(position);
            EnemyCharacter character;
            switch(current) {
                case 0:
                    kobolds.TryInstantiate(out character); break;
                case 1:
                    rats.TryInstantiate(out character); break;
                case 2:
                    nagas.TryInstantiate(out character); break;
                case 3:
                    slimes.TryInstantiate(out character); break;
                case 4:
                    wolves.TryInstantiate(out character); break;
                case 5:
                    kangaroos.TryInstantiate(out character); break;
                case 6:
                    frennedy.TryInstantiate(out character); break;
                case 7:
                    shark.TryInstantiate(out character); break;
                default:
                    kobolds.TryInstantiate(out character); break;
            }
            character.SetPositionAndVelocity(position, Vector3.zero);
            current = ((++current)%8);
        }
    }
}
