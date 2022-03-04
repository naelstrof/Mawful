using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

public class GloryAudioDucker : MonoBehaviour {
    [SerializeField]
    private AudioMixer mixer;
    void Start() {
        CameraFollower.instance.gloryModeChanged += OnGloryModeChanged;
    }
    void OnGloryModeChanged(bool glory) {
        float value = glory?0.5f:1f;
        mixer.SetFloat("GloryDuckVolume", Mathf.Log(Mathf.Max(value,0.01f))*20f);
    }
    void OnDestroy() {
        float value = 1f;
        mixer.SetFloat("GloryDuckVolume", Mathf.Log(Mathf.Max(value,0.01f))*20f);
        CameraFollower.instance.gloryModeChanged -= OnGloryModeChanged;
    }
}
