using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

public class SelectHandler : MonoBehaviour, ISelectHandler, IPointerEnterHandler {
    public delegate void SelectAction(BaseEventData eventData);
    public event SelectAction onSelect;
    public void OnSelect(BaseEventData eventData) {
        onSelect?.Invoke(eventData);
    }

    public void OnPointerEnter(PointerEventData eventData) {
        onSelect?.Invoke(eventData);
    }
}
