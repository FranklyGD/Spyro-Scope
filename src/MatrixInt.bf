using System;

namespace SpyroScope {
	struct MatrixInt {
		public struct Row {
			public int16 x,y,z;
		}

		public Row x,y,z;

		public MatrixInt Inverse() {
			MatrixInt inverse = ?;

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

		public Matrix ToMatrix() {
			Matrix matrix = ?;

			matrix.x.x = ToFloat!(x.x);
			matrix.x.y = ToFloat!(x.y);
			matrix.x.z = ToFloat!(x.z);
			
			matrix.y.x = ToFloat!(y.x);
			matrix.y.y = ToFloat!(y.y);
			matrix.y.z = ToFloat!(y.z);
			
			matrix.z.x = ToFloat!(z.x);
			matrix.z.y = ToFloat!(z.y);
			matrix.z.z = ToFloat!(z.z);

			return matrix;
		}

		public Matrix ToMatrixCorrected() {
			Matrix matrix = ?;

			matrix.x.x = ToFloat!(x.z);
			matrix.x.y = -ToFloat!(x.x);
			matrix.x.z = -ToFloat!(x.y);

			matrix.y.x = -ToFloat!(y.z);
			matrix.y.y = ToFloat!(y.x);
			matrix.y.z = ToFloat!(y.y);

			matrix.z.x = -ToFloat!(z.z);
			matrix.z.y = ToFloat!(z.x);
			matrix.z.z = ToFloat!(z.y);

			return matrix;
		}

		mixin ToFloat(int16 value) {
			(float)value / 0x1000
		}
	}
}
