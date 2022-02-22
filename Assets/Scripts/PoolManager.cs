using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PoolManager : MonoBehaviour {
    private static PoolManager instance;
    private List<EnemyPool> enemyPools;
    public static EnemyPool GetEnemyPool(GameObject prefab) {
        foreach(EnemyPool pool in instance.enemyPools) {
            if (pool.prefab.gameObject == prefab.gameObject) {
                return pool;
            }
        }
        return null;
    }
    public void Awake() {
        instance = this;
        enemyPools = new List<EnemyPool>(GetComponents<EnemyPool>());
    }
}
