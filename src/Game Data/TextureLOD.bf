using System;

namespace SpyroScope {
	// Ripto's Rage & Year of the Dragon
	[Ordered]
	struct TextureLOD {
		public TextureQuad farQuad, nearQuad, topLeftQuad, topRightQuad, bottomLeftQuad, bottomRightQuad;
	}
	
	// Spyro the Dragon
	[Ordered]
	struct TextureLOD1 {
		public TextureQuad D1;
		public TextureQuad[4] D2;
		public TextureQuad[16] D3;
	}
}
