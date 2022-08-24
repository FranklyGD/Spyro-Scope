using System;
using System.Collections;

namespace SpyroScope {
	class RegionWarper {
		uint8 regionIndex;
		Dictionary<uint8,uint32> timeOffsets ~ delete _;
		Vector3Int[] basePositions ~ delete _;
		
		public this(uint8 regionIndex, Dictionary<uint8,uint32> timeOffsets, Vector3Int[] basePositions) {
			this.regionIndex = regionIndex;
			this.timeOffsets = timeOffsets;
			this.basePositions = basePositions;
		}

		// Derived from Spyro: Ripto's Rage [80023a9c]
		public void Update(uint32 clock) {
			//if (renderingFlags[regionIndex] & 1 > 0)
			let region = Terrain.regions[regionIndex];
			var i = 0;
			for (let timeOffset in timeOffsets) {
				var vertex = basePositions[i];

				float t = (float)(clock + timeOffset.value) / 0x80 * Math.PI_f;
				vertex.x += (int32)(Math.Sin(t + Math.PI_f / 4) * 0x1000) >> 8;
				vertex.y += (int32)(Math.Sin(t) * 0x1000) >> 8;
				vertex.z += (int32)(Math.Cos(t) * 0x1000) >> 10;
				
				region.SetNearVertex(timeOffset.key, vertex, false);
				i++;
			}

			region.UpdateSubdividedVertex(false);
			region.UpdateSubdividedVertex(true);
			//}
			// Make it update regardless in program regardless if it is rendering in game or not
			// Commented code is part of the derived code
		}

		public void SetDefault() {
			let region = Terrain.regions[regionIndex];
			var i = 0;
			for (let timeOffset in timeOffsets) {
				region.SetNearVertex(timeOffset.key, basePositions[i++], false);
			}

			region.UpdateSubdividedVertex(false);
			region.UpdateSubdividedVertex(true);
		}
	}
}
