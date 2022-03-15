using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MetaUpgradePanel : MonoBehaviour {
    [SerializeField]
    private Sprite onSprite;
    [SerializeField]
    private Sprite offSprite;
    [SerializeField]
    private Transform targetSpriteSpawn;
    [SerializeField]
    private Image weaponImage;
    [SerializeField]
    private Image costImage;
    [SerializeField]
    private TMPro.TMP_Text costText;
    private List<Image> availableUpgradeSprites;
    public void Setup(MetaUpgrade targetUpgrade) {
        weaponImage.sprite = targetUpgrade.sprite;
        // Reset
        if (availableUpgradeSprites == null) {
            availableUpgradeSprites = new List<Image>();
        }
        foreach(Image image in availableUpgradeSprites) {
            Destroy(image.gameObject);
        }
        availableUpgradeSprites.Clear();

        // Full respawn
        for(int i=0;i<targetUpgrade.max;i++) {
            GameObject obj = new GameObject(targetUpgrade.name + " upgrade", typeof(Image));
            obj.transform.SetParent(targetSpriteSpawn);
            availableUpgradeSprites.Add(obj.GetComponent<Image>());
        }
        // Set sprites
        for(int i=0;i<targetUpgrade.max;i++) {
            if (i < targetUpgrade.value) {
                availableUpgradeSprites[i].sprite = onSprite;
            } else {
                availableUpgradeSprites[i].sprite = offSprite;
            }
        }
        costImage.sprite = targetUpgrade.resource.characterSprite;
        costText.text = "("+targetUpgrade.GetCost().ToString()+")";
    }
}
