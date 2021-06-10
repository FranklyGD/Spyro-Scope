using System;

namespace SpyroScope {
	struct Matrix4 {
		public Vector4 x,y,z,w;
		
		[Inline]
		public this(Vector4 x, Vector4 y, Vector4 z, Vector4 w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public static Self Identity {
			[Inline]
			get {
			    return .(
					.(1,0,0,0),
					.(0,1,0,0),
					.(0,0,1,0),
					.(0,0,0,1)
				);
			}
		}
		
		[Inline]
		public static implicit operator Self(Matrix3 m) {
			return .(
				.(m.x,0),
				.(m.y,0),
				.(m.z,0),
				.(0,0,0,1)
			);
		}
		
		[Inline]
		public static Self Translation(Vector3 translation) {
			return .(
				.(1,0,0,0),
				.(0,1,0,0),
				.(0,0,1,0),
				.(translation.x,translation.y,translation.z,1)
			);
		}
		
		[Inline]
		public static Self Perspective(float FoV, float aspect, float near, float far) {
			let tanFoV2 = Math.Tan(FoV / 2);
			let space = far - near;
			return .(
				.(1f / (aspect * tanFoV2),0,0,0),
				.(0,1f / tanFoV2,0,0),
				.(0,0,-(far) / space,-1),
				.(0,0,-(far * near) / space,0)
			);
		}
		
		[Inline]
		public static Self PerspectiveAlt(float FoV, float aspect, float near, float far) {
			let tanFoV2 = Math.Tan(FoV / 2);
			let space = far - near;
			return .(
				.(1f / (tanFoV2),0,0,0),
				.(0,aspect / tanFoV2,0,0),
				.(0,0,-(far) / space,-1),
				.(0,0,-(far * near) / space,0)
			);
		}
		
		[Inline]
		public static Self Orthographic(float width, float height, float near, float far) {
			let space = far - near;
			return .(
				.(2f / width,0,0,0),
				.(0,2f / height,0,0),
				.(0,0,-2f / space,0),
				.(0,0,-(far + near) / space,1)
			);
		}
		
		[Inline]
		public static Self Screen(float width, float height) {
			return .(
				.(2f / width,0,0,0),
				.(0,2f / -height,0,0),
				.(0,0,-1,0),
				.(-1,1,0,1)
			);
		}

		public static Self operator *(Self left, Self right) {
			var left, right;
			float* l = (float*)&left;
			float* r = (float*)&right;
			Self m = ?;
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
		
		[Inline]
		public static Vector4 operator *(Self left, Vector4 right) {
			return left.x * right.x + left.y * right.y + left.z * right.z + left.w * right.w;
		}

		public Self Inverse() {
			Self inverse = ?;

			let s0 = x.x * y.y - y.x * x.y;
			let s1 = x.x * y.z - y.x * x.z;
			let s2 = x.x * y.w - y.x * x.w;
			let s3 = x.y * y.z - y.y * x.z;
			let s4 = x.y * y.w - y.y * x.w;
			let s5 = x.z * y.w - y.z * x.w;

			let c5 = x.z * w.w - w.z * z.w;
			let c4 = z.y * w.w - w.y * z.w;
			let c3 = z.y * w.z - w.y * z.z;
			let c2 = z.x * w.w - w.x * z.w;
			let c1 = z.x * w.z - w.x * z.z;
			let c0 = z.x * w.y - w.x * z.y;

			let determinant = s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0;
			if (determinant == 0) {
				return this;
			}
			let determinantInv = 1f / determinant;

			inverse.x.x = (y.y * c5 - y.z * c4 + y.w * c3) * determinantInv;
			inverse.x.y = (-x.y * c5 + x.z * c4 - x.w * c3) * determinantInv;
			inverse.x.z = (w.y * s5 - w.z * s4 + w.w * s3) * determinantInv;
			inverse.x.w = (-z.y * s5 + z.z * s4 - z.w * s3) * determinantInv;

			inverse.y.x = (-y.x * c5 + y.z * c2 - y.w * c1) * determinantInv;
			inverse.y.y = (x.x * c5 - x.z * c2 + x.w * c1) * determinantInv;
			inverse.y.z = (-w.x * s5 + w.z * s2 - w.w * s1) * determinantInv;
			inverse.y.w = (z.x * s5 - z.z * s2 + z.w * s1) * determinantInv;

			inverse.z.x = (y.x * c4 - y.y * c2 + y.w * c0) * determinantInv;
			inverse.z.y = (-x.x * c4 + x.y * c2 - x.w * c0) * determinantInv;
			inverse.z.z = (w.x * s4 - w.y * s2 + w.w * s0) * determinantInv;
			inverse.z.w = (-z.x * s4 + z.y * s2 - z.w * s0) * determinantInv;

			inverse.w.x = (-y.x * c3 + y.y * c1 - y.z * c0) * determinantInv;
			inverse.w.y = (x.x * c3 - x.y * c1 + x.z * c0) * determinantInv;
			inverse.w.z = (-w.x * s3 + w.y * s1 - w.z * s0) * determinantInv;
			inverse.w.w = (z.x * s3 - z.y * s1 + z.z * s0) * determinantInv;

			return inverse;
		}
	}
}
