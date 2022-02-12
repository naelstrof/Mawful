using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemySpawner : MonoBehaviour {
    [SerializeField]
    private int count = 1000;
    [SerializeField]
    private GameObject prefab;
    void Start() {
        for(int i=0;i<count;i++) {
            Vector3 position = new Vector3(UnityEngine.Random.Range(0f,200f), 0f, UnityEngine.Random.Range(0f, 200f));
            position = WorldGrid.worldBounds.ClosestPoint(position);
            EnemyCharacter character;
            EnemyPool.TryInstantiate(out character);
            character.SetPositionAndVelocity(position, Vector3.zero);
        }
    }
}
