using System.Collections;
using System.Collections.Generic;
using UnityEngine;
#if UNITY_EDITOR
using UnityEditor;
#endif

#if UNITY_EDITOR
public class PositionCurveEditor<C,T>: Editor
            where C : IPositionCurve, new()
            where T : PositionCurveMonoBehaviour<C> {
    public override void OnInspectorGUI() {
        serializedObject.Update();
        base.DrawDefaultInspector();
        SerializedProperty positions = serializedObject.FindProperty("positions");
        if (GUILayout.Button("Add new spline point")){
            Undo.RecordObject(target, "created spline point");
            int startIndex = positions.arraySize;
            positions.InsertArrayElementAtIndex(startIndex);
            positions.GetArrayElementAtIndex(startIndex).vector3Value = Vector3.zero;
        }
        if (GUILayout.Button("Remove spline point")){
            positions.DeleteArrayElementAtIndex(positions.arraySize-1);
        }
        if (positions.arraySize < 2) {
            EditorGUILayout.HelpBox("Please add a new spline--", MessageType.Error);
        }
        serializedObject.ApplyModifiedProperties();
    }
    protected virtual void OnSceneGUI() {
        T positionSpline = target as T;
        Transform positionParent = positionSpline.positionsParent;
        if (positionParent == null) {
            return;
        }
        for(int i=0;i<positionSpline.positions.Length;i++) {
            Vector3 pos = positionParent.TransformPoint(positionSpline.positions[i]);
            EditorGUI.BeginChangeCheck();
            Vector3 newPos = Handles.PositionHandle(pos, Quaternion.identity);
            if (EditorGUI.EndChangeCheck()) {
                Undo.RecordObject(target, "move node");
                positionSpline.positions[i] = positionParent.InverseTransformPoint(newPos);
            }
        }
    }
}
#endif
public class PositionCurveMonoBehaviour <T>: MonoBehaviour where T : IPositionCurve, new() {
    [SerializeField]
    private bool looped = false;
    [SerializeField]
    public Transform positionsParent;
    [SerializeField]
    public Vector3[] positions;
    [SerializeField]
    public IPositionCurve positionCurve;
    public virtual void Awake() {
        positionCurve = new T();
        positionCurve.SetLooped(looped);
        positionCurve.SetTargetPositions(positions);
    }
    public virtual void OnDrawGizmos() {
        if (positions == null || positions.Length < 2) {
            return;
        }
        if (positionCurve == null) {
            positionCurve = new T();
        }
        Gizmos.color = Color.yellow;
        positionCurve.SetLooped(looped);
        positionCurve.SetTargetPositions(positions);
        Vector3 lastPos = positionCurve.Evaluate(0f);
        if (positionsParent != null) {
            lastPos = positionsParent.TransformPoint(positionCurve.Evaluate(0f));
        }
        float resolutionStep = 0.05f;
        for(float t = 0;;t=Mathf.MoveTowards(t,1f,resolutionStep)) {
            Vector3 newPos = positionCurve.Evaluate(t);
            if (positionsParent != null) {
                newPos = positionsParent.TransformPoint(newPos);
            }
            Gizmos.DrawLine(lastPos, newPos);
            lastPos = newPos;
            if (t == 1f) {
                break;
            }
        }
        foreach(Vector3 pos in positions) {
            if (positionsParent != null) {
                Gizmos.DrawWireSphere(positionsParent.TransformPoint(pos), 0.5f);
            } else {
                Gizmos.DrawWireSphere(pos, 0.5f);
            }
        }
    }
}
public interface IPositionCurve {
    public bool GetLooped();
    public void SetLooped(bool value);
    public void SetTargetPositions(Vector3[] points);
    public Vector3 Evaluate(float time01);
}
[System.Serializable]
public class CatmullRomPositionSpline : IPositionCurve {
    [SerializeField]
    private bool splineLoop;
    public bool GetLooped() => splineLoop;
    public void SetLooped(bool value) => splineLoop = value;
    public CatmullRomPositionSpline() {
        splineWeights = new List<Vector3>();
    }
    public void SetTargetPositions(Vector3[] points) {
        CatmullRom.GenerateSplineValues(points, splineWeights, splineLoop);
    }
    public Vector3 Evaluate(float time01) {
        if (time01 > 1f) {
            time01 = Mathf.Repeat(time01, 1f);
        }
        time01 *= (splineWeights.Count/4);
        // Progress is now from 0 to n, where n is the number of splines
        int splineIndex = Mathf.FloorToInt(time01)*4;
        // Floor doesn't work on the last digit (when we're exactly on the digit)
        if (splineIndex == splineWeights.Count) {
            splineIndex -= 4;
            time01 = 1f;
        // For every other case, we're fine to just repeat between 0 and 1
        } else {
            time01 = Mathf.Repeat(time01,1f);
        }
        Vector3 pos = CatmullRom.CalculatePosition(splineWeights[splineIndex],
                                                    splineWeights[splineIndex+1],
                                                    splineWeights[splineIndex+2],
                                                    splineWeights[splineIndex+3], time01);
        return pos;
    }
    private List<Vector3> splineWeights;
}