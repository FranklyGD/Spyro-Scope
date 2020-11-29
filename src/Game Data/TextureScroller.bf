using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureScroller {
		Emulator.Address address;
		public uint8 textureIndex;
		
		public TerrainRegion[] visualMeshes;
		public Dictionary<uint8, List<int>> affectedTriangles = new .();
		public Dictionary<uint8, List<int>> affectedTransparentTriangles = new .();
		
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
			if (!Terrain.usedTextureIndices.Contains(textureIndex)) {
				Terrain.usedTextureIndices.Add(textureIndex);
			}

			affectedTriangles.Clear();
			affectedTransparentTriangles.Clear();

			if (address.IsNull)
				return;
			
			Emulator.ReadFromRAM(address + 4, &textureIndex, 1);

			// Append the missing parts of the scrolling textures to the main decoded one
			// They only exist against the top edge of the VRAM because of how they are programmed

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
				let verticalQuad = (quad.texturePage & 0x80 > 0) ? 3 : 2;
				for (let s < verticalQuad) {
					quad.leftSkew = (uint8)s * 0x20;
					quad.rightSkew = quad.leftSkew + 0x1f;

					VRAM.Decode(quad.texturePage, quad.left, quad.leftSkew, 32, 32, (quad.texturePage & 0x80 > 0) ? 8 : 4, quad.clut);
				}

				quad++;
			}

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
			uint8 verticalPosition = ?;
			Emulator.ReadFromRAM(address + 6, &verticalPosition, 1);

			let quadVerticalPosition = verticalPosition >> 2;

			if (Emulator.installment == .SpyroTheDragon) {
				let textureLOD = (TextureQuad*)&Terrain.texturesLODs1[textureIndex];

				textureLOD[0].leftSkew = textureLOD[0].rightSkew = quadVerticalPosition;
				for (uint8 i < 4) {
					textureLOD[1 + i].leftSkew = textureLOD[1 + i].rightSkew = ((verticalPosition >> 1) + (i / 2 * 0x20)) & 0x3f;
				}
				for (uint8 i < 16) {
					textureLOD[5 + i].leftSkew = textureLOD[5 + i].rightSkew = (verticalPosition + (i / 4 * 0x20)) & 0x3f;
				}
			} else {
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
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}

		public void UpdateUVs(bool transparent) {
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
