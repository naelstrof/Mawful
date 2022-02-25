using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(CanvasGroup))]
public class OnPlayerDie : MonoBehaviour {
    private CanvasGroup group;
    // Start is called before the first frame update
    void Start() {
        group = GetComponent<CanvasGroup>();
        PlayerCharacter.player.health.depleted += OnHealthDepleted;
    }
    void OnHealthDepleted() {
        group.alpha = 1f;
        group.interactable = true;
        group.blocksRaycasts = true;
    }
}
