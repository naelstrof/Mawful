using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

public class GloryAudioDucker : MonoBehaviour {
    [SerializeField]
    private AudioMixer mixer;
    [SerializeField]
    [Range(0f,1f)]
    private float gloryVolume = 0.8f;
    [SerializeField]
    [Range(0f,22000f)]
    private float gloryLowpassLimit = 600f;
    private Coroutine routine;
    void Start() {
        CameraFollower.instance.gloryModeChanged += OnGloryModeChanged;
    }
    void SetFloat(string name, float off, float on, float t, bool glory) {
        float currentValue;
        mixer.GetFloat(name, out currentValue);
        float desiredValue = glory?on:off;
        mixer.SetFloat(name, Mathf.Lerp(currentValue, desiredValue, t));
    }
    IEnumerator GoToGlory(float duration, bool glory) {
        float logVolumeOn = Mathf.Log(Mathf.Max(gloryVolume,0.01f))*20f;
        float logVolumeOff = Mathf.Log(Mathf.Max(1f,0.01f))*20f;
        float startTime = Time.time;
        while (Time.time < startTime+duration) {
            float t = Mathf.Clamp01((Time.time - startTime)/duration);
            SetFloat("GloryDuckVolume", logVolumeOff, logVolumeOn, t, glory);
            SetFloat("GloryDuckLowpass", 22000f, gloryLowpassLimit, t, glory);
            yield return null;
        }
        SetFloat("GloryDuckVolume", logVolumeOff, logVolumeOn, 1f, glory);
        SetFloat("GloryDuckLowpass", 22000f, gloryLowpassLimit, 1f, glory);
    }
    void OnGloryModeChanged(bool glory) {
        if (routine != null) {
            StopCoroutine(routine);
        }
        routine = StartCoroutine(GoToGlory(1f, glory));
    }
    void OnDestroy() {
        float value = 1f;
        mixer.SetFloat("GloryDuckVolume", Mathf.Log(Mathf.Max(value,0.01f))*20f);
        mixer.SetFloat("GloryDuckLowpass", 22000f);
        CameraFollower.instance.gloryModeChanged -= OnGloryModeChanged;
    }
}
