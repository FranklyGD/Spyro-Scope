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
				let aspect = (float)WindowApp.width / WindowApp.height;
				return orthographic ? .Orthographic(size * aspect, size, near, far):
				.Perspective(fov * Math.PI_f / 180, aspect, near, far);
			}
		};

		public static Vector SceneToScreen(Vector worldPosition) {
			let viewProjectionMatrix = projection * (basis.Transpose() * Matrix4.Translation(-position));
			let viewPosition = viewProjectionMatrix * Vector4(worldPosition, 1);

			if (viewPosition.w < 0) {
				return .Zero;
			}

			return .((viewPosition.x / viewPosition.w + 1) * WindowApp.width / 2, (1 - viewPosition.y / viewPosition.w) * WindowApp.height / 2, orthographic ? Math.Lerp(near, far, (viewPosition.z + 1) / 2) : viewPosition.w);
		}

		public static float SceneSizeToScreenSize(float size, float depth) {
			return size * WindowApp.height / (orthographic ? Camera.size / 2 : (depth * Math.Tan(fov * (Math.PI_f / 180) / 2) * 2));
		}

		public static Vector ScreenPointToOrigin(Vector screenPosition) {
			if (orthographic) {
				let x = 0.5f - (screenPosition.x / WindowApp.width);
				let y = screenPosition.y / WindowApp.height - 0.5f;

				let aspect = (float)WindowApp.width / WindowApp.height;
				return position - basis.x * x * aspect * size - basis.y * y * size;
			} else {
				return position;
			}
		}

		public static Vector ScreenPointToRay(Vector screenPosition) {
			if (orthographic) {
				return -basis.z;
			} else {
				let x = 1 - (screenPosition.x / WindowApp.width * 2);
				let y = screenPosition.y / WindowApp.height * 2 - 1;
				let tangent = Math.Tan(fov * Math.PI_f / 360);
	
				let aspect = (float)WindowApp.width / WindowApp.height;
				return basis * Vector(-x * tangent * aspect, -y * tangent, -1);
			}
		}
	}
}
