using OpenGL;
using SDL2;
using System;

namespace SpyroScope {
	static struct VRAM {
		static public uint16[] snapshot ~ delete _;
		static public Texture raw ~ delete _;
		static public Texture decoded ~ delete _;

		public static void TakeSnapshot() {
			delete snapshot;
			snapshot = new .[1024 * 512];
			Windows.ReadProcessMemory(Emulator.processHandle, (void*)Emulator.VRAMBaseAddress, &snapshot[0], 1024 * 512 * 2, null);

			delete raw;
			raw = new .(1024, 512, OpenGL.GL.GL_SRGB, OpenGL.GL.GL_RGBA, OpenGL.GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &snapshot[0]);
			raw.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
		}

		public static void Decode(int tpage, int x, int y, int width, int height, int bitmode, int clut) {
			(int x, int y) tpageCoords = (tpage & 0xf, (tpage & 0x10) >> 4);

			// Pixel index from T-Page
			let vramPagePosition = (tpageCoords.x * 64) + (tpageCoords.y * 256 * 1024);

			// Pixel index from starting row
			let vramPosition = vramPagePosition + ((int)y * 1024);

			let bitModeMask = (1 << bitmode) - 1;
			let subPixels = 16 / bitmode;
			let pWidth = 4 / subPixels;

			// The game splits the VRAM into 16 columns of CLUT starting locations
			// The size of each column is 16 pixels that contain all the necessary colors
			// or more depending on the bit-mode used to sample the colors in the table
			let clutPosition = (int)clut << 4;

			uint16[] pixels = new .[width * pWidth * height];
			for (let localx < width) {
				for (let localy < height) {
					let texelX = localx + x;

					// Get the target pixel from the texture
					let vramPixel = VRAM.snapshot[vramPosition + texelX / subPixels + localy * 1024];

					// Retrieve a sub-pixel value from VRAM (8- or 4-bit mode) to sample from a CLUT
					// Each sub-pixel contains a 8 or 4 bit value that tells the location of sample
					//
					// |       16-bit pixel        |
					// |       (8-bit mode)        |
					// |   11111111  |  00000000   |
					// |       (4-bit mode)        |
					// | 3333 | 2222 | 1111 | 0000 |
					//
					// After sampling, the result is a pixel in a color format of BGR555
					let p = texelX % subPixels;
					let clutSample = (((int)vramPixel >> (p * bitmode)) & bitModeMask) + clutPosition;
					let bgr555pixel = VRAM.snapshot[clutSample];

					// Get each 5 bit color channel
					// |        16-bit pixel       |
					// | a | bbbbb | ggggg | rrrrr |

					// Alpha has an inverse use when it comes to its value
					// 0 = Opaque, 1 = Semi-Transparent

					// Write pixel to the texture data
					for (let subx < pWidth) {
						pixels[subx + localx * pWidth + localy * width * pWidth] = bgr555pixel ^ 0x8000;
					}
				}
			}

			if (decoded == null) {
				uint16[] textureBuffer = new .[(1024 * 4) * 512]; // VRAM but four times wider
				decoded = new .(1024 * 4, 512, GL.GL_SRGB_ALPHA, GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &textureBuffer[0]);
				decoded.Bind();

				// Make the textures sample sharp
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

				delete textureBuffer;
			}

			decoded.Bind();
			GL.glTexSubImage2D(GL.GL_TEXTURE_2D,
				0, (tpageCoords.x * 64 * 4) + x * pWidth, (tpageCoords.y * 256) + y,
				width * pWidth, height,
				GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &pixels[0]
			);

			delete pixels;
		}

		public static void Export(String file, int x, int y, int width, int height, int bitmode) {
			let subPixels = 16 / bitmode;
			uint16[] textureBuffer = new .[width * subPixels * height];

			decoded.Bind();
			GL.glGetTexImage(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &textureBuffer[0]);

			SDL.Surface* img = SDL2.SDL.CreateRGBSurfaceFrom(&textureBuffer[0], (.)(width * subPixels), (.)height, 16, 2 * (.)(width * subPixels), 0x001f, 0x03e0, 0x7c00, 0x8000);
			SDL.SDL_SaveBMP(img, file);
			SDL.FreeSurface(img);
			delete textureBuffer;
		}

		
		public static void Export() {
			Export("./decoded_vram.bmp", 0, 0, 1024, 512, 4);
		}
	}
}
