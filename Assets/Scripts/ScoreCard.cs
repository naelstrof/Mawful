using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "ScoreCard", menuName = "VoreGame/ScoreCard", order = 1)]
public class ScoreCard : ScriptableObject {
    [SerializeField]
    private List<BakedAnimation> struggleAnimations;
    [SerializeField]
    public Material material;
    [SerializeField]
    public Sprite characterSprite;
    public BakedAnimation GetStruggleAnimation() {
        return struggleAnimations[UnityEngine.Random.Range(0,struggleAnimations.Count)];
    }
}
