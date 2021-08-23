using OpenGL;
using System.Collections;

namespace SpyroScope {
	static class SpyroFont {
		static (uint8 character, int8 offsetWidth)[128] fontCharacters;

		public static void Init() {
			//Emulator.spyroFontAddress[(int)Emulator.active.rom - 4].ReadArray((.)&fontCharacters, 128);
		}

		public static void Decode(List<int> spriteTextureIDs) {
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

				spriteTextureIDs.Add(VRAM.Decode(0x18, coordx, coordy, 12, 9, 4, clut));
			}
		}
	}
}
