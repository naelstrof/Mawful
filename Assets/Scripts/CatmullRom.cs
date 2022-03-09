using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class CatmullRom {
    //Returns a position between 4 Vector3 with Catmull-Rom spline algorithm
	//http://www.iquilezles.org/www/articles/minispline/minispline.htm
	/*public static Vector3 GetPosition(float t, Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3) {
		//The coefficients of the cubic polynomial (except the 0.5f * which I added later for performance)
		Vector3 a = 2f * p1;
		Vector3 b = p2 - p0;
		Vector3 c = 2f * p0 - 5f * p1 + 4f * p2 - p3;
		Vector3 d = -p0 + 3f * p1 - 3f * p2 + p3;
		//The cubic polynomial: a + b * t + c * t^2 + d * t^3
		Vector3 pos = 0.5f * (a + (b * t) + (c * t * t) + (d * t * t * t));
		return pos;
	}*/
	public static Vector3 CalculatePosition(Vector3 start, Vector3 end, Vector3 tanPoint1, Vector3 tanPoint2, float t) {
		// Hermite curve formula:
		// (2t^3 - 3t^2 + 1) * p0 + (t^3 - 2t^2 + t) * m0 + (-2t^3 + 3t^2) * p1 + (t^3 - t^2) * m1
		Vector3 position = (2.0f * t * t * t - 3.0f * t * t + 1.0f) * start
			+ (t * t * t - 2.0f * t * t + t) * tanPoint1
			+ (-2.0f * t * t * t + 3.0f * t * t) * end
			+ (t * t * t - t * t) * tanPoint2;

		return position;
	}
	public static void GenerateSplineValues(Vector3[] controlPoints, List<Vector3> pValues, bool closedLoop) {
		pValues.Clear();
		Vector3 p0, p1; //Start point, end point
		Vector3 m0, m1; //Tangents
		// First for loop goes through each individual control point and connects it to the next, so 0-1, 1-2, 2-3 and so on
		int closedAdjustment = closedLoop ? 0 : 1;
		for (int currentPoint = 0; currentPoint < controlPoints.Length - closedAdjustment; currentPoint++) {
			bool closedLoopFinalPoint = (closedLoop && currentPoint == controlPoints.Length - 1);
			p0 = controlPoints[currentPoint];
			p1 = closedLoopFinalPoint ? controlPoints[0] : controlPoints[currentPoint+1];
			// m0
			// Tangent M[k] = (P[k+1] - P[k-1]) / 2
			if (currentPoint == 0) {
				if(closedLoop) {
					m0 = p1 - controlPoints[controlPoints.Length - 1];
				} else {
					m0 = p1 - p0;
				}
			} else {
				m0 = p1 - controlPoints[currentPoint - 1];
			}

			// m1
			if (closedLoop) {
				//Last point case
				if (currentPoint == controlPoints.Length - 1) {
					m1 = controlPoints[(currentPoint + 2) % controlPoints.Length] - p0;
					//First point case
				} else if (currentPoint == 0) {
					m1 = controlPoints[currentPoint + 2] - p0;
				} else {
					m1 = controlPoints[(currentPoint + 2) % controlPoints.Length] - p0;
				}
			} else {
				if (currentPoint < controlPoints.Length - 2) {
					m1 = controlPoints[(currentPoint + 2) % controlPoints.Length] - p0;
				} else {
					m1 = p1 - p0;
				}
			}

			m0 *= 0.5f; //Doing this here instead of  in every single above statement
			m1 *= 0.5f;

			pValues.Add(p0);
			pValues.Add(p1);
			pValues.Add(m0);
			pValues.Add(m1);
		}
	}

}

