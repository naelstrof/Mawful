using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class Axe : Projectile {
    private static Vector3 gravityDir = new Vector3(1f,0,-1f).normalized * 9.81f;
    public void Update() {
        transform.rotation *= Quaternion.AngleAxis(Time.deltaTime*360f, Vector3.forward);
    }
    public override void FixedUpdate() {
        Vector3 newPosition = position + (position-lastPosition)*(1f-friction*friction) + gravityDir * Time.fixedDeltaTime*Time.fixedDeltaTime;
        lastPosition = position;
        position = newPosition;
        Vector3 edgePoint = WorldGrid.instance.worldBounds.ClosestPoint(newPosition);
        if (edgePoint != newPosition) {
            Reset();
            gameObject.SetActive(false);
        }

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
        DoWallCollision(WorldGrid.instance.GetPathGridElement(pathX,pathY), newPosition);
    }
}
