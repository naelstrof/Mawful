using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Pauser {
    private static bool paused = false;
    public static bool GetPaused() => paused;
    public delegate void PauseAction(bool paused);
    public static event PauseAction pauseChanged;
    private static int pauseCount = 0;
    public static void SetPaused(bool newPause) {
        if (newPause) {
            pauseCount++;
        } else {
            pauseCount = Mathf.Max(0,pauseCount-1);
        }
        bool pauseBuffer = (pauseCount!=0);
        if (pauseBuffer == paused) {
            return;
        }
        paused = pauseBuffer;
        Time.timeScale = paused ? 0f : 1f;
        pauseChanged?.Invoke(paused);
    }
}
