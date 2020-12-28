using OpenGL;
using SDL2;
using System;

namespace SpyroScope {
	class BitmapFont {
		public readonly int characterWidth;
		public readonly int characterHeight;

		Texture texture ~ delete _;

		public this(String font, int characterWidth, int characterHeight) {
			texture = new .(font);
			this.characterWidth = characterWidth;
			this.characterHeight = characterHeight;
		}

		public void Print(StringView text, float width, float height, Vector position, Renderer.Color4 color) {
			for (let i < text.Length) {
				if (text[i] == ' ') {
					continue;
				}

				let character = (uint8)text[i] - 32;
				let glyphSize = ((float)characterWidth / texture.width, (float)characterHeight / texture.height);

				let a0 = character * glyphSize.0;
				let d0 = a0 / 1f;
				let r0 = d0 - (int)d0;

				DrawUtilities.Rect(position.y, position.y + height, position.x + i * width, position.x + (i + 1) * width,
					character / 16 * glyphSize.1, (character / 16 + 1) * glyphSize.1, r0, r0 + glyphSize.0,
					texture, color);
			}
		}

		public void Print(StringView text, Vector position, Renderer.Color4 color) {
			Print(text, characterWidth, characterHeight, position, color);
		}
	}
}
