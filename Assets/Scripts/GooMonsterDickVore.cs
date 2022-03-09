using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GooMonsterDickVore : Vore {
    private float ballsSize = 0f;
    public override void Vaccum(Character other) {
        voreBumps.Add(new VoreBump(Time.time,UnityEngine.Random.Range(minTimeRange, maxTimeRange), other));
        chompEffect.Play();
    }
    protected override void Digest(Character character) {
        ballsSize+=1f;
        gulp.PlayOneShot(source);
    }
}
