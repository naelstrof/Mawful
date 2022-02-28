using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelHandler : MonoBehaviour {
    public enum LoadingType {
        MainMenu,
        Level,
    }
    public LoadingType type;
    [SerializeField]
    private CanvasGroup loadingPanel;
    private static bool loading;
    private static LevelHandler instance;
    void Awake() {
        instance = this;
    }
    void Start() {
        if (type == LoadingType.MainMenu) {
            loadingPanel.alpha = 0f;
            loadingPanel.interactable = false;
            loadingPanel.blocksRaycasts = false;
            return;
        }
        loadingPanel.alpha = 1f;
        loadingPanel.interactable = true;
        loadingPanel.blocksRaycasts = true;
        WorldGrid.instance.worldPathReady += OnWorldPathReady;
    }
    void OnWorldPathReady() {
        loadingPanel.alpha = 0f;
        loadingPanel.interactable = false;
        loadingPanel.blocksRaycasts = false;
        WorldGrid.instance.worldPathReady -= OnWorldPathReady;
    }
    public static void StartLevelStatic(string name) {
        instance.StartLevel(name);
    }
    public void StartLevel(string name) {
        if (loading) {
            return;
        }
        loading = true;
        loadingPanel.alpha = 1f;
        loadingPanel.interactable = true;
        loadingPanel.blocksRaycasts = true;
        AsyncOperation op = SceneManager.LoadSceneAsync(name, LoadSceneMode.Single);
        op.completed += (AsyncOperation o) => {
            loading = false;
            if (loadingPanel == null) {
                return;
            }
            loadingPanel.interactable = false;
            loadingPanel.blocksRaycasts = false;
            loadingPanel.alpha = 0f;
            MainMenuShower.ShowMainMenu(false);
        };
    }
}
