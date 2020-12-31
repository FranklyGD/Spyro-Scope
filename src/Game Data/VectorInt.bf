using System;

namespace SpyroScope {
	struct Vector3Int {
		public int32 x,y,z;

		public this(int32 x, int32 y, int32 z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public override void ToString(System.String strBuffer) {
			strBuffer.AppendF("<{},{},{}>", x, y, z);
		}

		public int64 LengthSq() {
			return (int64)x * x + (int64)y * y + (int64)z * z;
		}

		public float Length() {
			return Math.Sqrt(LengthSq());
		}

		public static explicit operator Self(Vector3 v) {
			return .((.)Math.Round(v.x),(.)Math.Round(v.y),(.)Math.Round(v.z));
		}

		public static Self operator -(Self v) {
			return .(- v.x , - v.y, - v.z);
		}

		public static Self operator +(Self left, Self right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z);
		}

		public static Self operator -(Self left, Self right) {
			return .(left.x - right.x, left.y - right.y, left.z - right.z);
		}

		public static Self operator *(Self left, int32 right) {
			return .(left.x * right, left.y * right, left.z * right);
		}

		public static Self operator /(Self left, int32 right) {
			if (right == 0)
				return left;
			return .(left.x / right, left.y / right, left.z / right);
		}
	}
}
