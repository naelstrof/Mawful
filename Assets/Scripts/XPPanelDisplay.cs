using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class XPPanelDisplay : MonoBehaviour {
    [SerializeField]
    private GameObject panelPrefab;
    private Dictionary<ScoreCard, GameObject> panels;
    void Start() {
        panels = new Dictionary<ScoreCard, GameObject>();
    }
    public void AddScore(ScoreCard card) {
        GetComponentInParent<CanvasGroup>().alpha = 1f;
        if (!panels.ContainsKey(card)) {
            panels.Add(card, GameObject.Instantiate(panelPrefab, transform));
            panels[card].transform.Find("Text").GetComponent<TMPro.TMP_Text>().text = "0";
        }
        panels[card].transform.Find("Image").GetComponent<Image>().sprite = card.characterSprite;
        TMPro.TMP_Text text = panels[card].transform.Find("Text").GetComponent<TMPro.TMP_Text>();
        // GARbaGe!! oh well
        int count = int.Parse(text.text);
        count++;
        text.text = count.ToString();
    }
}
