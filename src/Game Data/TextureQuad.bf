using System;

namespace SpyroScope {
	[Ordered]
	public struct TextureQuad {
		
		// All terrain quads are 32x32 when decoded
		// and the closer rendered ones are four of those combined

		public uint8 left, leftSkew;
		public uint16 clut;
		public uint8 right, rightSkew, texturePage, flipRotateRaw;
		public const float quadSize = 1f / 16;

		// Used for checking where the quad UVs would line up in VRAM
		public (float left, float right, float leftY, float rightY) GetVramPartialUV() {
			let tpageCell = GetTPageCell();
			let subPixels = (texturePage & 0x80 > 0) ? 2 : 4;

			let pageOffsetX = tpageCell.x * 0.0625f;
			let pageOffsetY = tpageCell.y * 0.5f;

			let rightSkewAdjusted = Emulator.installment == .SpyroTheDragon ? rightSkew + 0x1f : rightSkew;
			return (
				pageOffsetX + (float)left / subPixels / 1024,
				pageOffsetX + (float)((uint16)right + 1) / subPixels / 1024,
				pageOffsetY + (float)leftSkew / 512,
				pageOffsetY + (float)((uint16)rightSkewAdjusted + 1) / 512
			);
		}

		public int GetTPageIndex() {
			return texturePage & 0x1f;
		}

		public (uint x, uint y) GetTPageCell() {
			return (texturePage & 0xf, (texturePage & 0x10) >> 4);
		}

		public (uint x, uint y) GetCLUTCoordinates() {
			return ((clut & 0x3f) << 4, clut >> 6);
		}

		public uint8 GetQuadRotation() {
			return (flipRotateRaw & 0b00110000) >> 4;
		}

		public bool GetDiagonalFlip() {
			return (flipRotateRaw & 0b01000000) > 0;
		}

		public bool GetTransparency() {
			return Emulator.installment != .SpyroTheDragon && (flipRotateRaw & 0b10000000) > 0;
			// For "Spyro the Dragon", the transparency flag for it can be found on a per face basis
			// Refer to "TerrainRegion.NearFace.RenderInfo" for an implementation of the mentioned above
		}
	}
}
