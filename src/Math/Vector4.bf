namespace SpyroScope {
	struct Vector4 {
		public float x,y,z,w;

		public this(float x, float y, float z, float w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public this(Vector v, float w) {
			this.x = v.x;
			this.y = v.y;
			this.z = v.z;
			this.w = w;
		}

		public override void ToString(System.String strBuffer) {
			strBuffer.AppendF("<{},{},{},{}>", x, y, z, w);
		}

		public static implicit operator Vector4(Vector v) {
			return Vector4(v.x,v.y,v.z,0);
		}

		public static Vector4 operator +(Vector4 left, Vector4 right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z, left.w + right.w);
		}

		public static Vector4 operator *(Vector4 left, float right) {
			return .(left.x * right, left.y * right, left.z * right, left.w * right);
		}
	}
}
