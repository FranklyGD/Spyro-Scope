using System;

namespace SpyroScope {
	static struct Camera {
		public static Vector position;
		public static Matrix basis;
		public static float fov;

		public static Matrix4 projection { get { return .Perspective(fov * Math.PI_f / 180,  (float)WindowApp.width / WindowApp.height, 100, 500000); } };

		public static Vector SceneToScreen(Vector worldPosition) {
			let viewProjectionMatrix = projection * (basis.Transpose() * Matrix4.Translation(-position));
			let viewPosition = viewProjectionMatrix * Vector4(worldPosition, 1);

			if (viewPosition.w < 0) {
				return .Zero;
			}

			return Vector(viewPosition.x / viewPosition.w * WindowApp.width / 2, viewPosition.y / viewPosition.w * WindowApp.height / 2, viewPosition.w);
		}

		public static float SceneSizeToScreenSize(float size, float depth) {
			return size * WindowApp.height / (depth * Math.Tan(fov * (Math.PI_f / 180) / 2) * 2);
		}
	}
}
