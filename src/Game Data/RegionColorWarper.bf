using System;

namespace SpyroScope {
	class RegionColorWarper {
		public static Color4 targetColor;

		Emulator.Address address;
		bool firstRun = true;
		
		uint8 regionIndex;
		uint8[] timeOffsets ~ delete _;
		Color4[] baseColors ~ delete _;

		public this(Emulator.Address address) {
			this.address = address;
		}

		// Derived from Spyro: Ripto's Rage [80023a9c]
		public void Update(uint32 clock) {
			if (firstRun) {
				Reload();
				firstRun = false;
			}

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

				region.SetNearColor((.)i, Color.Lerp(baseColors[i], targetColor, alpha), false);
				i++;
			}

			region.UpdateSubdividedColor(false);
			region.UpdateSubdividedColor(true);
			//}
			// Make it update regardless in program regardless if it is rendering in game or not
			// Commented code is part of the derived code
		}

		// Used for getting the correct data first time because
		// the color information is not loaded in game until
		// it is actually being used (being animated)
		void Reload() {
			Emulator.Address warpingRegionsDataPointer = ?;
			Emulator.active.ReadFromRAM(Emulator.active.regionsWarpPointer, &warpingRegionsDataPointer, 4);

			uint32 value = ?;
			Emulator.active.ReadFromRAM(address, &value, 4);

			Emulator.Address colorInfoScan = warpingRegionsDataPointer + (2 + (value >> 16)) * 4;
			Emulator.Address colorInfoEnd = colorInfoScan + (value >> 8 & 0xff) * 4;
			regionIndex = (.)value;

			delete timeOffsets;
			delete baseColors;

			let count = (colorInfoEnd - colorInfoScan) / 4;
			timeOffsets = new .[count];
			baseColors = new .[count];

			var i = 0;
			while (colorInfoScan < colorInfoEnd) {
				Color4 colorTimeOffset = ?;
				Emulator.active.ReadFromRAM(colorInfoScan, &colorTimeOffset, 4);
				
				baseColors[i] = colorTimeOffset;
				timeOffsets[i] = colorTimeOffset.a;

				i++;
				colorInfoScan += 4;
			}
		}

		public void SetDefault() {
			if (firstRun) {
				// Can not set default if we have not figured it out
				// what the default is anyways
				return;
			}

			let region = Terrain.regions[regionIndex];
			for (let i < timeOffsets.Count) {
				region.SetNearColor((.)i, baseColors[i], false);
			}

			region.UpdateSubdividedColor(false);
			region.UpdateSubdividedColor(true);
		}
	}
}
