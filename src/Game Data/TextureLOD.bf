using System;

namespace SpyroScope {
	[Ordered]
	struct TextureLOD {
		[Ordered]
		public struct TextureQuad {
			public uint8 left, leftSkew, a, b, right, rightSkew, texturePage, flags;
		}
		public TextureQuad farQuad, nearQuad, topLeftQuad, topRightQuad, bottomLeftQuad, bottomRightQuad;
	}
}
