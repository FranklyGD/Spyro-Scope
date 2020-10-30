using OpenGL;

namespace SpyroScope {
	struct TextureAnimation {
		Emulator.Address address;
		public uint8 textureIndex;
		
		public Mesh sourceNearMesh;
		
		public struct KeyframeData {
			public uint8 a, nextFrame, b, verticalOffset;
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

			// Append the missing parts of the scrolling textures to the main decoded one
			// They only exist against the top edge of the VRAM because of how they are programmed

			let textureLOD = &Terrain.texturesLODs[textureIndex];
			var quad = &textureLOD.nearQuad;
			
			Terrain.terrainTexture.Bind();

			for (let i < 6) {
				let mode = quad.texturePage & 0x80 > 0;
				let pixelWidth = mode ? 2 : 1;
				
				let width = mode ? 64 : 32;
				uint32[] textureBuffer = new .[width * 32];

				let pageCoords = quad.GetPageCoordinates();

				let verticalQuad = mode ? 3 : 2;
				for (let s < verticalQuad) {
					quad.leftSkew = (uint8)s * 0x20;
					quad.rightSkew = quad.leftSkew + 0x1f;

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
				}

				delete textureBuffer;
				quad++;
			}
			
			Texture.Unbind();
		}

		// Derived from Spyro: Ripto's Rage [8002270c]
		public void Update() {
			uint8 verticalPosition = ?;
			Emulator.ReadFromRAM(address + 6, &verticalPosition, 1);

			let quadVerticalPosition = verticalPosition >> 2;

			let textureLOD = &Terrain.texturesLODs[textureIndex];
			let farQuad = &textureLOD.farQuad;
			let nearQuad = &textureLOD.nearQuad;
			farQuad.leftSkew = nearQuad.leftSkew = quadVerticalPosition;
			farQuad.rightSkew = nearQuad.rightSkew = quadVerticalPosition + 0x1f;

			var doubleQuadVerticalPosition = verticalPosition >> 1;

			let topLeftQuad = &textureLOD.topLeftQuad;
			let topRightQuad = &textureLOD.topRightQuad;
			topLeftQuad.leftSkew = topRightQuad.leftSkew = doubleQuadVerticalPosition;
			topLeftQuad.rightSkew = topRightQuad.rightSkew = doubleQuadVerticalPosition + 0x1f;

			doubleQuadVerticalPosition = (doubleQuadVerticalPosition + 0x20) & 0x3f;

			let bottomLeftQuad = &textureLOD.bottomLeftQuad;
			let bottomRightQuad = &textureLOD.bottomRightQuad;
			bottomLeftQuad.leftSkew = bottomRightQuad.leftSkew = doubleQuadVerticalPosition;
			bottomLeftQuad.rightSkew = bottomRightQuad.rightSkew = doubleQuadVerticalPosition + 0x1f;
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}
	}
}
