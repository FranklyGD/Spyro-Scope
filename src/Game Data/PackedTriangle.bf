namespace SpyroScope {
	struct CollisionTriangle {
		public int32 x, y, z;

		// Derived from Spyro: Ripto's Rage [8001c214]
		// Animated version from [80022e70]
		public VectorInt[3] Unpack(bool animated) {
			VectorInt[3] triangle;

			let x = this.x & 0x3fff;
			let y = this.y & 0x3fff;

			triangle[0].x = x << 4;
			triangle[0].y = y << 4;

			triangle[1].x = (((this.x << 9) >> 23) << 4) + triangle[0].x; //triangle[1].x = (((data.x << 9) >> 23) + x) << 4;
			triangle[1].y = (((this.y << 9) >> 23) << 4) + triangle[0].y; //triangle[1].y = (((data.y << 9) >> 23) + y) << 4;

			triangle[2].x = ((this.x >> 23) << 4) + triangle[0].x; //triangle[2].x = ((data.x >> 23) + x) << 4;
			triangle[2].y = ((this.y >> 23) << 4) + triangle[0].y; //triangle[2].y = ((data.y >> 23) + y) << 4;

			if (animated) {
				let z = this.z & 0x1fff;

				triangle[0].z = z << 4;
				triangle[1].z = (((this.z << 9) >> 23) << 4) + triangle[0].z; //(((data.z << 9) >> 23) + z) << 4;
				triangle[2].z = ((this.z >> 23) << 4) + triangle[0].z; //((data.z >> 23) + z) << 4;
			} else {
				let z = this.z & 0x3fff;

				triangle[0].z = z << 4;
				triangle[1].z = ((int32)((uint32)(this.z << 8) >> 24) + z) << 4;
				triangle[2].z = ((int32)((uint32)this.z >> 24) + z) << 4;
			}

			return triangle;
		}

		public static CollisionTriangle Pack(VectorInt[3] triangle, bool animated) {
			var triangle;
			CollisionTriangle packedTriangle = ?;

			triangle[0].x = triangle[0].x >> 4 & 0x3fff;
			triangle[0].y = triangle[0].y >> 4 & 0x3fff;

			triangle[1].x = ((triangle[1].x >> 4) - triangle[0].x) & 0x1ff;
			triangle[1].y = ((triangle[1].y >> 4) - triangle[0].y) & 0x1ff;

			triangle[2].x = (triangle[2].x >> 4) - triangle[0].x;
			triangle[2].y = (triangle[2].y >> 4) - triangle[0].y;

			packedTriangle.x = triangle[2].x << 23 | triangle[1].x << 14 | triangle[0].x;
			packedTriangle.y = triangle[2].y << 23 | triangle[1].y << 14 | triangle[0].y;

			if (animated) {
				triangle[0].z = triangle[0].z >> 4 & 0x1fff;
				triangle[1].z = ((triangle[1].z >> 4) - triangle[0].z) & 0x1ff;
				triangle[2].z = (triangle[2].z >> 4) - triangle[0].z;
				
				packedTriangle.z = triangle[2].z << 23 | triangle[1].z << 14 | triangle[0].z;
			} else {
				triangle[0].z = triangle[0].z >> 4 & 0x3fff;
				triangle[1].z = ((triangle[1].z >> 4) - triangle[0].z) & 0xff;
				triangle[2].z = (triangle[2].z >> 4) - triangle[0].z;

				packedTriangle.z = triangle[2].z << 24 | triangle[1].z << 16 | triangle[0].z;
			}

			return packedTriangle;
		}
	}
}
