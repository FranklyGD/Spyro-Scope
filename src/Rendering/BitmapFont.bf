using OpenGL;
using System;

namespace SpyroScope {
	class BitmapFont : Font {
		public readonly int characterWidth;

		public this(String font, int characterWidth, int characterHeight) {
			this.height = characterHeight;
			this.characterWidth = characterWidth;

			texture = new .(font);
		}

		public float Print(StringView text, float width, float height, Vector2 position, Renderer.Color4 color) {
			for (let i < text.Length) {
				if (text[i] == ' ') {
					continue;
				}

				let character = (uint8)text[i] - 32;
				let glyphSize = ((float)characterWidth / texture.width, (float)height / texture.height);

				let a0 = character * glyphSize.0;
				let d0 = a0 / 1f;
				let r0 = d0 - (int)d0;

				DrawUtilities.Rect(position.y, position.y + height, position.x + i * width, position.x + (i + 1) * width,
					character / 16 * glyphSize.1, (character / 16 + 1) * glyphSize.1, r0, r0 + glyphSize.0,
					texture, color);
			}

			return position.x + width * text.Length;
		}

		public override float Print(StringView text, Vector2 position, Renderer.Color4 color) {
			return Print(text, characterWidth, height, position, color);
		}
	}
}
