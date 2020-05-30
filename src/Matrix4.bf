using System;

namespace SpyroScope {
	struct Matrix4 {
		public Vector4 x,y,z,w;

		public this(Vector4 x, Vector4 y, Vector4 z, Vector4 w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public static Matrix4 Identity {
			get {
			    return .(
					.(1,0,0,0),
					.(0,1,0,0),
					.(0,0,1,0),
					.(0,0,0,1)
				);
			}
		}

		public static implicit operator Matrix4(Matrix m) {
			return .(
				m.x,
				m.y,
				m.z,
				.(0,0,0,1)
			);
		}

		public Matrix4 Translate(Vector translation) {
			Matrix4 t = .(
				.(1,0,0,0),
				.(0,1,0,0),
				.(0,0,1,0),
				.(translation.x,translation.y,translation.z,1)
			);

			return this * t;
		}

		public static Matrix4 Perspective(float FoV, float aspect, float near, float far) {
			let tanFoV2 = Math.Tan(FoV / 2);
			let space = far - near;
			return .(
				.(1f / (aspect * tanFoV2),0,0,0),
				.(0,1f / tanFoV2,0,0),
				.(0,0,-(far + near) / space,-1),
				.(0,0,-(2 * far * near) / space,0)
			);
		}

		public static Matrix4 operator *(Matrix4 left, Matrix4 right) {
			var left, right;
			float* l = (float*)&left;
			float* r = (float*)&right;
			Matrix4 m = ?;
			float* f = (float*)&m;

			for (int i < 4) {
				for (int j < 4) {
					float sum = 0;
					for (int k < 4) {
						sum += *(l + i + k * 4) * *(r + k + j * 4);
					}
					*(f + i + j * 4) = sum;
				}
			}
			return m;
		}
	}
}
