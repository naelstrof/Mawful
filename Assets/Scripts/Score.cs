using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Score : MonoBehaviour {
    public class WeaponDamage {
        public WeaponDamage() {
            startTime = Time.timeSinceLevelLoad;
        }
        public float startTime;
        public float endTime;
        public float totalDamage;
    }
    private Dictionary<WeaponCard,WeaponDamage> damageData;
    [SerializeField]
    private List<ScoreCard> packets;
    private static Score instance;
    void Awake() {
        if (instance != null) {
            Destroy(this);
            return;
        }
        damageData = new Dictionary<WeaponCard, WeaponDamage>();
        instance = this;
        DontDestroyOnLoad(gameObject);
    }
    public static bool HasScore() {
        return instance.packets.Count > 0;
    }
    public static void TriggerEndTime() {
        foreach(var pair in instance.damageData) {
            if (pair.Value.endTime == 0f) {
                pair.Value.endTime = Time.timeSinceLevelLoad;
            }
        }
    }
    public static void Reset() {
        instance.packets.Clear();
        instance.damageData.Clear();
    }
    public static void AddDamage(WeaponCard card, float damage) {
        if (!instance.damageData.ContainsKey(card)) {
            instance.damageData.Add(card, new WeaponDamage());
        }
        instance.damageData[card].totalDamage += damage;
    }
    public static void AddScore(ScoreCard card) {
        if (card == null) {
            throw new UnityException("Can't add a null score card");
        }
        instance.packets.Add(card);
    }
    public static List<ScoreCard> GetScores() {
        return new List<ScoreCard>(instance.packets);
    }
    public static Dictionary<WeaponCard, WeaponDamage> GetDamageData() {
        return new Dictionary<WeaponCard, WeaponDamage>(instance.damageData);
    }
    public static void ClearScore() {
        instance.packets.Clear();
        instance.damageData.Clear();
    }
}
