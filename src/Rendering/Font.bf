using System;

namespace SpyroScope {
	abstract class Font {
		public readonly int height;
		public readonly Texture texture ~ delete _;

		public abstract float Print(StringView text, Vector2 position, Renderer.Color4 color);
	}
}
