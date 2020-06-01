using System;

namespace SpyroScope {
	struct Matrix {
		public Vector x,y,z;

		public this(Vector x, Vector y, Vector z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public static Matrix Identity {
			get {
			    return .(
					.(1,0,0),
					.(0,1,0),
					.(0,0,1)
				);
			}
		}

		public static Matrix Euler(float roll, float pitch, float yaw) {
			let sinRoll = Math.Sin(roll);
			let cosRoll = Math.Cos(roll);
			let sinPitch = Math.Sin(pitch);
			let cosPitch = Math.Cos(pitch);
			let sinYaw = Math.Sin(yaw);
			let cosYaw = Math.Cos(yaw);

			return .(
				.(cosYaw * cosPitch, -cosPitch * sinYaw, sinPitch),
				.(cosRoll * sinYaw + cosYaw * sinRoll * sinPitch, cosRoll * cosYaw - sinRoll * sinPitch * sinYaw, -cosPitch * sinRoll),
				.(sinRoll * sinYaw - cosRoll * cosYaw * sinPitch, cosYaw * sinRoll + cosRoll * sinPitch * sinYaw, cosRoll * cosPitch)
			);
		}

		public static Matrix Scale(float x, float y, float z) {
			return .(
				.(x,0,0),
				.(0,y,0),
				.(0,0,z)
			);
		}

		public Matrix Inverse() {
			Matrix inverse = ?;

			inverse.x.x = x.x;
			inverse.x.y = y.x;
			inverse.x.z = z.x;

			inverse.y.x = x.y;
			inverse.y.y = y.y;
			inverse.y.z = z.y;
			
			inverse.z.x = x.z;
			inverse.z.y = y.z;
			inverse.z.z = z.z;

			return inverse;
		}

		public Matrix Orthonormalized() {
			let right = Vector.Cross(z, y);
			let up = Vector.Cross(z, right);
			return .(right.Normalized(), up.Normalized(), z.Normalized());
		}

		public static Matrix operator *(Matrix left, float right) {
			return .(left.x * right, left.y * right, left.z * right);
		}

		public static Vector operator *(Matrix left, Vector right) {
			return left.x * right.x + left.y * right.y + left.z * right.z;
		}

		public static Matrix operator *(Matrix left, Matrix right) {
			var left, right;
			float* l = (float*)&left;
			float* r = (float*)&right;
			Matrix m = ?;
			float* f = (float*)&m;

			for (int i < 3) {
				for (int j < 3) {
					float sum = 0;
					for (int k < 3) {
						sum += *(l + i + k * 3) * *(r + k + j * 3);
					}
					*(f + i + j * 3) = sum;
				}
			}
			return m;
		}
	}
}
