namespace SpyroScope {
	struct PackedTriangle {
		VectorInt data;

		// Derived from Spyro: Ripto's Rage [8001c214]
		// Animated version from [80022e70]
		public VectorInt[3] Unpack(bool animated) {
			VectorInt[3] triangle;

			let x = data.x & 0x3fff;
			let y = data.y & 0x3fff;

			triangle[0].x = x << 4;
			triangle[0].y = y << 4;

			triangle[1].x = (((data.x << 9) >> 23) + x) << 4;
			triangle[1].y = (((data.y << 9) >> 23) + y) << 4;

			triangle[2].x = ((data.x >> 23) + x) << 4;
			triangle[2].y = ((data.y >> 23) + y) << 4;

			if (animated) {
				let z = data.z & 0x1fff;

				triangle[0].z = z << 4;
				triangle[1].z = (((data.z << 9) >> 23) + z) << 4;
				triangle[2].z = ((data.z >> 23) + z) << 4;
			} else {
				let z = data.z & 0x3fff;

				triangle[0].z = z << 4;
				triangle[1].z = ((int32)((uint32)(data.z << 8) >> 24) + z) << 4;
				triangle[2].z = ((int32)((uint32)data.z >> 24) + z) << 4;
			}

			return triangle;
		}

		public void Pack(VectorInt[3] triangle) mut {
			let x = triangle[0].x >> 4;
			let y = triangle[0].y >> 4;
			let z = triangle[0].z >> 4;
		}
	}
}
