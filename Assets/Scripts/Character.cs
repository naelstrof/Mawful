using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(SphereCollider))]
public class Character : PooledItem {
    public delegate void StartVoreAction();
    public event StartVoreAction startedVore;
    public delegate void PositionSet(Vector3 newPosition);
    public PositionSet positionSet;
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
    [HideInInspector]
    public float radius = 0.5f;
    [SerializeField]
    [ColorUsage(false, true)]
    private Color colorFlash;
    protected bool beingVored = false;
    protected bool frozen;
    private Vector3 freezePosition;
    public ScoreCard scoreCard;
    public Attribute damage;
    public struct DamageInstance {
        public DamageInstance(WeaponCard card, float damage, Vector3 knockback) {
            this.card = card;
            this.damage = damage;
            this.knockback = knockback;
        }
        public WeaponCard card;
        public float damage;
        public Vector3 knockback;
    }
    IEnumerator HitEffect() {
        float startTime = Time.time;
        float duration = 0.33f;
        while(Time.time < startTime+duration) {
            float t = (Time.time-startTime)/duration;
            targetRenderer.material.SetColor("_EmissionColor", Color.Lerp(Color.black, colorFlash, hitEffectCurve.Evaluate(t)));
            yield return null;
        }
        targetRenderer.material.SetColor("_EmissionColor", Color.black);
    }
    /*public virtual void Freeze(float time) {
        StartCoroutine(FreezeRoutine(time));
    }
    private IEnumerator FreezeRoutine(float time) {
        frozen = true;
        freezePosition = position;
        yield return new WaitForSeconds(time);
        frozen = false;
    }*/
    public void SetFreeze(bool freeze) {
        frozen = freeze;
        freezePosition = position;
    }
    public virtual bool StartVore() {
        if (beingVored) {
            return false;
        }
        beingVored = true;
        enabled = false;
        startedVore?.Invoke();
        return true;
    }
    public virtual void BeHit(DamageInstance instance) {
        if (health.GetHealth() <= 0f || frozen) {
            return;
        }
        MeshFloater floater;
        MeshFloaterPool.StaticTryInstantiate(out floater);
        floater.transform.position = position + Vector3.up*0.5f;
        floater.SetDisplay(Mathf.CeilToInt(instance.damage*10f));
        health.Damage(instance.damage);
        position += instance.knockback;
        if (hitRoutine != null) {
            StopCoroutine(hitRoutine);
        }
        hitRoutine = StartCoroutine(HitEffect());
    }
    public void SetPositionAndVelocity(Vector3 position, Vector3 velocity) {
        this.position = WorldGrid.instance.worldBounds.ClosestPoint(position);
        lastPosition = this.position - velocity;
        transform.position = this.position;
        positionSet?.Invoke(this.position);
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
    }
    protected virtual void Start() {
        radius = GetComponent<SphereCollider>().radius;
        Pauser.pauseChanged += OnPauseChanged;
    }
    public virtual void OnEnable() {
        characters.Add(this);
    }
    protected virtual void OnDestroy() {
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
            if ((this is EnemyCharacter && character is PlayerCharacter) && health.GetHealth()>0f && moveAmount > 0f) {
                character.BeHit(new DamageInstance(null, Mathf.Min(health.GetHealth(),2f), Vector3.zero));
            } else if ((character is EnemyCharacter && this is PlayerCharacter) && health.GetHealth()>0f && moveAmount > 0f) {
                this.BeHit(new DamageInstance(null, Mathf.Min(character.health.GetHealth(),2f), Vector3.zero));
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
            Physics.ComputePenetration(characterCollider, newPosition, Quaternion.identity, WorldGrid.instance.pathCollider, worldPosition, Quaternion.identity, out outDir, out outDist);
            newPosition += outDir*outDist;
        }
    }
    public virtual void FixedUpdate() {
        Vector3 diff = (position-lastPosition);
        float mag = diff.magnitude;
        float maxMeterMovement = 5f;
        Vector3 newPosition = position + diff.normalized*Mathf.Min(mag,maxMeterMovement)*(1f-friction*friction);
        lastPosition = position;
        newPosition += wishDir * Time.deltaTime * speed.GetValue();
        newPosition = WorldGrid.instance.worldBounds.ClosestPoint(newPosition);
        if (health.GetHealth() > 0f) {
            newPosition.y = 0f;
        }

        if (!phased) {
            int collisionX = Mathf.RoundToInt(newPosition.x/WorldGrid.instance.collisionGridSize);
            int collisionY = Mathf.RoundToInt(newPosition.z/WorldGrid.instance.collisionGridSize);
            int collisionXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.instance.collisionGridSize,1f))*2-1);
            int collisionYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.instance.collisionGridSize,1f))*2-1);
            DoCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY), ref newPosition);
            DoCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY), ref newPosition);
            DoCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX, collisionY+collisionYOffset), ref newPosition);
            DoCharacterCollision(WorldGrid.instance.GetCollisionGridElement(collisionX+collisionXOffset, collisionY+collisionYOffset), ref newPosition);
        }

        if (frozen) {
            position = freezePosition;
            return;
        }

        int pathX = Mathf.RoundToInt(newPosition.x/WorldGrid.instance.pathGridSize);
        int pathY = Mathf.RoundToInt(newPosition.z/WorldGrid.instance.pathGridSize);
        int pathXOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.x/WorldGrid.instance.pathGridSize,1f))*2-1);
        int pathYOffset = -(Mathf.RoundToInt(Mathf.Repeat(newPosition.z/WorldGrid.instance.pathGridSize,1f))*2-1);
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX,pathY), ref newPosition);
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX+pathXOffset, pathY), ref newPosition);
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX, pathY+pathYOffset), ref newPosition);
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX+pathXOffset, pathY+pathYOffset), ref newPosition);
        position = newPosition;
    }
    public virtual void LateUpdate() {
        transform.position = interpolatedPosition;
    }
    public override void Reset() {
        base.Reset();
        enabled = !Pauser.GetPaused();
        beingVored = false;
        health.Heal(99999f);
    }
    protected virtual void OnPauseChanged(bool paused) {
        enabled = !paused && !beingVored;
    }
}
