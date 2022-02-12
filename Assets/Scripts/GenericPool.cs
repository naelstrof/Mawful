using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GenericPool<T> : MonoBehaviour where T : PooledItem {
    private static GenericPool<T> instance;
    [SerializeField][Range(0,1000)]
    private int poolSize = 10;
    [SerializeField]
    private GameObject prefab;
    private Queue<T> prefabSet;
    void Awake() {
        prefabSet = new Queue<T>();
        instance = this;
        for(int i=0;i<poolSize;i++) {
            T thing = GameObject.Instantiate(prefab).GetComponent<T>();
            thing.resetTrigger += ()=>{prefabSet.Enqueue(thing);};
            thing.Reset();
            thing.gameObject.SetActive(false);
        }
    }
    public static bool TryInstantiate(out T thing) {
        if (instance.prefabSet.Count > 0) {
            thing = instance.prefabSet.Dequeue();
            thing.Reset();
            thing.gameObject.SetActive(true);
            return true;
        }
        thing = null;
        return false;
    }
}
