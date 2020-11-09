using System;

namespace SpyroScope {
	static class GMath {
		public enum SideIntersect { Front, Back, Both }
		public static float RayPlaneIntersect(Vector rayOrigin, Vector rayDirection, Vector planeOrigin, Vector planeNormal, SideIntersect side = .Both) {
			let originDistance = Vector.Dot(planeOrigin - rayOrigin, planeNormal);

			switch (side) {
				case .Front: if (originDistance > 0) return float.NegativeInfinity;
				case .Back: if (originDistance < 0) return float.NegativeInfinity;
				default :
			}

			let disalignment = Vector.Dot(rayDirection, planeNormal);
			return originDistance / disalignment;
		}

		public static float RayTriangleIntersect(Vector rayOrigin, Vector rayDirection, Vector p0, Vector p1, Vector p2, SideIntersect side) {
			let normal = Vector.Cross(p2 - p0, p1 - p0);
			let time = RayPlaneIntersect(rayOrigin, rayDirection, p0, normal, side);
			let intersect = rayOrigin + rayDirection * time;

			if (
				Vector.Dot(Vector.Cross(p2 - p0, intersect - p0), normal) > 0 &&
				Vector.Dot(Vector.Cross(p0 - p1, intersect - p1), normal) > 0 &&
				Vector.Dot(Vector.Cross(p1 - p2, intersect - p2), normal) > 0
			) {
				return time;
			}
			return float.PositiveInfinity * time;
		}

		public static bool RayMeshIntersect(Vector rayOrigin, Vector rayDirection, Mesh mesh, ref float closestTime, ref int triangleIndex) {
			var hit = false;
			let indices = mesh.[Friend]indices;
			for (int i = 0; i < indices.Count; i += 3) {
				let time = RayTriangleIntersect(rayOrigin, rayDirection, mesh.vertices[indices[i]], mesh.vertices[indices[i + 1]], mesh.vertices[indices[i + 2]], .Front);
				if (time > 0 && time < closestTime) {
					closestTime = time;
					triangleIndex = i / 3;
					hit = true;
				}
			}
			return hit;
		}
	}
}
