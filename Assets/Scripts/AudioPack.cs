using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Audio;

[CreateAssetMenu(fileName = "NewAudioPack", menuName = "VoreGame/AudioPack")]
public class AudioPack : ScriptableObject {
    public AudioClip[] clips;
    public float volume = 1f;
    public AudioMixerGroup group;
    public AudioClip GetRandomClip() {
        return clips[Random.Range(0, clips.Length)];
    }
    public void Play(AudioSource source) {
        source.outputAudioMixerGroup = group;
        source.clip = GetRandomClip();
        source.volume = volume;
        source.pitch = UnityEngine.Random.Range(0.7f,1.3f);
        source.Play();
    }
    public void PlayOneShot(AudioSource source) {
        source.outputAudioMixerGroup = group;
        source.pitch = UnityEngine.Random.Range(0.7f,1.3f);
        source.PlayOneShot(GetRandomClip(), volume);
    }

}
