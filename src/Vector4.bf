namespace SpyroScope {
	struct Vector4 {
		public float x,y,z,w;

		public this(float x, float y, float z, float w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}

		public static implicit operator Vector4(Vector v) {
			return Vector4(v.x,v.y,v.z,0);
		}
	}
}
