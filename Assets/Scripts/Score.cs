using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Score : MonoBehaviour {
    [SerializeField]
    private List<ScoreCard> packets;
    private static Score instance;
    void Awake() {
        if (instance != null) {
            Destroy(this);
            return;
        }
        instance = this;
        DontDestroyOnLoad(gameObject);
    }
    public static bool HasScore() {
        return instance.packets.Count > 0;
    }
    public static void Reset() {
        instance.packets.Clear();
    }
    public static void AddScore(ScoreCard card) {
        instance.packets.Add(card);
    }
    public static List<ScoreCard> GetScores() {
        return new List<ScoreCard>(instance.packets);
    }
    public static void ClearScore() {
        instance.packets.Clear();
    }
}
