using System;

namespace SpyroScope {
	struct Vector3 {
		public float x,y,z;

		public this(float x, float y , float z) {
			this.x = x;
			this.y = y;
			this.z = z;
		}

		public static Self Zero {
			get { return .(0,0,0); }
		}

		public override void ToString(String strBuffer) {
			strBuffer.AppendF("<{},{},{}>", x, y, z);
		}

		public float LengthSq() {
			return x * x + y * y + z * z;
		}

		public float Length() {
			return Math.Sqrt(LengthSq());
		}

		public Self Normalized() {
			return this / Length();
		}

		public static implicit operator Self(Vector3Int v) {
			return .(v.x,v.y,v.z);
		}

		public static implicit operator Self(Vector4 v) {
			return .(v.x/v.w,v.y/v.w,v.z/v.w);
		}

		public static Self operator -(Self v) {
			return .(- v.x, - v.y, - v.z);
		}

		public static Self operator +(Self left, Self right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z);
		}

		public static Self operator -(Self left, Self right) {
			return .(left.x - right.x, left.y - right.y, left.z - right.z);
		}

		public static Self operator *(Self left, float right) {
			return .(left.x * right, left.y * right, left.z * right);
		}

		public static Self operator /<T>(Self left, T right) where float : operator float/T {
			return .(left.x / right, left.y / right, left.z / right);
		}

		public static Self operator *(Self left, Self right) {
			return .(left.x * right.x, left.y * right.y, left.z * right.z);
		}

		public static float Dot(Self left, Self right) {
			return left.x * right.x + left.y * right.y + left.z * right.z;
		}

		public static Self Cross(Self left, Self right) {
			return .(
				left.y * right.z - left.z * right.y,
				left.z * right.x - left.x * right.z,
				left.x * right.y - left.y * right.x
			);
		}

		public static float RayPlaneIntersect(Self rayOrigin, Self rayDirection, Self planeOrigin, Self planeNormal) {
			return Dot(planeOrigin, rayOrigin - planeOrigin) / Dot(planeOrigin, rayDirection);
		}
	}
}
