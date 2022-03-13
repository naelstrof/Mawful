using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class XPPanelAvailableDisplay : MonoBehaviour {
    [SerializeField]
    private GameObject panelPrefab;
    [SerializeField]
    private List<ScoreCard> possibleXP;
    void Start() {
        foreach(ScoreCard card in possibleXP) {
            GameObject obj = GameObject.Instantiate(panelPrefab, transform);
            obj.transform.Find("Text").GetComponent<TMPro.TMP_Text>().text = Score.GetXP(card).ToString("N0");
            obj.transform.Find("Image").GetComponent<Image>().sprite = card.characterSprite;
        }
    }
}
