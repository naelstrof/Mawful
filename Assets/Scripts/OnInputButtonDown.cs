using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Events;
using UnityEngine.InputSystem;
using UnityEngine.Serialization;

public class OnInputButtonDown : MonoBehaviour {
    public InputActionReference actionReference;
    [FormerlySerializedAs("OnButtonDown")]
    public UnityEvent onButtonDown;
    //public UnityEvent onButtonUp;
    //void Awake() {
    //}
    void OnButtonDown(InputAction.CallbackContext ctx) {
        if (ctx.ReadValueAsButton()) {
            onButtonDown.Invoke();
        }
    }
    //void OnButtonUp(InputAction.CallbackContext ctx) {
        //onButtonUp.Invoke();
    //}
    void OnEnable() {
        actionReference.action.performed += OnButtonDown;
        //actionReference.action.canceled += OnButtonUp;
    }
    void OnDisable() {
        actionReference.action.performed -= OnButtonDown;
        //actionReference.action.canceled -= OnButtonUp;
    }
}
