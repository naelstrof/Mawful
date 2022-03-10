using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PooledItem : MonoBehaviour {
    public delegate void OnResetAction();
    public event OnResetAction resetTrigger;
    private List<PooledItem> pooledChildren;
    // Quickly cache all pooled items, so that we can "reset" the whole object.
    public virtual void Awake() {
        pooledChildren = new List<PooledItem>();
        GetComponentsInChildren<PooledItem>(pooledChildren);

        // Make sure we don't loop forever
        for(int i=0;i<pooledChildren.Count;i++) {
            if (pooledChildren[i].pooledChildren.Contains(this)) {
                pooledChildren[i].pooledChildren.Remove(this);
            }
        }
        pooledChildren.Remove(this);
    }
    public virtual void Reset() {
        foreach(PooledItem item in pooledChildren) {
            item.Reset();
        }
        resetTrigger?.Invoke();
    }
}
