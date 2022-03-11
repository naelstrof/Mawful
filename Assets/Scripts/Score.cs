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
    public static float GetXP(ScoreCard type) {
        float xp = PlayerPrefs.GetFloat(type.name, 0f);
        return xp;
    }
    private void SetXP(ScoreCard type, float xp)  {
        PlayerPrefs.SetFloat(type.name, xp);
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

        HashSet<ScoreCard> cardTypes = new HashSet<ScoreCard>(instance.packets);
        foreach(ScoreCard card in cardTypes) {
            float addedXP = 0f;
            foreach(ScoreCard scoreCard in instance.packets) {
                if (scoreCard == card) {
                    addedXP++;
                }
            }
            instance.SetXP(card, GetXP(card)+addedXP);
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
