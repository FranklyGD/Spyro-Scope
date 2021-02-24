using System;

namespace SpyroScope {
	[Ordered]
	struct ExtendedTextureQuad{
		// TextureQuad (Similar)
		public (uint8 x, uint8 y) uv0;
		public uint16 clut;
		public (uint8 x, uint8 y) uv1;

		public uint8 texturePage, flipRotateRaw;

		// Extended
		public (uint8 x, uint8 y) uv2;
		public (uint8 x, uint8 y) uv3;
		
		public uint8 left { get => Math.Min(Math.Min(uv0.x, uv1.x), Math.Min(uv2.x, uv3.x)); }
		public uint8 right { get => Math.Max(Math.Max(uv0.x, uv1.x), Math.Max(uv2.x, uv3.x)); }
		public uint8 top { get => Math.Min(Math.Min(uv0.y, uv1.y), Math.Min(uv2.y, uv3.y)); }
		public uint8 bottom { get => Math.Max(Math.Max(uv0.y, uv1.y), Math.Max(uv2.y, uv3.y)); }

		public int width { get => (int)right - left + 1; }
		public int height { get => (int)bottom - top + 1; }

		Vector2 GetVramUV((uint8 x, uint8 y) uv) {
			let tpageCell = GetTPageCell();
			let subPixels = (texturePage & 0x80 > 0) ? 2 : 4;

			let pageOffsetX = tpageCell.x * 0.0625f;
			let pageOffsetY = tpageCell.y * 0.5f;

			let yAdjusted = Emulator.active.installment == .SpyroTheDragon ? uv.y + 0x1f : uv.y;
			return .(
				pageOffsetX + (float)((uint16)uv.x + ((uv.x % 32 >= 16) ? 1 : 0)) / subPixels / 1024,
				pageOffsetY + (float)((uint16)yAdjusted + ((yAdjusted % 32 >= 16) ? 1 : 0)) / 512
			);
		}

		// Used for checking where the quad UVs would line up in VRAM
		public Vector2 GetVramUV0() {
			return GetVramUV(uv0);
		}

		public Vector2 GetVramUV1() {
			return GetVramUV(uv1);
		}

		public Vector2 GetVramUV2() {
			return GetVramUV(uv2);
		}

		public Vector2 GetVramUV3() {
			return GetVramUV(uv3);
		}
		
		public (int x, int y) GetTPageCell() {
			return (texturePage & 0xf, (texturePage & 0x10) >> 4);
		}

		public int Decode() {
			if (width < 0 || height < 0) {
				return -1;
			}
			return VRAM.Decode(texturePage, left, top, width, height, (texturePage & 0x80 > 0) ? 8 : 4, clut);
		}
	}
}
