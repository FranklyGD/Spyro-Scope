using OpenGL;
using System;

namespace SpyroScope {
	class TextureSprite {
		public uint8 width, height;

		[Ordered]
		public struct SpriteFrame {
			public uint8 x, y, clutX, clutY;

			public bool GetTransparency() {
				return (clutX & 0b10000000) > 0;
			}
		}
		public SpriteFrame[] frames ~ delete _;

		public this(uint8 id, int start, int count) {
			Emulator.ReadFromRAM((.)0x800634b8 + id, &width, 1);
			Emulator.ReadFromRAM((.)0x800634d0 + id, &height, 1);
			
			frames = new .[count];
			Emulator.ReadFromRAM((.)0x8006351c + start * sizeof(SpriteFrame), &frames[0], sizeof(SpriteFrame) * count);
		}

		uint32[] GetTextureData(SpriteFrame frame) {
			let vramPageCoords = ((8) * 64) + ((1) * 256 * 1024); // Always the 24th tpage or 0x18
			let vramCoords = vramPageCoords + ((int)frame.y * 1024);

			// The sprites a small and take up not much in size of the VRAM
			// since they exclusively use the 4-bit mode in its color lookup

			let clutPosition = vramPageCoords + ((int)frame.clutX & 0x3) << 4 + (int)frame.clutY << 10;

			uint32[] pixels = new .[(int)width * height];
			for (let x < width) {
				for (let y < height) {
					let texelX = x + frame.x;

					// Get the target pixel from the texture
					let vramPixel = Emulator.vramSnapshot[vramCoords + texelX / 4 + y * 1024];

					// Retrieve a sub-pixel value from VRAM (4-bit mode) to sample from a CLUT
					// Each sub-pixel contains a 4 bit value that tells the location of sample
					//
					// |       16-bit pixel        |
					// | 3333 | 2222 | 1111 | 0000 |
					//
					// After sampling, the result is a pixel in a color format of BGR555
					let p = texelX % 4;
					let clutSample = (((int)vramPixel >> (p * 4)) & 0xf) + clutPosition;
					let bgr555pixel = Emulator.vramSnapshot[clutSample];

					// Get each 5 bit color channel
					// |        16-bit pixel       |
					// | a | bbbbb | ggggg | rrrrr |
					let r5 = bgr555pixel & 0x1f;
					let g5 = bgr555pixel >> 5 & 0x1f;
					let b5 = bgr555pixel >> 10 & 0x1f;
					// let a1 = bgr555pixel >> 15; Ignore the alpha for now

					// Bring values from 31 up to 255 (0x1f to 0xff)
					let r = (uint32)((float)r5 / 0x1f * 255);
					let g = (uint32)((float)g5 / 0x1f * 255);
					let b = (uint32)((float)b5 / 0x1f * 255);

					// Write to the texture data
					pixels[(int)x + (int)y * width] = r + (g << 8) + (b << 16) + ((uint32)0xff000000);
				}
			}

			return pixels;
		}

		public void Decode() {
			for (let frameIndex < frames.Count) {
				let frame = frames[frameIndex];

				let spriteTexture = GetTextureData(frame);

				GL.glTexSubImage2D(GL.GL_TEXTURE_2D,
					0, ((8) * 64 * 4) + frame.x, ((1) * 256) + frame.y,
					width, height,
					GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, &spriteTexture[0]
				);

				delete spriteTexture;
			}
		}
	}
}
