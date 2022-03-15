using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class XPPanelAvailableDisplay : MonoBehaviour {
    [SerializeField]
    private GameObject panelPrefab;
    [SerializeField]
    private List<ScoreCard> possibleXP;
    private List<GameObject> things;
    void Start() {
        things = new List<GameObject>();
        foreach(ScoreCard card in possibleXP) {
            GameObject obj = GameObject.Instantiate(panelPrefab, transform);
            obj.transform.Find("Text").GetComponent<TMPro.TMP_Text>().text = Score.GetXP(card).ToString("N0");
            obj.transform.Find("Image").GetComponent<Image>().sprite = card.characterSprite;
            things.Add(obj);
        }
    }
    public void Refresh() {
        foreach(GameObject obj in things) {
            Destroy(obj);
        }
        Start();
    }
}
