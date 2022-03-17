using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "Enemy Swarm Wave", menuName = "VoreGame/Enemy Swarm Wave", order = 1)]
public class EnemySwarmSpawn : EnemyWave {
    [SerializeField]
    private List<GameObject> enemiesToSpawn;
    private List<EnemyPool> enemyPools;

    [SerializeField]
    private float waveDuration;
    [SerializeField]
    private int spawnCount;
    [SerializeField]
    private int swarmCount = 3;
    private int currentSpawn;
    private int currentSwarm;
    private WaitForSeconds waitInterval;

    public override void OnWaveStart(EnemyWaveManager manager) {
        enemyPools = new List<EnemyPool>();
        foreach(GameObject prefab in enemiesToSpawn) {
            enemyPools.Add(PoolManager.GetEnemyPool(prefab));
        }
        currentSpawn = 0;
        currentSwarm = 0;
        waitInterval = new WaitForSeconds(waveDuration/(float)spawnCount);
        base.OnWaveStart(manager);
    }
    protected override IEnumerator OnWaveUpdate() {
        while(!running) {
            yield return null;
        }
        while(currentSwarm++ < swarmCount) {
            Vector3 pos = GetValidOffscreenSpawnPosition();
            int pathSelect = 1;
            if (pos.x < PlayerCharacter.playerPosition.x && pos.z < PlayerCharacter.playerPosition.z) {
                pathSelect = 4;
            } else if (pos.x >= PlayerCharacter.playerPosition.x && pos.z < PlayerCharacter.playerPosition.z) {
                pathSelect = 3;
            } else if (pos.x < PlayerCharacter.playerPosition.x && pos.z >= PlayerCharacter.playerPosition.z) {
                pathSelect = 2;
            } else if (pos.x >= PlayerCharacter.playerPosition.x && pos.z >= PlayerCharacter.playerPosition.z) {
                pathSelect = 1;
            }
            while (currentSpawn++<spawnCount) {
                Character character;
                enemyPools[UnityEngine.Random.Range(0,enemyPools.Count)].TryInstantiate(out character);
                character.SetPositionAndVelocity(pos, Vector3.zero);
                (character as EnemySwarmer).pathChoice = pathSelect;
                yield return waitInterval;
            }
            currentSpawn = 0;
            yield return null;
        }
        OnWaveEnd();
    }
}
