using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class QuitHandler : MonoBehaviour {
    public void Quit() {
        if (SceneManager.GetActiveScene().name == "MainMenu") {
#if UNITY_EDITOR
        // Application.Quit() does not work in the editor so
        // UnityEditor.EditorApplication.isPlaying need to be set to false to end the game
        UnityEditor.EditorApplication.isPlaying = false;
#else
         Application.Quit();
#endif
        } else {
            if (Score.GetTotalScore() <= 0f) {
                LevelHandler.StartLevelStatic("MainMenu");
            } else {
                LevelHandler.StartLevelStatic("ScoreScreen");
            }
        }
    }
}
