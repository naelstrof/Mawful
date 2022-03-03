using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;

public class Whip : Weapon {
    private WaitForSeconds perProjectileWait;
    private WaitForSeconds timeToWait;
    [SerializeField]
    private GameObject whipPrefab;
    private List<VisualEffect> whips;
    public override void Start() {
        cooldown.changed += OnCooldownChanged;
        radius.changed += OnRadiusChanged;
        projectileCount.changed += OnProjectileCountChanged;
        OnProjectileCountChanged(projectileCount.GetValue());
        OnCooldownChanged(cooldown.GetValue());
        OnRadiusChanged(radius.GetValue());
        perProjectileWait = new WaitForSeconds(0.33f);
        base.Start();
    }
    void OnProjectileCountChanged(float newProjectileCount) {
        if (whips != null) {
            foreach(VisualEffect v in whips) {
                Destroy(v.gameObject);
            }
        }

        whips = new List<VisualEffect>();
        for(int i=0;i<Mathf.RoundToInt(newProjectileCount);i++) {
            VisualEffect whip = GameObject.Instantiate(whipPrefab, transform).GetComponent<VisualEffect>();
            whips.Add(whip);
            //whips[i].transform.rotation = Quaternion.Euler(0f,CameraFollower.GetCamera().transform.rotation.eulerAngles.y,0f)*Quaternion.AngleAxis((i%2)*180f+270f, Vector3.up);
        }
    }
    void OnCooldownChanged(float newCooldown) {
        timeToWait = new WaitForSeconds(1f/newCooldown);
    }
    void OnRadiusChanged(float newRadius) {
        foreach(VisualEffect v in whips) {
            v.SetFloat("Radius", 4f+newRadius);
        }
    }
    public override IEnumerator FireRoutine() {
        while(isActiveAndEnabled) {
            yield return timeToWait;
            for (int i=0;i<whips.Count;i++) {
                float aimAngle = Vector3.Dot(CameraFollower.GetCamera().transform.right, player.fireDir) > 0f ? 0f : 180f;
                whips[i].transform.rotation = Quaternion.AngleAxis((i%2)*180f+90f+aimAngle+CameraFollower.GetCamera().transform.rotation.eulerAngles.y, Vector3.up);
                whips[i].Play();
                for(float dist=0f;dist<4f+radius.GetValue();dist+=2f) {
                    foreach(Character character in Character.characters) {
                        if (character == player) {
                            continue;
                        }
                        float vfxRadius = radius.GetValue()*0.6f;
                        if (Vector3.Distance(character.position, player.position+whips[i].transform.forward*dist) <= vfxRadius+character.radius) {
                            float knockbackAmount = 0.2f*dist;
                            character.BeHit(new Character.DamageInstance(damage.GetValue(), (character.position-player.position).normalized*knockbackAmount));
                        }
                    }
                }
                yield return perProjectileWait;
            }
        }
    }
}
