using System;

namespace SpyroScope {
	static struct Camera {
		public static Vector position;
		public static Matrix basis;
		public static bool orthographic;
		public static float size;
		public static float fov;
		public static float near = 100;
		public static float far = 500000;

		public static Matrix4 projection {
			get {
				return orthographic ? .Orthographic(size * WindowApp.width / WindowApp.height, size, near, far):
				.Perspective(fov * Math.PI_f / 180,  (float)WindowApp.width / WindowApp.height, near, far);
			}
		};

		public static Vector SceneToScreen(Vector worldPosition) {
			let viewProjectionMatrix = projection * (basis.Transpose() * Matrix4.Translation(-position));
			let viewPosition = viewProjectionMatrix * Vector4(worldPosition, 1);

			if (viewPosition.w < 0) {
				return .Zero;
			}

			return .((viewPosition.x / viewPosition.w + 1) * WindowApp.width / 2, (1 - viewPosition.y / viewPosition.w) * WindowApp.height / 2, orthographic ? viewPosition.z * size : viewPosition.w);
		}

		public static float SceneSizeToScreenSize(float size, float depth) {
			return size * WindowApp.height / (orthographic ? Camera.size / 2 : (depth * Math.Tan(fov * (Math.PI_f / 180) / 2) * 2));
		}
	}
}
