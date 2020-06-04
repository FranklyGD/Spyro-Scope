using System;

namespace SpyroScope {
	struct MatrixInt {
		public struct Column {
			public int16 x,y,z;
		}

		public Column x,y,z;

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
