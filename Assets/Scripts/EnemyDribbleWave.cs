using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Enemy Dribble Wave", menuName = "VoreGame/Enemy Dribble Wave", order = 1)]
public class EnemyDribbleWave : EnemyWave {
    [SerializeField]
    private List<GameObject> enemiesToSpawn;
    private List<EnemyPool> enemyPools;

    [SerializeField]
    private float waveDuration;
    [SerializeField]
    private int spawnCount;
    private int currentSpawn;
    private WaitForSeconds waitInterval;

    public override void OnWaveStart(EnemyWaveManager manager) {
        enemyPools = new List<EnemyPool>();
        foreach(GameObject prefab in enemiesToSpawn) {
            enemyPools.Add(PoolManager.GetEnemyPool(prefab));
        }
        currentSpawn = 0;
        waitInterval = new WaitForSeconds(waveDuration/(float)spawnCount);
        base.OnWaveStart(manager);
    }
    protected override IEnumerator OnWaveUpdate() {
        while(!running) {
            yield return null;
        }
        while (currentSpawn++<spawnCount) {
            EnemyCharacter character;
            enemyPools[UnityEngine.Random.Range(0,enemyPools.Count)].TryInstantiate(out character);
            character.SetPositionAndVelocity(GetValidOffscreenSpawnPosition(), Vector3.zero);
            yield return waitInterval;
        }
        OnWaveEnd();
    }
}
