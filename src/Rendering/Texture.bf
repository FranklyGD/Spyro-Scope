using OpenGL;
using SDL2;
using System;

namespace SpyroScope {
	class Texture {
		public uint32 textureObjectID;
		public readonly int width;
		public readonly int height;

		public this(String source) {
			let surface = SDLImage.Load(source);
			if (surface != null) {
				width = surface.w;
				height = surface.h;

				GL.glGenTextures(1, &textureObjectID);
				GL.glBindTexture(GL.GL_TEXTURE_2D, textureObjectID);
				
				uint fromFormat = surface.format.Amask == 0 ? GL.GL_SRGB : GL.GL_SRGB_ALPHA;
				uint toFormat = surface.format.Amask == 0 ? GL.GL_RGB : GL.GL_RGBA;

				GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, (int)fromFormat, surface.w, surface.h, 0, toFormat, GL.GL_UNSIGNED_BYTE, surface.pixels);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);
				SDL.FreeSurface(surface);

				GL.glBindTexture(GL.GL_TEXTURE_2D, 0);

				Renderer.CheckForErrors();
			}
		}

		public this(int width, int height, int fromFormat, uint toFormat, void* data) {
			this.width = width;
			this.height = height;

			GL.glGenTextures(1, &textureObjectID);
			GL.glBindTexture(GL.GL_TEXTURE_2D, textureObjectID);

			GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, fromFormat, width, height, 0, toFormat, GL.GL_UNSIGNED_BYTE, data);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);

			GL.glBindTexture(GL.GL_TEXTURE_2D, 0);

			Renderer.CheckForErrors();
		}

		public this(int width, int height, int fromFormat, uint toFormat, uint type, void* data) {
			this.width = width;
			this.height = height;

			GL.glGenTextures(1, &textureObjectID);
			GL.glBindTexture(GL.GL_TEXTURE_2D, textureObjectID);

			GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, fromFormat, width, height, 0, toFormat, type, data);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);

			GL.glBindTexture(GL.GL_TEXTURE_2D, 0);

			Renderer.CheckForErrors();
		}

		public ~this() {
			GL.glDeleteTextures(1, &textureObjectID);
		}

		public void Bind(uint index = 0) {
			GL.glActiveTexture(GL.GL_TEXTURE0 + index);
			GL.glBindTexture(GL.GL_TEXTURE_2D, textureObjectID);
		}

		public static void Unbind() {
			GL.glBindTexture(GL.GL_TEXTURE_2D, 0);
		}
	}
}
