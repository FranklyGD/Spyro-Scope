using System;

namespace SpyroScope {
	struct Vector4 {
		public float x,y,z,w;
		
		[Inline]
		public this(float x, float y, float z, float w) {
			this.x = x;
			this.y = y;
			this.z = z;
			this.w = w;
		}
		
		[Inline]
		public this(Vector3 v, float w) {
			this.x = v.x;
			this.y = v.y;
			this.z = v.z;
			this.w = w;
		}
		
		[Inline]
		public override void ToString(String strBuffer) {
			strBuffer.AppendF($"<{x},{y},{z},{w}>");
		}
		
		[Inline]
		public static Self operator +(Self left, Self right) {
			return .(left.x + right.x, left.y + right.y, left.z + right.z, left.w + right.w);
		}
		
		[Inline]
		public static Self operator *(Self left, float right) {
			return .(left.x * right, left.y * right, left.z * right, left.w * right);
		}
	}
}
