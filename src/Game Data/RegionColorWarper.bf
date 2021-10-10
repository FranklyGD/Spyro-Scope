using System;

namespace SpyroScope {
	class RegionColorWarper {
		public static Renderer.Color4 targetColor;
		
		uint8 regionIndex;
		uint8[] timeOffsets ~ delete _;
		Renderer.Color4[] baseColors ~ delete _;

		public this(uint8 regionIndex, uint8[] timeOffsets, Renderer.Color4[] baseColors) {
			this.regionIndex = regionIndex;
			this.timeOffsets = timeOffsets;
			this.baseColors = baseColors;
		}

		// Derived from Spyro: Ripto's Rage [80023a9c]
		public void Update(uint32 clock) {
			//if (renderingFlags[regionIndex] & 1 > 0)
			let region = Terrain.regions[regionIndex];
			var i = 0;
			for (let timeOffset in timeOffsets) {
				uint32 colorClock;
				let o = timeOffsets[i] & 3;
				if (o == 3) {
					colorClock = clock * 3;
				} else if (o > 0) {
					colorClock = clock * 2;
				} else {
					colorClock = clock;
				}

				let alpha = (Math.Cos((float)((uint32)timeOffset + colorClock) / 0x80 * Math.PI_f) + 1) / 4;

				region.SetNearColor((.)i, Renderer.Color.Lerp(baseColors[i], targetColor, alpha), false);
				i++;
			}

			region.UpdateSubdividedColor(false);
			region.UpdateSubdividedColor(true);
			//}
			// Make it update regardless in program regardless if it is rendering in game or not
			// Commented code is part of the derived code
		}
	}
}
