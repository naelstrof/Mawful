using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class WeaponProgressPanel : MonoBehaviour {
    [SerializeField]
    private Sprite onSprite;
    [SerializeField]
    private Sprite offSprite;
    [SerializeField]
    private Transform targetSpriteSpawn;
    [SerializeField]
    private Image weaponImage;
    private List<Image> availableUpgradeSprites;
    public void Setup(Weapon targetWeapon) {
        weaponImage.sprite = targetWeapon.weaponCard.icon;
        // Reset
        if (availableUpgradeSprites == null) {
            availableUpgradeSprites = new List<Image>();
        }
        foreach(Image image in availableUpgradeSprites) {
            Destroy(image.gameObject);
        }
        availableUpgradeSprites.Clear();

        // Full respawn
        for(int i=availableUpgradeSprites.Count;i<targetWeapon.GetUpgradeTotal();i++) {
            GameObject obj = new GameObject(targetWeapon.name + " upgrade", typeof(Image));
            obj.transform.SetParent(targetSpriteSpawn);
            availableUpgradeSprites.Add(obj.GetComponent<Image>());
        }
        // Set sprites
        for(int i=0;i<targetWeapon.GetUpgradeTotal();i++) {
            if (i < targetWeapon.GetUpgradeLevel()) {
                availableUpgradeSprites[i].sprite = onSprite;
            } else {
                availableUpgradeSprites[i].sprite = offSprite;
            }
        }
    }
}
