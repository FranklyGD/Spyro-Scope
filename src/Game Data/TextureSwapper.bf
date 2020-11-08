using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureSwapper {
		Emulator.Address address;
		public uint8 textureIndex;
		
		public TerrainRegion[] visualMeshes;
		public Dictionary<uint8, List<int>> affectedTriangles = new .();
		public Dictionary<uint8, List<int>> affectedTransparentTriangles = new .();

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

		public this(Emulator.Address address, TerrainRegion[] visualMeshes) {
			this = ?;

			this.address = address;
			this.visualMeshes = visualMeshes;
			Reload();
		}

		public void Dispose() {
			for (var pair in affectedTriangles) {
				delete pair.value;
			}
			delete affectedTriangles;

			for (var pair in affectedTransparentTriangles) {
				delete pair.value;
			}
			delete affectedTransparentTriangles;
		}

		public void Reload() mut {
			affectedTriangles.Clear();
			affectedTransparentTriangles.Clear();

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

			for (let regionIndex < visualMeshes.Count) {
				let terrainRegion = visualMeshes[regionIndex];

				for (var triangleIndex = 0; triangleIndex < terrainRegion.nearTri2TextureIndices.Count; triangleIndex++) {
					if (terrainRegion.nearTri2TextureIndices[triangleIndex] == textureIndex) {
						if (!affectedTriangles.ContainsKey((.)regionIndex)) {
							affectedTriangles[(.)regionIndex] = new .();
						}
						affectedTriangles[(.)regionIndex].Add(triangleIndex);
					}
				}
				
				for (var triangleIndex = 0; triangleIndex < terrainRegion.nearTri2TransparentTextureIndices.Count; triangleIndex++) {
					if (terrainRegion.nearTri2TransparentTextureIndices[triangleIndex] == textureIndex) {
						if (!affectedTransparentTriangles.ContainsKey((.)regionIndex)) {
							affectedTransparentTriangles[(.)regionIndex] = new .();
						}
						affectedTransparentTriangles[(.)regionIndex].Add(triangleIndex);
					}
				}
			}
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

			UpdateUVs(false);
			UpdateUVs(true);
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}

		
		void UpdateUVs(bool transparent) {
			TextureQuad nearQuad = ?;
			if (Emulator.installment == .SpyroTheDragon) {
				nearQuad = Terrain.texturesLODs1[textureIndex].D1;
			} else {
				nearQuad = Terrain.texturesLODs[textureIndex].nearQuad;
			}
			let partialUV = nearQuad.GetVramPartialUV();

			float[4][2] triangleUV = ?;

			let affectedTriangles = transparent ? affectedTransparentTriangles : affectedTriangles;
			for (let affectedRegionTriPair in affectedTriangles) {
				let terrainRegion = visualMeshes[affectedRegionTriPair.key];
				let faceIndices = transparent ? terrainRegion.nearFaceTransparentIndices : terrainRegion.nearFaceIndices;
				let regionMesh = transparent ? terrainRegion.nearMeshTransparent : terrainRegion.nearMesh;

				for (var i < affectedRegionTriPair.value.Count) {
					let triangleIndex = affectedRegionTriPair.value[i];
					let vertexIndex = triangleIndex * 3;

					let nearFaceIndex = faceIndices[triangleIndex];
					TerrainRegion.NearFace regionFace = terrainRegion.nearFaces[nearFaceIndex];
					let textureRotation = regionFace.renderInfo.rotation;

					triangleUV[0] = .(partialUV.right, partialUV.rightY - TextureQuad.quadSize);
					triangleUV[1] = .(partialUV.left, partialUV.leftY);
					triangleUV[2] = .(partialUV.left, partialUV.leftY + TextureQuad.quadSize);
					triangleUV[3] = .(partialUV.right, partialUV.rightY);

					if (regionFace.isTriangle) {
						float[3][2] rotatedTriangleUV = .(
							triangleUV[(0 - textureRotation) & 3],
							triangleUV[(1 - textureRotation) & 3],
							triangleUV[(2 - textureRotation) & 3]
							);

						if (regionFace.flipped) {
							regionMesh.uvs[0 + vertexIndex] = rotatedTriangleUV[2];
							regionMesh.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
							regionMesh.uvs[2 + vertexIndex] = rotatedTriangleUV[1];
						} else {
							regionMesh.uvs[0 + vertexIndex] = rotatedTriangleUV[1];
							regionMesh.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
							regionMesh.uvs[2 + vertexIndex] = rotatedTriangleUV[2];
						}
					} else {
						if (regionFace.flipped) {
							Swap!(triangleUV[0], triangleUV[1]);
							Swap!(triangleUV[2], triangleUV[3]);
						}

						regionMesh.uvs[0 + vertexIndex] = triangleUV[0];
						regionMesh.uvs[1 + vertexIndex] = triangleUV[3];
						regionMesh.uvs[2 + vertexIndex] = triangleUV[1];

						regionMesh.uvs[3 + vertexIndex] = triangleUV[1];
						regionMesh.uvs[4 + vertexIndex] = triangleUV[3];
						regionMesh.uvs[5 + vertexIndex] = triangleUV[2];

						i++;
					}
				}
				
				regionMesh.SetDirty();
			}
		} 
	}
}
