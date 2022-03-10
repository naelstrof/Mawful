using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooMonsterDickVore : Vore {
    private float vel;
    private float ballsSizeTarget = 0f;
    private float ballsSize = 0f;
    [SerializeField]
    private Animator monsterAnimator;
    public override void Vaccum(Character other) {
        voreBumps.Add(new VoreBump(Time.time,UnityEngine.Random.Range(minTimeRange, maxTimeRange), other));
        chompEffect.Play();
    }
    protected override void Digest(Character character) {
        ballsSizeTarget = Mathf.Lerp(ballsSizeTarget, 1f, 0.005f);
        if (!source.isPlaying) {
            gulp.Play(source);
        }
    }
    protected override void Update() {
        base.Update();
        ballsSize = Mathf.SmoothDamp(ballsSize, ballsSizeTarget, ref vel, 0.5f, 1f);
        monsterAnimator.SetFloat("BallsBlend", ballsSize);
    }
}
