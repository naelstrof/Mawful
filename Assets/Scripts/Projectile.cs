using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Projectile : PooledItem {
    private Vector3 lastPosition;
    [Range(0f,1f)][SerializeField]
    private float friction = 0f;
    public Vector3 position;
    [SerializeField]
    public float damage = 1f;
    public float radius = 1f;
    private Dictionary<EnemyCharacter, float> hits;
    private float hitCooldown = 1f;
    private int hitCount;
    public int hitLimit = 1;
    public Vector3 interpolatedPosition {
        get {
            float timeSinceLastUpdate = Time.time-Time.fixedTime;
            return Vector3.Lerp(position, position+(position-lastPosition), timeSinceLastUpdate/Time.fixedDeltaTime);
        }
    }
    public override void Awake() {
        base.Awake();
        hits = new Dictionary<EnemyCharacter, float>();
    }
    private void DoHit(EnemyCharacter character) {
        hitCount++;
        character.BeHit(this);
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
    private void CheckCharacterCollision(WorldGrid.CollisionGridElement element, ref Vector3 newPosition) {
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
        int collisionX = Mathf.RoundToInt(newPosition.x/WorldGrid.collisionGridSize);
        int collisionY = Mathf.RoundToInt(newPosition.z/WorldGrid.collisionGridSize);
        int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.collisionGridSize,1f))*2-1);
        int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.collisionGridSize,1f))*2-1);
        CheckCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX, collisionY), ref newPosition);
        CheckCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY), ref newPosition);
        CheckCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX, collisionY+collisionYOffset), ref newPosition);
        CheckCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset), ref newPosition);
        position = newPosition;
    }
    public virtual void LateUpdate() {
        transform.position = interpolatedPosition;
    }
    public override void Reset() {
        base.Reset();
        hits.Clear();
        hitCount = 0;
    }
}
