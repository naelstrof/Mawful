using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;

public class LevelHandler : MonoBehaviour {
    [SerializeField]
    private CanvasGroup loadingPanel;
    private static bool loading;
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
        };
    }
}
