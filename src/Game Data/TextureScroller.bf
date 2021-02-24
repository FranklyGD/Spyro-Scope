using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureScroller {
		Emulator.Address address;
		public uint8 textureIndex;
		
		public Dictionary<uint8, List<int>> affectedTriangles = new .();
		public Dictionary<uint8, List<int>> affectedTransparentTriangles = new .();
		
		public struct KeyframeData {
			public uint8 a, nextFrame, b, verticalOffset;
		}

		public uint8 CurrentKeyframe {
			get {
				uint8 currentKeyframe = ?;
				Emulator.active.ReadFromRAM(address + 2, &currentKeyframe, 1);
				return currentKeyframe;
			}
		}

		public this(Emulator.Address address) {
			this = ?;

			this.address = address;

			Emulator.active.ReadFromRAM(address + 4, &textureIndex, 1);
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
			for (let pair in affectedTriangles) {
				delete pair.value;
			}
			affectedTriangles.Clear();
			for (let pair in affectedTransparentTriangles) {
				delete pair.value;
			}
			affectedTransparentTriangles.Clear();

			if (address.IsNull)
				return;

			for (let regionIndex < Terrain.regions.Count) {
				let terrainRegion = Terrain.regions[regionIndex];

				for (var triangleIndex = 0; triangleIndex < terrainRegion.nearFaceIndices.Count; triangleIndex++) {
					let nearFace = terrainRegion.GetNearFace(terrainRegion.nearFaceIndices[triangleIndex]);
					if (nearFace.renderInfo.textureIndex == textureIndex) {
						if (!affectedTriangles.ContainsKey((.)regionIndex)) {
							affectedTriangles[(.)regionIndex] = new .();
						}
						affectedTriangles[(.)regionIndex].Add(triangleIndex);
					}
				}
				
				for (var triangleIndex = 0; triangleIndex < terrainRegion.nearFaceTransparentIndices.Count; triangleIndex++) {
					let nearFace = terrainRegion.GetNearFace(terrainRegion.nearFaceTransparentIndices[triangleIndex]);
					if (nearFace.renderInfo.textureIndex == textureIndex) {
						if (!affectedTransparentTriangles.ContainsKey((.)regionIndex)) {
							affectedTransparentTriangles[(.)regionIndex] = new .();
						}
						affectedTransparentTriangles[(.)regionIndex].Add(triangleIndex);
					}
				}
			}
		}

		public void GetUsedTextures() {
			if (!Terrain.usedTextureIndices.Contains(textureIndex)) {
				Terrain.usedTextureIndices.Add(textureIndex);
			}
		}

		public void Decode() {
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			for (let i < quadCount) {
				let quad = (TextureQuad*)&Terrain.textures[textureIndex * quadCount + i];

				let verticalQuad = ((quad.texturePage & 0x80 > 0) ? 3 : 2) - ((Emulator.active.installment == .SpyroTheDragon) ? 1 : 0);
				quad.leftSkew = 0;
				quad.rightSkew = (uint8)(verticalQuad * 0x20 - 1);
				quad.Decode();
			}
		}

		// Derived from Spyro the Dragon [8002b578]
		// Derived from Spyro: Ripto's Rage [8002270c]
		public void Update() {
			uint8 verticalPosition = ?;
			Emulator.active.ReadFromRAM(address + 6, &verticalPosition, 1);

			let quadVerticalPosition = verticalPosition >> 2;

			if (Emulator.active.installment == .SpyroTheDragon) {
				let textureLOD = (TextureQuad*)&Terrain.textures[(int)textureIndex * 21];

				textureLOD[0].leftSkew = textureLOD[0].rightSkew = quadVerticalPosition;
				for (uint8 i < 4) {
					textureLOD[1 + i].leftSkew = textureLOD[1 + i].rightSkew = ((verticalPosition >> 1) + (i / 2 * 0x20)) & 0x3f;
				}
				for (uint8 i < 16) {
					textureLOD[5 + i].leftSkew = textureLOD[5 + i].rightSkew = (verticalPosition + (i / 4 * 0x20)) & 0x3f;
				}
			} else {
				let textureLOD = (TextureLOD*)&Terrain.textures[(int)textureIndex * 6];
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
			Emulator.active.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}

		public void UpdateUVs(bool transparent) {
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			TextureQuad* quad = &Terrain.textures[textureIndex * quadCount];
			if (Emulator.active.installment != .SpyroTheDragon) {
				quad++;
			}

			float[4 * 5][2] triangleUV = ?;
			for (let qi < 5) {
				let partialUV = quad.GetVramPartialUV();

				let offset = qi * 4;
				triangleUV[0 + offset] = .(partialUV.left, partialUV.rightY);
				triangleUV[1 + offset] = .(partialUV.right, partialUV.rightY);
				triangleUV[2 + offset] = .(partialUV.right, partialUV.leftY);
				triangleUV[3 + offset] = .(partialUV.left, partialUV.leftY);

				quad++;
			}

			let affectedTriangles = transparent ? affectedTransparentTriangles : affectedTriangles;
			for (let affectedRegionTriPair in affectedTriangles) {
				let terrainRegion = Terrain.regions[affectedRegionTriPair.key];
				terrainRegion.UpdateUVs(affectedRegionTriPair.value, triangleUV, transparent);
			}
		} 
	}
}
