using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Character : PooledItem {
    public static HashSet<Character> characters = new HashSet<Character>();
    public AnimationCurve hitEffectCurve;
    public Vector3 lastPosition;
    public Vector3 position;
    public Vector3 velocity {
        get {
            return (position-lastPosition);
        }
    }
    private Collider characterCollider;
    private Renderer targetRenderer;
    private Coroutine hitRoutine;
    protected Vector3 wishDir;
    [SerializeField]
    protected Attribute speed;
    [Range(0f,1f)][SerializeField]
    protected float friction;
    protected bool phased = false;
    public HealthAttribute health;
    [SerializeField]
    protected float radius = 0.5f;

    public Attribute damage;

    public void BeHit(Character other) {
        health.Damage(Time.fixedDeltaTime);
        if (hitRoutine != null) {
            StopCoroutine(hitRoutine);
        }
        hitRoutine = StartCoroutine(HitEffect());
    }
    IEnumerator HitEffect() {
        float startTime = Time.time;
        float duration = 0.33f;
        while(Time.time < startTime+duration) {
            float t = (Time.time-startTime)/duration;
            targetRenderer.material.SetColor("_EmissionColor", Color.Lerp(Color.black, Color.white, hitEffectCurve.Evaluate(t)));
            yield return null;
        }
        targetRenderer.material.SetColor("_EmissionColor", Color.black);
    }
    public void BeHit(Projectile projectile) {
        health.Damage(projectile.damage);
        position += projectile.knockback * (projectile.position-projectile.lastPosition).normalized;
        if (hitRoutine != null) {
            StopCoroutine(hitRoutine);
        }
        hitRoutine = StartCoroutine(HitEffect());
    }
    public void SetPositionAndVelocity(Vector3 position, Vector3 velocity) {
        this.position = position;
        lastPosition = position - velocity;
        transform.position = this.position;
    }

    public Vector3 interpolatedPosition {
        get {
            float timeSinceLastUpdate = Time.time-Time.fixedTime;
            return Vector3.Lerp(position, position+(position-lastPosition), timeSinceLastUpdate/Time.fixedDeltaTime);
        }
    }
    public virtual void Die() {
    }
    public override void Awake() {
        base.Awake();
        lastPosition = position = transform.position;
        characterCollider = GetComponent<Collider>();
        health.Heal(99999f);
        health.depleted += Die;
        targetRenderer = GetComponentInChildren<Renderer>();
        Pauser.pauseChanged += OnPauseChanged;
    }
    public virtual void OnEnable() {
        characters.Add(this);
    }
    void OnDestroy() {
        Pauser.pauseChanged -= OnPauseChanged;
    }
    public virtual void OnDisable() {
        characters.Remove(this);
    }
    private void DoCharacterCollision(WorldGrid.CollisionGridElement element, ref Vector3 newPosition) {
        foreach(Character character in element.charactersInElement) {
            if (character == this || character.phased) { continue; }
            Vector3 diff = position - character.position;
            Vector3 dir = diff.normalized;
            float mag = diff.magnitude;
            float doubleRadius = radius+character.radius;
            float moveAmount = Mathf.Max(doubleRadius-mag, 0f) * 0.5f;
            if (this is EnemyCharacter && character is PlayerCharacter && health.GetHealth()>0f && moveAmount > 0.01f) {
                character.BeHit(this);
            }
            newPosition += dir * moveAmount;
            character.position -= dir * moveAmount;
        }
    }
    private void DoWallCollision(WorldGrid.PathGridElement element, ref Vector3 newPosition) {
        if (!element.passable) {
            Vector3 worldPosition = element.worldPosition;
            Vector3 outDir;
            float outDist;
            Physics.ComputePenetration(characterCollider, newPosition, Quaternion.identity, WorldGrid.pathCollider, worldPosition, Quaternion.identity, out outDir, out outDist);
            newPosition += outDir*outDist;
        }
    }
    public virtual void FixedUpdate() {
        Vector3 newPosition = position + (position-lastPosition)*(1f-friction*friction);
        lastPosition = position;
        newPosition += wishDir * Time.deltaTime * speed.GetValue();
        Vector3 edgePoint = WorldGrid.worldBounds.ClosestPoint(newPosition);
        if (edgePoint != newPosition) {
            newPosition = edgePoint;
        }
        newPosition.y = 0f;

        if (!phased) {
            int collisionX = Mathf.RoundToInt(newPosition.x/WorldGrid.collisionGridSize);
            int collisionY = Mathf.RoundToInt(newPosition.z/WorldGrid.collisionGridSize);
            int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.collisionGridSize,1f))*2-1);
            int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.collisionGridSize,1f))*2-1);
            DoCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX, collisionY), ref newPosition);
            DoCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY), ref newPosition);
            DoCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX, collisionY+collisionYOffset), ref newPosition);
            DoCharacterCollision(WorldGrid.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset), ref newPosition);
        }

        int pathX = Mathf.RoundToInt(newPosition.x/WorldGrid.pathGridSize);
        int pathY = Mathf.RoundToInt(newPosition.z/WorldGrid.pathGridSize);
        int pathXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.pathGridSize,1f))*2-1);
        int pathYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.pathGridSize,1f))*2-1);
        DoWallCollision(WorldGrid.GetPathGridElement(pathX,pathY), ref newPosition);
        DoWallCollision(WorldGrid.GetPathGridElement(pathX+pathXOffset, pathY), ref newPosition);
        DoWallCollision(WorldGrid.GetPathGridElement(pathX, pathY+pathYOffset), ref newPosition);
        DoWallCollision(WorldGrid.GetPathGridElement(pathX+pathXOffset, pathY+pathYOffset), ref newPosition);
        position = newPosition;
    }
    public virtual void LateUpdate() {
        transform.position = interpolatedPosition;
    }
    public override void Reset() {
        base.Reset();
        health.Heal(99999f);
    }
    void OnPauseChanged(bool paused) {
        enabled = !paused;
    }
}
