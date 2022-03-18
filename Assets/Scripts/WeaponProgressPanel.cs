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
    [SerializeField]
    private StatsBarSpawner statsSpawner;
    private List<Image> availableUpgradeSprites;
    private bool subcribed;
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
        if (targetWeapon is Passive) {
            return;
        }
        if (!subcribed) {
            statsSpawner.Subscribe(targetWeapon.stats, true);
            subcribed = true;
        }
        Show();
    }
    public void Show() {
        // FIXME: HACK, just need something goddamn enabled around here to do something. Probably should have some static coroutine manager for things that need to run no matter what.
        CameraFollower.GetCamera().GetComponent<CameraFollower>().StartCoroutine(FadeInAndOut());
    }
    private IEnumerator FadeInAndOut() {
        CanvasGroup group = statsSpawner.GetComponent<CanvasGroup>();
        group.alpha = 1f;
        yield return new WaitForSecondsRealtime(2f);
        float startTime = Time.unscaledTime;
        while(Time.unscaledTime < startTime + 1f ) {
            float t = 1f-Mathf.Clamp01(Time.unscaledTime - startTime);
            group.alpha = t;
            yield return null;
        }
        group.alpha = 0f;
    }
}
