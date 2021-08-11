using System;

namespace SpyroScope {
	struct Matrix3 {
		public Vector3 x,y,z;
		
		[Inline]
		public this(Vector3 x, Vector3 y, Vector3 z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public static Self Identity {
			[Inline]
			get {
			    return .(
					.(1,0,0),
					.(0,1,0),
					.(0,0,1)
				);
			}
		}

		public static Self Euler(float x, float y, float z) {
			let sx = Math.Sin(x);
			let cx = Math.Cos(x);
			let sy = Math.Sin(y);
			let cy = Math.Cos(y);
			let sz = Math.Sin(z);
			let cz = Math.Cos(z);

			return .(
				.(cz * cy, -cy * sz, sy),
				.(cx * sz + cz * sx * sy, cx * cz - sx * sy * sz, -cy * sx),
				.(sx * sz - cx * cz * sy, cz * sx + cx * sy * sz, cx * cy)
			);
		}

		[Inline]
		public static Self Euler(Vector3 euler) {
			return Euler(euler.x, euler.y, euler.z);
		}
		
		[Inline]
		public static Self Scale(float x, float y, float z) {
			return .(
				.(x,0,0),
				.(0,y,0),
				.(0,0,z)
			);
		}
		
		[Inline]
		public static Self Scale(float scale) {
			return .(
				.(scale,0,0),
				.(0,scale,0),
				.(0,0,scale)
			);
		}
		
		[Inline]
		public static Self Scale(Vector3 scale) {
			return .(
				.(scale.x,0,0),
				.(0,scale.y,0),
				.(0,0,scale.z)
			);
		}
		
		[Inline]
		public Self Transpose() {
			Self transpose = ?;

			transpose.x.x = x.x;
			transpose.x.y = y.x;
			transpose.x.z = z.x;

			transpose.y.x = x.y;
			transpose.y.y = y.y;
			transpose.y.z = z.y;
			
			transpose.z.x = x.z;
			transpose.z.y = y.z;
			transpose.z.z = z.z;

			return transpose;
		}

		public Self Orthonormalized() {
			let right = Vector3.Cross(z, y);
			let up = Vector3.Cross(z, right);
			return .(right.Normalized(), up.Normalized(), z.Normalized());
		}
		
		[Inline]
		public static Self operator *(Self left, float right) {
			return .(left.x * right, left.y * right, left.z * right);
		}
		
		[Inline]
		public static Vector3 operator *(Self left, Vector3 right) {
			return left.x * right.x + left.y * right.y + left.z * right.z;
		}

		public static Self operator *(Self left, Self right) {
			var left, right;
			float* l = (float*)&left;
			float* r = (float*)&right;
			Self m = ?;
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

		// NOTE: Currently used for converting to camera matrix,
		// may not be accurate or appropriate place for this
		[Inline]
		public MatrixInt ToMatrixIntCorrected() {
			MatrixInt matrix = ?;

			matrix.x.x = ToInt(y.y);
			matrix.x.y = ToInt(y.z);
			matrix.x.z = ToInt(y.x);

			matrix.y.x = ToInt(z.y);
			matrix.y.y = ToInt(z.z);
			matrix.y.z = ToInt(z.x);

			matrix.z.x = ToInt(x.y);
			matrix.z.y = ToInt(x.z);
			matrix.z.z = ToInt(x.x);

			return matrix;
		}
		
		[Inline]
		int16 ToInt(float value) {
			return (.)(value * 0x1000);
		}
	}
}
