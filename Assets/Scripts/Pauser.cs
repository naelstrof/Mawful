using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class Pauser {
    private static bool paused = false;
    public delegate void PauseAction(bool paused);
    public static event PauseAction pauseChanged;
    public static void SetPaused(bool newPause) {
        if (newPause == paused) {
            return;
        }
        paused = newPause;
        pauseChanged?.Invoke(newPause);
    }
}
