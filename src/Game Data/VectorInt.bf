using System;

namespace SpyroScope {
	struct VectorInt {
		public int32 x,y,z;

		public this(int32 x, int32 y, int32 z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public override void ToString(System.String strBuffer) {
			strBuffer.AppendF("<{},{},{}>", x, y, z);
		}

		public Vector ToVector() {
			return .(x, y, z);
		}

		public int64 LengthSq() {
			return (int64)x * x + (int64)y * y + (int64)z * z;
		}

		public float Length() {
			return Math.Sqrt(LengthSq());
		}

		public static VectorInt operator -(VectorInt value) {
			return .(-value.x , -value.y, -value.z);
		}

		public static VectorInt operator +(VectorInt left, VectorInt right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z);
		}

		public static VectorInt operator -(VectorInt left, VectorInt right) {
			return .(left.x - right.x, left.y - right.y, left.z - right.z);
		}

		public static VectorInt operator *(VectorInt left, int32 right) {
			return .(left.x * right, left.y * right, left.z * right);
		}

		public static VectorInt operator /(VectorInt left, int32 right) {
			if (right == 0)
				return left;
			return .(left.x / right, left.y / right, left.z / right);
		}
	}
}
