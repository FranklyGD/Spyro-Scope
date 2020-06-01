using System;

namespace SpyroScope {
	struct Vector {
		public float x,y,z;

		public this(float x, float y , float z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public static Vector Zero {
			get { return .(1,0,0); }
		}

		public override void ToString(System.String strBuffer) {
			strBuffer.AppendF("<{},{},{}>", x, y, z);
		}

		public VectorInt ToVectorInt() {
			return .((.)x,(.)y,(.)z);
		}

		public float LengthSq() {
			return x * x + y * y + z * z;
		}

		public float Length() {
			return Math.Sqrt(LengthSq());
		}

		public Vector Normalized() {
			return this / Length();
		}

		public static implicit operator Vector(VectorInt v) {
			return Vector(v.x,v.y,v.z);
		}

		public static Vector operator -(Vector value) {
			return .(- value.x, - value.y, - value.z);
		}

		public static Vector operator +(Vector left, Vector right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z);
		}

		public static Vector operator -(Vector left, Vector right) {
			return .(left.x - right.x, left.y - right.y, left.z - right.z);
		}

		public static Vector operator *(Vector left, float right) {
			return .(left.x * right, left.y * right, left.z * right);
		}

		public static Vector operator /(Vector left, float right) {
			return .(left.x / right, left.y / right, left.z / right);
		}

		public static Vector operator *(Vector left, Vector right) {
			return .(left.x * right.x, left.y * right.y, left.z * right.z);
		}

		public static float Dot(Vector left, Vector right) {
			return left.x * right.x + left.y * right.y + left.z * right.z;
		}

		public static Vector Cross(Vector left, Vector right) {
			return Vector(
				left.y * right.z - left.z * right.y,
				left.z * right.x - left.x * right.z,
				left.x * right.y - left.y * right.x
			);
		}
	}
}
