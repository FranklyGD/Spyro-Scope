using System;

namespace SpyroScope {
	struct Vector2 {
		public float x,y;

		public this(float x, float y) {
			this.x = x;
			this.y = y;
		}

		public static Self Zero {
			get { return .(0,0); }
		}

		public override void ToString(String strBuffer) {
			strBuffer.AppendF("<{},{},{}>", x, y);
		}

		public float LengthSq() {
			return x * x + y * y;
		}

		public float Length() {
			return Math.Sqrt(LengthSq());
		}

		public Self Normalized() {
			return this / Length();
		}

		public static explicit operator Self(Vector3 v) {
			return .(v.x,v.y);
		}

		public static Self operator -(Self v) {
			return .(- v.x, - v.y);
		}

		public static Self operator +(Self left, Self right) {
			return .(left.x + right.x, left.y + right.y);
		}

		public static Self operator -(Self left, Self right) {
			return .(left.x - right.x, left.y - right.y);
		}

		public static Self operator *(Self left, float right) {
			return .(left.x * right, left.y * right);
		}

		public static Self operator /<T>(Self left, T right) where float : operator float/T {
			return .(left.x / right, left.y / right);
		}

		public static Self operator *(Self left, Self right) {
			return .(left.x * right.x, left.y * right.y);
		}

		public static float Dot(Self left, Self right) {
			return left.x * right.x + left.y * right.y;
		}
	}
}
