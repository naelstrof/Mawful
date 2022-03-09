using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Score : MonoBehaviour {
    [System.Serializable]
    public class ScorePacket {
        public Mesh mesh;
        public Material material;
        public float score;
    }
    [SerializeField]
    private List<ScorePacket> packets;
    private static Score instance;
    void Awake() {
        if (instance != null) {
            Destroy(this);
            return;
        }
        instance = this;
        DontDestroyOnLoad(gameObject);
    }
    public static float GetTotalScore() {
        float score = 0f;
        for(int i=0;i<instance.packets.Count;i++) {
            score += instance.packets[i].score;
        }
        return score;
    }
    public static void Reset() {
        instance.packets.Clear();
    }
    public static void AddScore(Mesh mesh, Material material, float score) {
        ScorePacket packet = new ScorePacket();
        packet.mesh = mesh;
        packet.material = material;
        packet.score = score;
        instance.packets.Add(packet);
    }
    public static List<ScorePacket> GetScores() {
        return new List<ScorePacket>(instance.packets);
    }
    public static void ClearScore() {
        instance.packets.Clear();
    }
}
