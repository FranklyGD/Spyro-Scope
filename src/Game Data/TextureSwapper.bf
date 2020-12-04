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

		public void GetUsedTextures() {
			uint8 keyframe = 0;
			List<uint8> usedTextures = scope .();
			while (usedTextures.Count == 0 || keyframe > 0) {
				let keyframeData = GetKeyframeData(keyframe);
				usedTextures.Add(keyframeData.textureIndex);
				keyframe = keyframeData.nextFrame;
			}

			for (let textureIndex in usedTextures) {
				if (!Terrain.usedTextureIndices.Contains(textureIndex)) {
					Terrain.usedTextureIndices.Add(textureIndex);
				}
			}
		}

		// Derived from Spyro the Dragon [8002b578]
		// Derived from Spyro: Ripto's Rage [8002270c]
		public void Update() {
			uint8 sourceTextureIndex = ?;
			Emulator.ReadFromRAM(address + 8 + (int)CurrentKeyframe * 4 + 3, &sourceTextureIndex, 1);
			
			let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;
			for (let i < quadCount) {
				Terrain.textureInfos[(int)textureIndex * quadCount + i] = Terrain.textureInfos[(int)sourceTextureIndex * quadCount + i];
			}
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}
		
		public void UpdateUVs(bool transparent) {
			let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;
			TextureQuad* quad = &Terrain.textureInfos[(int)textureIndex * quadCount];
			if (Emulator.installment != .SpyroTheDragon) {
				quad++;
			}

			let partialUV = quad.GetVramPartialUV();

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
