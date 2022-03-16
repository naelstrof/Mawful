using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

[RequireComponent(typeof(CanvasGroup))]
public class OnPlayerDie : MonoBehaviour {
    public PlayerCharacter character;
    private CanvasGroup group;
    // Start is called before the first frame update
    void Start() {
        group = GetComponent<CanvasGroup>();
        character.stats.health.depleted += OnHealthDepleted;
    }
    void OnHealthDepleted() {
        group.alpha = 1f;
        group.interactable = true;
        group.blocksRaycasts = true;
        group.GetComponentInChildren<Selectable>().Select();
    }
}
