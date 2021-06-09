namespace SpyroScope {
	struct CollisionTriangle {
		public int32 x, y, z;

		// Derived from Spyro: Ripto's Rage [8001c214]
		public Vector3Int[3] Unpack() {
			Vector3Int[3] triangle;

			let z = this.z & 0x3fff;

			triangle[0].x = (this.x & 0x3fff) << 4;
			triangle[0].y = (this.y & 0x3fff) << 4;
			triangle[0].z = z << 4;

			triangle[1].x = (((this.x << 9) >> 23) << 4) + triangle[0].x; // (((data.x << 9) >> 23) + x) << 4;
			triangle[1].y = (((this.y << 9) >> 23) << 4) + triangle[0].y; // (((data.y << 9) >> 23) + y) << 4;
			triangle[1].z = ((int32)((uint32)(this.z << 8) >> 24) + z) << 4;

			triangle[2].x = ((this.x >> 23) << 4) + triangle[0].x; // ((data.x >> 23) + x) << 4;
			triangle[2].y = ((this.y >> 23) << 4) + triangle[0].y; // ((data.y >> 23) + y) << 4;
			triangle[2].z = ((int32)((uint32)this.z >> 24) + z) << 4;

			return triangle;
		}

		// Derived from Spyro: Ripto's Rage [80022e70]
		public Vector3Int[3] UnpackAnimated() {
			Vector3Int[3] triangle;

			triangle[0].x = (this.x & 0x3fff) << 4;
			triangle[0].y = (this.y & 0x3fff) << 4;
			triangle[0].z = (this.z & 0x1fff) << 4;

			triangle[1].x = (((this.x << 9) >> 23) << 4) + triangle[0].x; // (((data.x << 9) >> 23) + x) << 4;
			triangle[1].y = (((this.y << 9) >> 23) << 4) + triangle[0].y; // (((data.y << 9) >> 23) + y) << 4;
			triangle[1].z = (((this.z << 9) >> 23) << 4) + triangle[0].z; // (((data.z << 9) >> 23) + z) << 4;

			triangle[2].x = ((this.x >> 23) << 4) + triangle[0].x; // ((data.x >> 23) + x) << 4;
			triangle[2].y = ((this.y >> 23) << 4) + triangle[0].y; // ((data.y >> 23) + y) << 4;
			triangle[2].z = ((this.z >> 23) << 4) + triangle[0].z; // ((data.z >> 23) + z) << 4;

			return triangle;
		}

		public static CollisionTriangle Pack(Vector3Int[3] triangle) {
			var orderedTriangle = SortVertexOrder(triangle);
			CollisionTriangle packedTriangle = ?;

			orderedTriangle[0].x = orderedTriangle[0].x >> 4 & 0x3fff;
			orderedTriangle[0].y = orderedTriangle[0].y >> 4 & 0x3fff;
			orderedTriangle[0].z = orderedTriangle[0].z >> 4 & 0x3fff;

			orderedTriangle[1].x = ((orderedTriangle[1].x >> 4) - orderedTriangle[0].x) & 0x1ff;
			orderedTriangle[1].y = ((orderedTriangle[1].y >> 4) - orderedTriangle[0].y) & 0x1ff;
			orderedTriangle[1].z = ((orderedTriangle[1].z >> 4) - orderedTriangle[0].z) & 0xff;

			orderedTriangle[2].x = (orderedTriangle[2].x >> 4) - orderedTriangle[0].x;
			orderedTriangle[2].y = (orderedTriangle[2].y >> 4) - orderedTriangle[0].y;
			orderedTriangle[2].z = (orderedTriangle[2].z >> 4) - orderedTriangle[0].z;

			packedTriangle.x = orderedTriangle[2].x << 23 | orderedTriangle[1].x << 14 | orderedTriangle[0].x;
			packedTriangle.y = orderedTriangle[2].y << 23 | orderedTriangle[1].y << 14 | orderedTriangle[0].y;
			packedTriangle.z = orderedTriangle[2].z << 24 | orderedTriangle[1].z << 16 | orderedTriangle[0].z;

			return packedTriangle;
		}

		public static CollisionTriangle PackAnimated(Vector3Int[3] triangle) {
			var orderedTriangle = SortVertexOrder(triangle);
			CollisionTriangle packedTriangle = ?;

			orderedTriangle[0].x = orderedTriangle[0].x >> 4 & 0x3fff;
			orderedTriangle[0].y = orderedTriangle[0].y >> 4 & 0x3fff;
			orderedTriangle[0].z = orderedTriangle[0].z >> 4 & 0x1fff;

			orderedTriangle[1].x = ((orderedTriangle[1].x >> 4) - orderedTriangle[0].x) & 0x1ff;
			orderedTriangle[1].y = ((orderedTriangle[1].y >> 4) - orderedTriangle[0].y) & 0x1ff;
			orderedTriangle[1].z = ((orderedTriangle[1].z >> 4) - orderedTriangle[0].z) & 0x1ff;

			orderedTriangle[2].x = (orderedTriangle[2].x >> 4) - orderedTriangle[0].x;
			orderedTriangle[2].y = (orderedTriangle[2].y >> 4) - orderedTriangle[0].y;
			orderedTriangle[2].z = (orderedTriangle[2].z >> 4) - orderedTriangle[0].z;

			packedTriangle.x = orderedTriangle[2].x << 23 | orderedTriangle[1].x << 14 | orderedTriangle[0].x;
			packedTriangle.y = orderedTriangle[2].y << 23 | orderedTriangle[1].y << 14 | orderedTriangle[0].y;
			packedTriangle.z = orderedTriangle[2].z << 23 | orderedTriangle[1].z << 14 | orderedTriangle[0].z;

			return packedTriangle;
		}

		/// Create new vertex order for a triangle where the first vertex will become the lowest
		public static Vector3Int[3] SortVertexOrder(Vector3Int[3] triangle) {
			Vector3Int[3] orderedTriangle;
	
			// Find lowest vertex
			// Derived from Spyro: Ripto's Rage [80023014]
			if (triangle[1].z < triangle[0].z || triangle[2].z < triangle[0].z) {
				if (triangle[2].z < triangle[1].z) {
					orderedTriangle[0] = triangle[2];
					orderedTriangle[1] = triangle[0];
					orderedTriangle[2] = triangle[1];
				} else {
					orderedTriangle[0] = triangle[1];
					orderedTriangle[1] = triangle[2];
					orderedTriangle[2] = triangle[0];
				}
			} else {
				orderedTriangle[0] = triangle[0];
				orderedTriangle[1] = triangle[1];
				orderedTriangle[2] = triangle[2];
			}

			return orderedTriangle;
		}
	}
}
