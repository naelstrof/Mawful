using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class HealthBar : MonoBehaviour {
    [SerializeField]
    private AnimationCurve healthFlash;
    private Character character;
    private Vector3 originalScale;
    private float healthFlashDuration = 0.4f;
    private Material flashMaterial;
    private Color originalColor;
    private Coroutine rountine;
    [SerializeField]
    private Renderer flashRenderer;
    [SerializeField]
    private Renderer outlineRenderer;
    private Color originalOutlineColor;
    void OnEnable() {
        character = GetComponentInParent<Character>();
        character.stats.health.healthChanged += OnHealthChanged;
        originalScale = flashRenderer.transform.localScale;
        flashMaterial = flashRenderer.material;
        originalColor = flashMaterial.color;
        originalOutlineColor = outlineRenderer.material.color;
        flashMaterial.color = originalColor;
        OnHealthChanged(character.stats.health.GetHealth());
    }
    void OnDisable() {
        flashMaterial.color = originalColor;
        outlineRenderer.material.color = originalOutlineColor;
        flashRenderer.transform.localScale = originalScale;
        flashRenderer.transform.localPosition = Vector3.zero;
        rountine = null;
        character.stats.health.healthChanged -= OnHealthChanged;
    }
    void OnHealthChanged(float newValue) {
        float ratio = character.stats.health.GetHealth()/character.stats.health.GetValue();
        flashMaterial.color = originalColor;
        outlineRenderer.material.color = originalOutlineColor;
        flashRenderer.transform.localScale = Vector3.Scale(originalScale, new Vector3(Mathf.Max(ratio,0.01f),1f,1f));
        flashRenderer.transform.localPosition = Vector3.left*(1f-ratio)*originalScale.x*0.5f;
        if (rountine != null) {
            StopCoroutine(rountine);
        }
        rountine = StartCoroutine(HurtRoutine());
    }
    IEnumerator HurtRoutine() {
        float startTime = Time.time;
        while (Time.time < startTime+healthFlashDuration) {
            float t = (Time.time-startTime)/healthFlashDuration;
            flashMaterial.color = Color.Lerp(originalColor, Color.white, healthFlash.Evaluate(t));
            yield return null;
        }
        flashMaterial.color = originalColor;
        yield return new WaitForSeconds(1f);
        float fadeTime = Time.time;
        while (Time.time < fadeTime+healthFlashDuration) {
            float t = (Time.time-fadeTime)/healthFlashDuration;
            flashMaterial.color = Color.Lerp(originalColor, Color.clear, t);
            outlineRenderer.material.color = Color.Lerp(originalOutlineColor, Color.clear, t);
            yield return null;
        }
        flashMaterial.color = Color.clear;
        outlineRenderer.material.color =  Color.clear;
    }
}
