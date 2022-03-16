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
    [SerializeField]
    private AudioPack whipMiss;
    [SerializeField]
    private AudioPack whipHit;
    private AudioSource source;
    public override void Start() {
        source = GetComponentInParent<AudioSource>();
        stats.projectileCooldown.changed += OnCooldownChanged;
        stats.projectileRadius.changed += OnRadiusChanged;
        stats.projectileCount.changed += OnProjectileCountChanged;
        OnProjectileCountChanged(stats.projectileCount.GetValue());
        OnCooldownChanged(stats.projectileCooldown.GetValue());
        OnRadiusChanged(stats.projectileRadius.GetValue());
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
            while(Pauser.GetPaused()) {
                yield return null;
            }
            yield return timeToWait;
            for (int i=0;i<whips.Count;i++) {
                bool hit = false;
                float aimAngle = Vector3.Dot(CameraFollower.GetCamera().transform.right, player.fireDir) > 0f ? 0f : 180f;
                whips[i].transform.rotation = Quaternion.AngleAxis((i%2)*180f+90f+aimAngle+CameraFollower.GetCamera().transform.rotation.eulerAngles.y, Vector3.up);
                whips[i].Play();
                for(float dist=0f;dist<4f+stats.projectileRadius.GetValue();dist+=2f) {
                    foreach(Character character in Character.characters) {
                        if (character == player) {
                            continue;
                        }
                        float vfxRadius = stats.projectileRadius.GetValue()*0.6f;
                        if (Vector3.Distance(character.position, player.position+whips[i].transform.forward*dist) <= vfxRadius+character.radius) {
                            float knockbackAmount = 0.2f*dist;
                            character.BeHit(new Character.DamageInstance(weaponCard, stats.damage.GetValue(), (character.position-player.position).normalized*stats.knockback.GetValue()));
                            hit = true;
                        }
                    }
                }
                if (hit) {
                    whipHit.PlayOneShot(source);
                } else {
                    whipMiss.PlayOneShot(source);
                }
                yield return perProjectileWait;
            }
        }
    }
}
