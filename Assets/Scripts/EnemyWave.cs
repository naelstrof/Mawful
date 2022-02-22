using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EnemyWave : ScriptableObject {
    public delegate void EnemyWaveAction();
    public EnemyWaveAction waveEnded;
    protected bool running = false;
    public virtual void OnWaveStart(EnemyWaveManager manager) {
        Debug.Log("EnemyWave :: Staring wave " + name);
        running = true;
        Pauser.pauseChanged += OnPause;
        manager.StartCoroutine(OnWaveUpdate());
    }
    protected void OnPause(bool paused) {
        running = !paused;
    }
    protected virtual IEnumerator OnWaveUpdate() {
        yield return null;
        OnWaveEnd();
    }
    protected virtual void OnWaveEnd() {
        Debug.Log("EnemyWave :: Finished wave " + name);
        Pauser.pauseChanged -= OnPause;
        running = false;
        waveEnded?.Invoke();
    }
    protected Vector3 GetValidOffscreenSpawnPosition() {
        float totalChoices = 0f;
        var pathGrid = WorldGrid.GetPathGrid();
        for(int x=0;x<pathGrid.Count;x++) {
            for(int y=0;y<pathGrid[x].Count;y++) {
                if (pathGrid[x][y] == null) {
                    continue;
                }
                Vector3 screenPoint = CameraFollower.GetCamera().WorldToScreenPoint(pathGrid[x][y].worldPosition);
                bool onScreen = screenPoint.x > 0f && screenPoint.x < Screen.width && screenPoint.y > 0f && screenPoint.y < Screen.height;
                if (pathGrid[x][y].passable && pathGrid[x][y].visited && !onScreen) {
                    float distanceToPlayer = Vector3.Distance(PlayerCharacter.playerPosition, pathGrid[x][y].worldPosition);
                    totalChoices += Mathf.Max(50f-distanceToPlayer*2f, 0.01f);
                }
            }
        }

        float randomChoice = UnityEngine.Random.Range(0f,totalChoices);
        float currentChoice = 0f;
        for(int x=0;x<pathGrid.Count;x++) {
            for(int y=0;y<pathGrid[x].Count;y++) {
                if (pathGrid[x][y] == null) {
                    continue;
                }
                Vector3 screenPoint = CameraFollower.GetCamera().WorldToScreenPoint(pathGrid[x][y].worldPosition);
                bool onScreen = screenPoint.x > 0f && screenPoint.x < Screen.width && screenPoint.y > 0f && screenPoint.y < Screen.height;
                if (pathGrid[x][y].passable && pathGrid[x][y].visited && !onScreen) {
                    float distanceToPlayer = Vector3.Distance(PlayerCharacter.playerPosition, pathGrid[x][y].worldPosition);
                    currentChoice += Mathf.Max(50f-distanceToPlayer*2f, 0.01f);
                    if (currentChoice >= randomChoice) {
                        return pathGrid[x][y].worldPosition;
                    }
                }
            }
        }
        return Vector3.zero;
    }
}
