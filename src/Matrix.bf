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
	}
}
