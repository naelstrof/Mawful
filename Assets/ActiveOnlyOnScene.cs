using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class ActiveOnlyOnScene : MonoBehaviour {
    // Start is called before the first frame update
    void Start() {
        SceneManager.activeSceneChanged += OnSceneChanged;
        gameObject.SetActive(SceneManager.GetActiveScene().name == "MainMenu");
    }
    void OnDestroy() {
        SceneManager.activeSceneChanged -= OnSceneChanged;
    }
    void OnSceneChanged(Scene oldScene, Scene newScene) {
        gameObject.SetActive(newScene.name == "MainMenu");
    }
}
