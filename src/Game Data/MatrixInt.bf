using System;

namespace SpyroScope {
	struct MatrixInt {
		public struct Row {
			public int16 x,y,z;
		}

		public Row x,y,z;

		public static MatrixInt Euler(float x, float y, float z) {
			return Matrix.Euler(x,y,z).ToMatrixIntCorrected();
		}

		public MatrixInt Transpose() {
			MatrixInt transpose = ?;

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
			
			matrix.x.x = ToFloat!(z.z);
			matrix.x.y = -ToFloat!(x.z);
			matrix.x.z = -ToFloat!(y.z);
			
			matrix.y.x = -ToFloat!(z.x);
			matrix.y.y = ToFloat!(x.x);
			matrix.y.z = ToFloat!(y.x);
			
			matrix.z.x = -ToFloat!(z.y);
			matrix.z.y = ToFloat!(x.y);
			matrix.z.z = ToFloat!(y.y);

			return matrix;
		}

		mixin ToFloat(int16 value) {
			(float)value / 0x1000
		}
	}
}
