using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MainMenuShower : MonoBehaviour {
    private static MainMenuShower instance;
    public Selectable selectable;
    public GameObject pauseMenu;
    private bool paused => gameObject.activeInHierarchy;
    void Awake() {
        instance = this;
    }
    void Start() {
        if (WorldGrid.instance != null) {
            WorldGrid.instance.worldPathReady += OnWorldReady;
        }
    }
    void OnDestroy() {
        if (WorldGrid.instance != null) {
            WorldGrid.instance.worldPathReady -= OnWorldReady;
        }
    }
    void Update() {
    }
    void OnWorldReady() {
        ShowMainMenu(false);
    }
    public static void ToggleShow() {
        if (instance == null) {
            Pauser.SetPaused(false);
            return;
        }
        instance.SetShown(!instance.paused);
    }
    public static void ShowMainMenu(bool shown) {
        if (instance == null) {
            Pauser.SetPaused(false);
            return;
        }
        instance.SetShown(shown);
    }
    void SetShown(bool pause) {
        // Can't pause during certain interactions, one of them being if the options is open (which disables the pause menu)
        // Another being if we don't want the player to be able to close/move the menu (like on the main menu).
        if (!pauseMenu.gameObject.activeSelf || !enabled) {
            return;
        }
        if (!gameObject.activeInHierarchy && pause) {
            gameObject.SetActive(true);
            Pauser.SetPaused(true);
            selectable.Select();
        } else if (gameObject.activeInHierarchy && !pause) {
            gameObject.SetActive(false);
            Pauser.SetPaused(false);
        }
    }
}
