using System;

namespace SpyroScope {
	class RegionVerticalWarper {
		uint8 regionIndex;
		uint32[] timeOffsets ~ delete _;

		public this(uint8 regionIndex, uint32[] timeOffsets) {
			this.regionIndex = regionIndex;
			this.timeOffsets = timeOffsets;
		}
		
		// Derived from Spyro: Ripto's Rage [80023994]
		public void Update(uint32 clock) {
			//if (renderingFlags[regionIndex] & 1 > 0) { 
			let region = Terrain.regions[regionIndex];
			for (let i < (uint8)timeOffsets.Count) {
				let timeOffset = timeOffsets[i];
				Vector3Int vertex = region.GetNearVertex(i);

				let time = (float)(clock + timeOffset) / 0x80 * Math.PI_f;
				let baseHeight = timeOffset >> 16;
				vertex.z = (((int32)(Math.Cos(time) * 0x1000) * 0x140 >> 0x10) + (int32)baseHeight) << 1;

				region.SetNearVertex(i, vertex, false);
			}

			region.UpdateSubdividedVertex(false);
			region.UpdateSubdividedVertex(true);
			//}
			// Make it update regardless in program regardless if it is rendering in game or not
			// Commented code is part of the derived code
		}

		public void SetDefault() {
			let region = Terrain.regions[regionIndex];
			for (let i < (uint8)timeOffsets.Count) {
				let timeOffset = timeOffsets[i];
				Vector3Int vertex = region.GetNearVertex(i);

				let baseHeight = timeOffset >> 16;
				vertex.z = (int32)baseHeight << 1;

				region.SetNearVertex(i, vertex, false);
			}

			region.UpdateSubdividedVertex(false);
			region.UpdateSubdividedVertex(true);
		}
	}
}
