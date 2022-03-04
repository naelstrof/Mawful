using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class AudioPackPlayer : MonoBehaviour {
    private AudioSource source;
    void Start() {
        source = GetComponent<AudioSource>();
    }
    public void PlayFromPack(AudioPack pack) {
        pack.PlayOneShot(source);
    }
}
