using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Projectile : PooledItem {
    public delegate void StunChangedAction(bool stunned);
    public event StunChangedAction stunChanged;
    [SerializeField]
    protected AudioPack hitPack;
    [HideInInspector]
    public Vector3 lastPosition;
    [Range(0f,1f)][SerializeField]
    protected float friction = 0f;
    public Vector3 position;
    public WeaponCard weaponCard;
    [SerializeField]
    public float damage = 1f;
    public float radius = 1f;
    public float knockback = 1f;
    private Dictionary<Character, float> hits;
    private float hitCooldown = 1f;
    private int hitCount;
    public int hitLimit = 1;
    protected bool hitStunned;
    private Collider projectileCollider;
    private WaitForFixedUpdate waitForFixedUpdate;
    public Vector3 velocity {
        get {
            return position-lastPosition;
        }
    }
    public Vector3 interpolatedPosition {
        get {
            float timeSinceLastUpdate = Time.time-Time.fixedTime;
            return Vector3.Lerp(position, position+(position-lastPosition), timeSinceLastUpdate/Time.fixedDeltaTime);
        }
    }
    public void HitStun(float duration) {
        if (hitStunned) {
            return;
        }
        StartCoroutine(HitStunRoutine(duration));
    }
    public IEnumerator HitStunRoutine(float duration) {
        hitStunned = true;
        Vector3 preStunPosition = position;
        Vector3 preStunLastPosition = lastPosition;
        float preStunTime = Time.time;
        stunChanged?.Invoke(true);
        while(Time.time < preStunTime+duration) {
            yield return waitForFixedUpdate;
            position = preStunPosition;
            lastPosition = preStunPosition;
        }
        stunChanged?.Invoke(false);
        hitStunned = false;
        position = preStunPosition;
        lastPosition = preStunLastPosition;
        if (hitCount>=hitLimit) {
            Reset();
            gameObject.SetActive(false);
        }
    }
    public override void Awake() {
        base.Awake();
        waitForFixedUpdate = new WaitForFixedUpdate();
        projectileCollider = GetComponent<Collider>();
        hits = new Dictionary<Character, float>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
    protected void DoWallCollision(WorldGrid.PathGridElement element, Vector3 newPosition) {
        if (!element.passable) {
            Reset();
            gameObject.SetActive(false);
            return;
        }
    }
    protected void DoHit(Character character) {
        if (hitCount >= hitLimit) {
            return;
        }
        hitCount++;
        character.BeHit(new Character.DamageInstance(weaponCard, damage, velocity.normalized*knockback));

        hitPack.PlayOneShot(character.audioSource);
        // At the end of the hitstun, we'll check if we should be removed.
        HitStun(0.15f);
    }
    public void SetPositionAndVelocity(Vector3 position, Vector3 velocity) {
        this.position = position;
        lastPosition = position - velocity;
        transform.position = this.position;
        transform.localScale = Vector3.one*Mathf.Max(radius,0.01f);
    }
    protected void CheckCharacterCollision(WorldGrid.CollisionGridElement element, ref Vector3 newPosition) {
        foreach(Character character in element.charactersInElement) {
            if ((character is PlayerCharacter) || character.invulnerable) { continue; }
            if (character.stats.health.GetHealth() <= 0f) {
                continue;
            }
            float dist = Vector3.Distance(newPosition, character.position);
            if (dist<(radius+1f)*0.5f) {
                if (!hits.ContainsKey(character)) {
                    hits.Add(character, Time.time);
                    DoHit(character);
                } else if (Time.time-hits[character] > hitCooldown) {
                    hits[character] = Time.time;
                    DoHit(character);
                }
            }
        }
    }
    public virtual void FixedUpdate() {
        Vector3 newPosition = position + (position-lastPosition)*(1f-friction*friction);
        lastPosition = position;
        position = newPosition;
        Vector3 edgePoint = WorldGrid.instance.worldBounds.ClosestPoint(newPosition);
        if (Vector3.Distance(edgePoint,newPosition) > 0.01f) {
            Reset();
            gameObject.SetActive(false);
            return;
        }
        position.y = 0f;

        int collisionX = Mathf.RoundToInt(newPosition.x/WorldGrid.instance.collisionGridSize);
        int collisionY = Mathf.RoundToInt(newPosition.z/WorldGrid.instance.collisionGridSize);
        int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.instance.collisionGridSize,1f))*2-1);
        int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.instance.collisionGridSize,1f))*2-1);
        CheckCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY), ref newPosition);
        CheckCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY), ref newPosition);
        CheckCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY+collisionYOffset), ref newPosition);
        CheckCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset), ref newPosition);

        int pathX = Mathf.RoundToInt(newPosition.x/WorldGrid.instance.pathGridSize);
        int pathY = Mathf.RoundToInt(newPosition.z/WorldGrid.instance.pathGridSize);
        //int pathXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.pathGridSize,1f))*2-1);
        //int pathYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.pathGridSize,1f))*2-1);
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX,pathY), newPosition);
        //DoWallCollision(WorldGrid.GetPathGridElement(pathX+pathXOffset, pathY), newPosition);
        //DoWallCollision(WorldGrid.GetPathGridElement(pathX, pathY+pathYOffset), newPosition);
        //DoWallCollision(WorldGrid.GetPathGridElement(pathX+pathXOffset, pathY+pathYOffset), newPosition);
    }
    public virtual void LateUpdate() {
        float velMag = velocity.magnitude;
        if (velMag > 0.0001f) {
            transform.rotation = Quaternion.LookRotation(velocity.normalized, Vector3.up);
        }
        transform.localScale = Vector3.one*Mathf.Max(radius,0.01f) + Vector3.forward*velMag*1.5f;
        transform.position = interpolatedPosition;
    }
    public override void Reset(bool recurse = true) {
        base.Reset(recurse);
        hits.Clear();
        hitCount = 0;
    }
}
