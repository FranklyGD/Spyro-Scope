using OpenGL;
using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	static struct VRAM {
		static public bool upToDate { get; private set; }
		static public uint16[] snapshot ~ delete _;
		static public uint16[] snapshotDecoded ~ delete _;
		static public Texture raw ~ delete _;
		static public Texture decoded ~ delete _;

		public struct VRAMTexture {
			public int bitmode;
			public int x, y; // X's absolute position in the given bitmode, no page offset (already added in)
			public int width, height;
			public int clut;

			public Rect GetVramPartialUV() {
				return .(
					(float)x / (16 / bitmode) / 1024,
					(float)(x + width) / (16 / bitmode) / 1024,
					(float)y / 512,
					(float)(y + height) / 512
				);
			}

			
			public (int x, int y) GetCLUTCoordinates() {
				return ((clut & 0x3f) << 4, clut >> 6);
			}
		}
		public static List<VRAMTexture> decodedTextures = new .() ~ delete _;
		static List<int> queuedTextures = new .() ~ delete _;

		static public Event<delegate void()> OnSnapshotTaken ~ _.Dispose();

		public static void MakeOutdated() {
			upToDate = false;
			queuedTextures.Clear();
			decodedTextures.Clear();
		}

		public static void TakeSnapshot() {
			delete snapshot;
			snapshot = new .[1024 * 512];
			Windows.ReadProcessMemory(Emulator.active.processHandle, (void*)Emulator.active.VRAMBaseAddress, &snapshot[0], 1024 * 512 * 2, null);

			delete raw;
			raw = new .(1024, 512, OpenGL.GL.GL_SRGB, OpenGL.GL.GL_RGBA, OpenGL.GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &snapshot[0]);
			raw.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

			if (decoded != null) {
				delete snapshotDecoded;

				decoded.Bind();

				snapshotDecoded = new .[(1024 * 4) * 512]; // VRAM but four times wider
				GL.glTexSubImage2D(GL.GL_TEXTURE_2D, 0, 0, 0, 1024 * 4, 512, GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &snapshotDecoded[0]);
			}

			upToDate = true;

			OnSnapshotTaken();
		}

		public static void Write(uint16[] buffer, int x, int y, int width, int height) {
			raw.Bind();

			for (let localy < height) {
				for (let localx < width) {
					snapshot[x + localx + (y + localy) * 1024] = buffer[localx + localy * width];
				}
				Windows.WriteProcessMemory(Emulator.active.processHandle, (void*)(Emulator.active.VRAMBaseAddress + (x + (y + localy) * 1024) * 2), &buffer[(int)(localy * width)], width * 2, null);
			}
			GL.glTexSubImage2D(GL.GL_TEXTURE_2D, 0, x, y, width, height, GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &buffer[0]);
		}

		public static void Write(uint16[] buffer, int decodedTextureID) {
			let decodedTexture = decodedTextures[decodedTextureID];
			
			let subPixels = 16 / decodedTexture.bitmode;
			let pWidth = 4 / subPixels;
			Write(buffer, decodedTexture.x / subPixels, decodedTexture.y, decodedTexture.width * pWidth, decodedTexture.height);
		}

		static void DecodeInternal(int x, int y, int width, int height, int bitmode, int clut) {
			let bitModeMask = (1 << bitmode) - 1;
			let subPixels = 16 / bitmode;
			let pWidth = 4 / subPixels;

			// The game splits the VRAM into 16 columns of CLUT starting locations
			// The size of each column is 16 pixels that contain all the necessary colors
			// or more depending on the bit-mode used to sample the colors in the table
			let clutPosition = (clut << 4) & 0x7ffff;

			uint16[] pixels = new .[width * pWidth * height];
			for (let localx < width) {
				for (let localy < height) {
					let texelX = localx + x;

					// Get the target pixel from the texture
					let vramPixel = VRAM.snapshot[texelX / subPixels + (y + localy) * 1024];

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
				snapshotDecoded = new .[(1024 * 4) * 512]; // VRAM but four times wider
				decoded = new .(1024 * 4, 512, GL.GL_SRGB_ALPHA, GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &snapshotDecoded[0]);
				decoded.Bind();

				// Make the textures sample sharp
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
				GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
			}

			decoded.Bind();
			GL.glTexSubImage2D(GL.GL_TEXTURE_2D,
				0, x * pWidth, y,
				width * pWidth, height,
				GL.GL_RGBA, GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, pixels.CArray()
			);

			for (let localx < width * pWidth) {
				for (let localy < height) {
					snapshotDecoded[x * pWidth + localx + (y + localy) * 1024 * 4] = pixels[localx + localy * (width * pWidth)];
				}
			}

			delete pixels;
		}

		public static int Decode(int x, int y, int width, int height, int bitmode, int clut) {
			VRAMTexture vtex = ?;
			vtex.bitmode = bitmode;
			vtex.x = x;
			vtex.y = y;
			vtex.width = width;
			vtex.height = height;
			vtex.clut = clut;

			let foundIndex = decodedTextures.FindIndex(scope (x) => x == vtex);
			if (foundIndex > -1) {
				return foundIndex;
			}
			
			let nextIndex = decodedTextures.Count;

			if (snapshot == null) {
				queuedTextures.Add(nextIndex);
			} else {
				DecodeInternal(x, y, width, height, bitmode, clut);
			}
			
			decodedTextures.Add(vtex);

			return nextIndex;
		}

		public static int Decode(int tpage, int x, int y, int width, int height, int bitmode, int clut) {
			(int x, int y) tpageCoords = ((tpage & 0xf) * 64, ((tpage & 0x10) >> 4) * 256);
			
			let subPixels = 16 / bitmode;
			return Decode(x + tpageCoords.x * subPixels, y + tpageCoords.y, width, height, bitmode, clut);
		}

		public static void Decode(int decodedTextureID) {
			let decodedTexture = decodedTextures[decodedTextureID];

			DecodeInternal(decodedTexture.x, decodedTexture.y, decodedTexture.width, decodedTexture.height, decodedTexture.bitmode, decodedTexture.clut);
		}

		public static void DecodeQueue() {
			if (snapshot == null) {
				return;
			}

			for (let queuedTexture in queuedTextures) {
				let vtex = decodedTextures[queuedTexture];
				DecodeInternal(vtex.x, vtex.y, vtex.width, vtex.height, vtex.bitmode, vtex.clut);
			}

			queuedTextures.Clear();
		}

		public static void Export(String file, int x, int y, int width, int height, int bitmode) {
			let subPixels = 16 / bitmode;
			let pixelWidth = 4 / subPixels;
			uint16[] textureBuffer = new .[width * height];

			for (let localx < width) {
				for (let localy < height) {
					textureBuffer[localx + localy * width] = snapshotDecoded[(x + localx) * pixelWidth + (y + localy) * 1024 * 4];
				}
			}

			SpyroScope.Image.Save(textureBuffer.CArray(), width, height, file);

			delete textureBuffer;
		}

		public static void Export(String file, int x, int y, int width, int height, int bitmode, int tpage) {
			(int x, int y) tpageCoords = (tpage & 0xf, (tpage & 0x10) >> 4);
			let subPixels = 16 / bitmode;
			let pixelWidth = 4 / subPixels;

			Export(file, x + tpageCoords.x * 64 / pixelWidth, y + tpageCoords.y * 256, width, height, bitmode);
		}

		public static void Export(String file, int decodedTextureID) {
			let decodedTexture = decodedTextures[decodedTextureID];

			Export(file, decodedTexture.x, decodedTexture.y, decodedTexture.width, decodedTexture.height, decodedTexture.bitmode);
		}


		public static void Export(String file) {
			Export(file, 0, 0, 1024 * 4, 512, 4, 0);
		}

		public static void ExportTerrain(String file) {
			if (Terrain.usedTextureIndices != null) {
				let textureIndices = scope List<uint8>(Terrain.usedTextureIndices.Keys);
				textureIndices.Sort();
				let highestIndex = textureIndices[textureIndices.Count - 1];

				// Setup exported image size
				const int tileSize = 32 * 2;
				const int imageWidth = tileSize * 16;
				let tileRowCount = highestIndex / 16 + 1;
				let imageHeight = tileSize * tileRowCount;
				uint16[] textureBuffer = new .[imageWidth * imageHeight];
				
				// Get installment dependent values
				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
				let quadStart = Emulator.active.installment == .SpyroTheDragon ? 1 : 2;

				// Write out all
				for (let i < textureIndices.Count) {
					let textureIndex = textureIndices[i];
						
					TextureQuad* quad = &Terrain.textures[textureIndex * quadCount + quadStart];
					
					for (let subquadIndex < 4) {
						(int x, int y) bufferQuadPos = (textureIndex & 0xf, textureIndex >> 4);
						(int x, int y) bufferSubQuadPos = (subquadIndex & 1, subquadIndex >> 1);

						let tpageCell = quad.GetTPageCell();

						for (let localx < 32) {
							for (let localy < 32) {
								int localxt = ?, localyt = ?;

								switch (quad.GetQuadRotation()) {
									case 0: localxt = localx; localyt = localy;
									case 1: localxt = localy; localyt = 31-localx;
									case 2: localxt = 31-localx; localyt = 31-localy;
									case 3: localxt = 31-localy; localyt = localx;
								}

								if (quad.GetFlip()) {
									Swap!(localxt,localyt);
								}

								let tbX = bufferQuadPos.x * 64 + bufferSubQuadPos.x * 32 + localxt;
								let tbY = bufferQuadPos.y * 64 + bufferSubQuadPos.y * 32 + localyt;

								let ssTP = (tpageCell.x * 64 + tpageCell.y * 256 * 1024) * 4;
								let ssX = ((int)quad.left + localx) * 2 /*pixelWidth*/;
								let ssY = (int)quad.leftSkew + localy;

								textureBuffer[tbX + tbY * imageWidth] = VRAM.snapshotDecoded[ssTP + ssX + ssY * 1024 * 4];
							}
						}

						quad++;
					}
				}
				
				SpyroScope.Image.Save(textureBuffer.CArray(), imageWidth, imageHeight, file);

				delete textureBuffer;
			}
		}
	}
}
