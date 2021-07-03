using System;

namespace SpyroScope {
	[Ordered]
	public struct TextureQuad {
		public uint8 left, leftSkew;
		public uint16 clut;
		public uint8 right, rightSkew, texturePage, flipRotateRaw;

		public int width { get => (int)right - left + 1; }
		public int height { get {
			let rightSkewAdjusted = Emulator.active.installment == .SpyroTheDragon ? rightSkew + 0x1f : rightSkew;
			return (int)rightSkewAdjusted - leftSkew + 1;
		} }

		// Used for checking where the quad UVs would line up in VRAM
		public (float left, float right, float leftY, float rightY) GetVramPartialUV() {
			let tpageCell = GetTPageCell();
			let subPixels = (texturePage & 0x80 > 0) ? 2 : 4;

			let pageOffsetX = tpageCell.x * 0.0625f;
			let pageOffsetY = tpageCell.y * 0.5f;

			let rightSkewAdjusted = Emulator.active.installment == .SpyroTheDragon ? rightSkew + 0x1f : rightSkew;
			return (
				pageOffsetX + (float)left / subPixels / 1024,
				pageOffsetX + (float)((uint16)right + 1) / subPixels / 1024,
				pageOffsetY + (float)leftSkew / 512,
				pageOffsetY + (float)((uint16)rightSkewAdjusted + 1) / 512
			);
		}

		public Vector2[4] GetVramUVs() {
			let partialUV = GetVramPartialUV();
			
			Vector2[4] initialQuadUVs = .(
				.(partialUV.left, partialUV.rightY),
				.(partialUV.right, partialUV.rightY),
				.(partialUV.right, partialUV.leftY),
				.(partialUV.left, partialUV.leftY)
			);

			Vector2[4] quadUVs = ?;

			let quadRotation = GetQuadRotation();
			for (let i < 4) {
				quadUVs[i] = initialQuadUVs[(i - quadRotation) & 3];
			}

			if (GetFlip()) {
				Swap!(quadUVs[0], quadUVs[2]);
			}

			return quadUVs;
		}

		public int GetTPageIndex() {
			return texturePage & 0x1f;
		}

		public (int x, int y) GetTPageCell() {
			return (texturePage & 0xf, (texturePage & 0x10) >> 4);
		}

		public (int x, int y) GetCLUTCoordinates() {
			return ((clut & 0x3f) << 4, clut >> 6);
		}

		public uint8 GetQuadRotation() {
			return (flipRotateRaw & 0b00110000) >> 4;
		}

		public bool GetFlip() {
			return (flipRotateRaw & 0b01000000) > 0;
		}

		public bool GetTransparency() {
			return Emulator.active.installment != .SpyroTheDragon && (flipRotateRaw & 0b10000000) > 0;
			// For "Spyro the Dragon", the transparency flag for it can be found on a per face basis
			// Refer to "TerrainRegion.NearFace.RenderInfo" for an implementation of the mentioned above
		}

		public int Decode() {
			if (width < 0 || height < 0) {
				return -1;
			}
			return VRAM.Decode(texturePage, left, leftSkew, width, height, (texturePage & 0x80 > 0) ? 8 : 4, clut);
		}
	}
}
