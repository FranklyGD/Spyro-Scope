namespace SpyroScope {
	static class GMath {
		public static float RayPlaneIntersect(Vector rayOrigin, Vector rayDirection, Vector planeOrigin, Vector planeNormal) {
			let originDistance = Vector.Dot(planeOrigin - rayOrigin, planeNormal);
			let disalignment = Vector.Dot(rayDirection, planeNormal);
			return originDistance / disalignment;
		}
	}
}
