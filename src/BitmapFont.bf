using OpenGL;
using SDL2;
using System;

namespace SpyroScope {
	class BitmapFont {
		public readonly int characterWidth;
		public readonly int characterHeight;

		uint textureObject;

		public this(String font, int characterWidth, int characterHeight) {
			let surface = SDLImage.Load(font);
			if (surface != null) {
				this.characterWidth = characterWidth;
				this.characterHeight = characterHeight;

				GL.glGenTextures(1, &textureObject);
				GL.glBindTexture(GL.GL_TEXTURE_2D, textureObject);

				GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGB, surface.w, surface.h, 0, GL.GL_RGB, GL.GL_UNSIGNED_BYTE, surface.pixels);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
				SDL.FreeSurface(surface);

				GL.glBindTexture(GL.GL_TEXTURE_2D, 0);

				Renderer.CheckForErrors();
			}
		}

		public void Print(String text, float width, float height, Vector position, Renderer.Color color, Renderer renderer) {
			for (let i < text.Length) {
				if (text[i] == ' ') {
					continue;
				}

				let character = (uint8)text[i] - 32;
				let glyphSize = ((float)characterWidth / 192, (float)characterHeight / 128);

				let pos = position + .(i * width, 0, 0);
				let postl = position + .(i * width, height, 0); 
				let postr = position + .((i + 1) * width, height, 0); 
				let posbr = position + .((i + 1) * width, 0, 0);

				let a0 = character * glyphSize.0;
				let d0 = a0 / 1f;
				let r0 = d0 - (int)d0;

				let uv = (r0, character / 16 * glyphSize.1);
				let uvtl = (r0, (character / 16 + 1) * glyphSize.1);

				let uvtr = (r0 + glyphSize.0, (character / 16 + 1) * glyphSize.1);
				let uvbr = (r0 + glyphSize.0, character / 16 * glyphSize.1);

				renderer.DrawTriangle(pos, postl, postr, color, color, color, uvtl, uv, uvbr, textureObject);
				renderer.DrawTriangle(pos, postr, posbr, color, color, color, uvtl, uvbr, uvtr, textureObject);
			}
		}

		public void Print(String text, Vector position, Renderer.Color color, Renderer renderer) {
			Print(text, characterWidth, characterHeight, position, color, renderer);
		}
	}
}
