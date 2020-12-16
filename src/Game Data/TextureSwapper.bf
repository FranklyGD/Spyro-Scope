using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureSwapper {
		Emulator.Address address;
		public uint8 textureIndex;
		
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

		public this(Emulator.Address address) {
			this = ?;

			this.address = address;
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
				Terrain.textures[(int)textureIndex * quadCount + i] = Terrain.textures[(int)sourceTextureIndex * quadCount + i];
			}
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 8 + ((uint32)keyframeIndex) * 4, &keyframeData, 4);
			return keyframeData;
		}
		
		public void UpdateUVs(bool transparent) {
			let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;
			TextureQuad* quad = &Terrain.textures[textureIndex * quadCount];
			if (Emulator.installment != .SpyroTheDragon) {
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
