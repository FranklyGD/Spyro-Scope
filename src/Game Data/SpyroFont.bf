using OpenGL;

namespace SpyroScope {
	static class SpyroFont {
		static (uint8 character, int8 offsetWidth)[128] fontCharacters;

		public static void Init() {
			Emulator.ReadFromRAM((.)0x800636a4, &fontCharacters, 2 * 128);
		}

		public static void Decode() {
			for (let character < 128) {
				let fontCharacter = fontCharacters[character];
				
				// Derived from Spyro: Ripto's Rage [8004a424]
				if (fontCharacter.character == 0xff) {
					continue;
				}

				// Derived from Spyro: Ripto's Rage [8004a4e8]
				let coordx = (fontCharacter.character & 0x1f) * 12;
				let vertical = fontCharacter.character & 0xe0;
				let coordy = vertical >> 2 | vertical >> 5;

				int clut = ?;
				switch (character) {
					case 0x3c, 0x3e, 0x7b, 0x7d: clut = 0x4962;
					default: clut = 0x4922;
				}

				VRAM.Decode(0x18, coordx, coordy, 12, 9, 4, clut);
			}
		}

		static uint32[] GetTextureData(int index) {
			let fontCharacter = fontCharacters[index];

			// Derived from Spyro: Ripto's Rage [8004a4e8]
			let coordx = (fontCharacter.character & 0x1f) * 12;
			let vertical = fontCharacter.character & 0xe0;
			let coordy = vertical >> 2 | vertical >> 5;

			let vramPageCoords = ((8) * 64) + ((1) * 256 * 1024); // Always the 24th tpage or 0x18
			let vramCoords = vramPageCoords + ((int)coordy * 1024);

			// The sprites a small and take up not much in size of the VRAM
			// since they exclusively use the 4-bit mode in its color lookup

			// Derived from Spyro: Ripto's Rage [8004a520]
			int clutPosition = ?;
			switch (index) {
				case 0x3c, 0x3e, 0x7b, 0x7d: clutPosition = (int)0x4962 << 4;
				default: clutPosition = (int)0x4922 << 4;
			}

			uint32[] pixels = new .[12 * 9];
			for (let x < 12) {
				for (let y < 9) {
					let texelX = x + coordx;

					// Get the target pixel from the texture
					let vramPixel = VRAM.snapshot[vramCoords + texelX / 4 + y * 1024];

					// Retrieve a sub-pixel value from VRAM (4-bit mode) to sample from a CLUT
					// Each sub-pixel contains a 4 bit value that tells the location of sample
					//
					// |       16-bit pixel        |
					// | 3333 | 2222 | 1111 | 0000 |
					//
					// After sampling, the result is a pixel in a color format of BGR555
					let p = texelX % 4;
					let clutSample = (((int)vramPixel >> (p * 4)) & 0xf) + clutPosition;
					let bgr555pixel = VRAM.snapshot[clutSample];

					// Get each 5 bit color channel
					// |        16-bit pixel       |
					// | a | bbbbb | ggggg | rrrrr |
					let r5 = bgr555pixel & 0x1f;
					let g5 = bgr555pixel >> 5 & 0x1f;
					let b5 = bgr555pixel >> 10 & 0x1f;
					// let a1 = bgr555pixel >> 15; Ignore the alpha for now

					// Bring values from 31 up to 255 (0x1f to 0xff)
					let r = (uint32)((float)r5 / 0x1f * 255);
					let g = (uint32)((float)g5 / 0x1f * 255);
					let b = (uint32)((float)b5 / 0x1f * 255);

					// Write to the texture data
					pixels[(int)x + (int)y * 12] = r + (g << 8) + (b << 16) + ((uint32)0xff000000);
				}
			}

			return pixels;
		}
	}
}
