using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AudioPackRepeater : MonoBehaviour {
    [SerializeField]
    private float delay = 0f;
    private AudioSource source;
    [SerializeField]
    private AudioPack pack;
    void OnEnable() {
        source = GetComponent<AudioSource>();
        StartCoroutine(WaitAndPlay());
    }
    void OnDisable() {
        StopAllCoroutines();
    }
    IEnumerator WaitAndPlay() {
        while(true) {
            if (!source.isPlaying) {
                yield return new WaitForSeconds(delay);
                pack.Play(source);
            }
            yield return null;
        }
    }
    void Update() {
    }
}
