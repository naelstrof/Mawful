using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Projectile : PooledItem {
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
    private Dictionary<EnemyCharacter, float> hits;
    private float hitCooldown = 1f;
    private int hitCount;
    public int hitLimit = 1;
    private Collider projectileCollider;
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
    public override void Awake() {
        base.Awake();
        projectileCollider = GetComponent<Collider>();
        hits = new Dictionary<EnemyCharacter, float>();
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
        }
    }
    protected void DoHit(EnemyCharacter character) {
        hitCount++;
        character.BeHit(new Character.DamageInstance(weaponCard, damage, velocity*knockback));

        hitPack.PlayOneShot(character.audioSource);
        if (hitCount>=hitLimit) {
            gameObject.SetActive(false);
        }
    }
    public void SetPositionAndVelocity(Vector3 position, Vector3 velocity) {
        this.position = position;
        lastPosition = position - velocity;
        transform.position = this.position;
        transform.localScale = Vector3.one*radius;
    }
    protected void CheckCharacterCollision(WorldGrid.CollisionGridElement element, ref Vector3 newPosition) {
        foreach(Character character in element.charactersInElement) {
            if (!(character is EnemyCharacter)) { continue; }
            EnemyCharacter enemyCharacter = character as EnemyCharacter;
            if (enemyCharacter.health.GetHealth() <= 0f) {
                continue;
            }
            float dist = Vector3.Distance(position, enemyCharacter.position);
            if (dist<(radius+1f)*0.5f) {
                if (!hits.ContainsKey(enemyCharacter)) {
                    hits.Add(enemyCharacter, Time.time);
                    DoHit(enemyCharacter);
                } else if (Time.time-hits[enemyCharacter] > hitCooldown) {
                    hits[enemyCharacter] = Time.time;
                    DoHit(enemyCharacter);
                }
            }
        }
    }
    public virtual void FixedUpdate() {
        Vector3 newPosition = position + (position-lastPosition)*(1f-friction*friction);
        lastPosition = position;
        position = newPosition;
        Vector3 edgePoint = WorldGrid.instance.worldBounds.ClosestPoint(newPosition);
        if (Vector3.Distance(edgePoint,newPosition) > 0.001f) {
            Reset();
            gameObject.SetActive(false);
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
            transform.rotation = Quaternion.LookRotation(velocity, Vector3.up);
        }
        transform.localScale = Vector3.one*radius + Vector3.forward*velMag;
        transform.position = interpolatedPosition;
    }
    public override void Reset() {
        base.Reset();
        hits.Clear();
        hitCount = 0;
    }
}
