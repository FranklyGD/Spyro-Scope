using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureSwapper {
		Emulator.Address address;
		public uint8 textureIndex;

		public struct KeyframeData {
			public uint8 a, nextFrame, b, textureIndex;
		}

		public uint8 CurrentKeyframe {
			get {
				uint8 currentKeyframe = ?;
				Emulator.ReadFromRAM(address + 2, &currentKeyframe, 1);
				return currentKeyframe;
			}
		}

		public this(Emulator.Address address) {
			this = ?;

			this.address = address;
			Reload();
		}

		public void Reload() mut {
			if (address.IsNull)
				return;
			
			Emulator.ReadFromRAM(address + 4, &textureIndex, 1);

			// Analyze frames
			uint8 keyframe = 0;
			List<uint8> usedTextures = scope .();
			while (usedTextures.Count == 0 && keyframe > 0) {
				let keyframeData = GetKeyframeData(keyframe);
				usedTextures.Add(keyframeData.textureIndex);
			}

			// Append the missing parts of the scrolling textures to the main decoded one

			Terrain.terrainTexture.Bind();

			for (let textureIndex in usedTextures) {
				TextureQuad* quad = ?;
				int quadCount = ?;
				if (Emulator.installment == .SpyroTheDragon) {
					quad = &Terrain.texturesLODs1[textureIndex].D1;
					quadCount = 5; // There is technically 21 texture quads, but the last 16 are almost unused
				} else {
					quad = &Terrain.texturesLODs[textureIndex].nearQuad;
					quadCount = 6;
				}

				for (let i < quadCount) {
					let mode = quad.texturePage & 0x80 > 0;
					let pixelWidth = mode ? 2 : 1;
					
					let width = 32 * pixelWidth;
					uint32[] textureBuffer = new .[width * 32];
	
					let pageCoords = quad.GetPageCoordinates();
					let quadTexture = quad.GetTextureData();
	
					for (let x < width) {
						for (let y < 32) {
							textureBuffer[(x + y * width)] = quadTexture[x / pixelWidth + y * 32];
						}
					}
					
					delete quadTexture;
	
					GL.glTexSubImage2D(GL.GL_TEXTURE_2D,
						0, (pageCoords.x * 64 * 4) + quad.left * pixelWidth, (pageCoords.y * 256) + quad.leftSkew,
						width, 32,
						GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, &textureBuffer[0]
					);
	
					delete textureBuffer;
					quad++;
				}
			}
			
			Texture.Unbind();
		}

		// Derived from Spyro the Dragon [8002b578]
		// Derived from Spyro: Ripto's Rage [8002270c]
		public void Update() {
			uint8 sourceTextureIndex = ?;
			Emulator.ReadFromRAM(address + 8 + (int)CurrentKeyframe * 4 + 3, &sourceTextureIndex, 1);

			if (Emulator.installment == .SpyroTheDragon) {
				Terrain.texturesLODs1[textureIndex] = Terrain.texturesLODs1[sourceTextureIndex];
			} else {
				Terrain.texturesLODs[textureIndex] = Terrain.texturesLODs[sourceTextureIndex];
			}
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}
	}
}
