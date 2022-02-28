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
    void Start() {
        character = GetComponentInParent<Character>();
        character.health.healthChanged += OnHealthChanged;
        originalScale = flashRenderer.transform.localScale;
        flashMaterial = flashRenderer.material;
        originalColor = flashMaterial.color;
        originalOutlineColor = outlineRenderer.material.color;
        rountine = StartCoroutine(HurtRoutine());
    }
    void OnDestroy() {
        if (character != null) {
            character.health.healthChanged -= OnHealthChanged;
        }
    }
    void OnHealthChanged(float newValue) {
        float ratio = character.health.GetHealth()/character.health.GetValue();
        flashMaterial.color = originalColor;
        outlineRenderer.material.color = originalOutlineColor;
        flashRenderer.transform.localScale = Vector3.Scale(originalScale, new Vector3(ratio,1f,1f));
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
