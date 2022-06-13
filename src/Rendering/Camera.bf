using System;

namespace SpyroScope {
	static struct Camera {
		public static Vector3 position;
		public static Matrix3 basis;
		public static bool orthographic;
		public static float size;
		public static float fov;
		public static float near = 200;
		public static float far = 200000;

		public static Matrix4 projection {
			get {
				let aspect = (float)WindowApp.width / WindowApp.height;
				return orthographic ?
				aspect > 1 ?
					.Orthographic(size * aspect, size, near, far):
					.Orthographic(size, size / aspect, near, far):
				aspect > 1 ?
					.Perspective(fov * Math.PI_f / 180, aspect, near, far):
					.PerspectiveAlt(fov * Math.PI_f / 180, aspect, near, far);
			}
		};

		public static Vector3 SceneToScreen(Vector3 worldPosition) {
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

		public static Vector3 ScreenPointToOrigin(Vector2 screenPosition) {
			if (orthographic) {
				let x = 0.5f - (screenPosition.x / WindowApp.width);
				let y = screenPosition.y / WindowApp.height - 0.5f;

				let aspect = (float)WindowApp.width / WindowApp.height;
				return position - basis.x * x * aspect * size - basis.y * y * size;
			} else {
				return position;
			}
		}

		public static Vector3 ScreenPointToRay(Vector2 screenPosition) {
			if (orthographic) {
				return -basis.z;
			} else {
				let x = 1 - (screenPosition.x / WindowApp.width * 2);
				let y = screenPosition.y / WindowApp.height * 2 - 1;
				let tangent = Math.Tan(fov * Math.PI_f / 360);
	
				let aspect = (float)WindowApp.width / WindowApp.height;
				return aspect > 1 ?
					basis * Vector3(-x * tangent * aspect, -y * tangent, -1):
					basis * Vector3(-x * tangent, -y * tangent / aspect, -1);
			}
		}
	}
}
