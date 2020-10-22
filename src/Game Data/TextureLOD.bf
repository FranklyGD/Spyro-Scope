using System;

namespace SpyroScope {
	[Ordered]
	struct TextureLOD {
		[Ordered]
		public struct TextureQuad {
			public uint8 left, leftSkew, a, b, right, rightSkew, texturePage, flags;
			public const float quadSize = 1f / 16;

			public (float left, float right, float leftY, float rightY) GetVramPartialUV() {
				let pageCoords = GetPageCoordinates();

				let pageOffsetX = pageCoords.x * 0.0625f;
				let pageOffsetY = pageCoords.y * 0.5f;

				return (
					pageOffsetX + (float)left / 4 / 1024,
					pageOffsetX + (float)((uint16)right + 1) / 4 / 1024,
					pageOffsetY + (float)leftSkew / 512,
					pageOffsetY + (float)((uint16)rightSkew + 1) / 512
				);
			}

			public (int x, int y) GetPageCoordinates() {
				return (texturePage & 0xf, ((texturePage & 0x10) >> 4));
			}
		}

		public TextureQuad farQuad, nearQuad, topLeftQuad, topRightQuad, bottomLeftQuad, bottomRightQuad;
	}
}
