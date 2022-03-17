using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class StatBar : MonoBehaviour {
    [SerializeField]
    private Image statIcon;
    [SerializeField]
    private Image up;
    [SerializeField]
    private Image down;
    [SerializeField]
    private TMPro.TMP_Text statText;
    private float currentValue;
    public void Setup(Sprite statSprite, Attribute attr) {
        statIcon.sprite = statSprite;
        float value = attr.GetValue();
        statText.text = value.ToString("F1");
        if (value > currentValue) {
            StartCoroutine(FadeInOut(up));
        }
        if (value < currentValue) {
            StartCoroutine(FadeInOut(down));
        }
        currentValue = value;
    }
    public void Setup(Sprite statSprite, AttributeModifier attrMod) {
        string txt = "";
        float add = attrMod.baseValue+attrMod.flatUp+attrMod.diminishingReturnUp;
        if (add > 0f) {
            txt += "+" + add.ToString("F1") + " ";
        } else if (add < 0f) {
            txt += add.ToString("F1") + " ";
        }
        float multi = attrMod.multiplier;
        if (multi != 1f) {
            txt += "x" + multi.ToString("F1");
        }
        if ( add > 0f || multi > 1f) {
            up.gameObject.SetActive(true);
            up.color = up.color.With(a:1f);
        } else if ( add < 0f || multi < 1f) {
            down.gameObject.SetActive(true);
            down.color = down.color.With(a:1f);
        }
        statIcon.sprite = statSprite;
        statText.text = txt;

    }
    public IEnumerator FadeInOut(Image targetImage) {
        float startTime = Time.unscaledTime;
        targetImage.gameObject.SetActive(true);
        while(Time.unscaledTime < startTime+2f) {
            float t = Mathf.Clamp01(Time.unscaledDeltaTime-startTime);
            targetImage.color = targetImage.color.With(a:1f-t);
            yield return null;
        }
        targetImage.color = targetImage.color.With(a:0f);
        targetImage.gameObject.SetActive(false);
    }
}
