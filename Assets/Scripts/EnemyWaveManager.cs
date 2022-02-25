using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyWaveManager : MonoBehaviour {
    [SerializeField]
    private List<EnemyWave> waves = new List<EnemyWave>();
    private int currentWave = 0;
    void Start() {
        WorldGrid.instance.worldPathReady += OnWorldPathReady;
    }

    void OnDestroy() {
        WorldGrid.instance.worldPathReady -= OnWorldPathReady;
    }

    void OnWorldPathReady() {
        waves[currentWave].waveEnded += NextWave;
        waves[currentWave].OnWaveStart(this);
    }

    void NextWave() {
        waves[currentWave].waveEnded -= NextWave;
        currentWave++;
        waves[currentWave].waveEnded += NextWave;
        waves[currentWave].OnWaveStart(this);
    }
}
