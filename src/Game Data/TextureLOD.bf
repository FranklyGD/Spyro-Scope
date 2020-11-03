using System;

namespace SpyroScope {
	[Ordered]
	struct TextureLOD {
		public TextureQuad farQuad, nearQuad, topLeftQuad, topRightQuad, bottomLeftQuad, bottomRightQuad;
	}

	[Ordered]
	struct TextureLOD1 {
		public TextureQuad D1;
		public TextureQuad[4] D2;
		public TextureQuad[16] D3;
	}
}
