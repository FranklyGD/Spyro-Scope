using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureSwapper {
		Emulator.Address address;
		public uint8 textureIndex;
		List<uint8> textureFrameIndices = new .();
		
		public Dictionary<uint8, List<int>> affectedOpaqueTriangles = new .();
		public Dictionary<uint8, List<int>> affectedTransparentTriangles = new .();

		public struct KeyframeData {
			public uint8 a, nextFrame, b, textureIndex;
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
		}

		public void Dispose() {
			delete textureFrameIndices;

			for (var pair in affectedOpaqueTriangles) {
				delete pair.value;
			}
			delete affectedOpaqueTriangles;

			for (var pair in affectedTransparentTriangles) {
				delete pair.value;
			}
			delete affectedTransparentTriangles;
		}

		public void Reload() mut {
			affectedOpaqueTriangles.Clear();
			affectedTransparentTriangles.Clear();

			if (address.IsNull)
				return;
			
			Emulator.active.ReadFromRAM(address + 4, &textureIndex, 1);

			for (let regionIndex < (uint8)Terrain.regions.Count) {
				let terrainRegion = Terrain.regions[regionIndex];

				List<int> affectedOpaqueTriangles = new .();
				List<int> affectedTransparentTriangles = new .();

				terrainRegion.GetTriangleFromTexture(textureIndex, affectedOpaqueTriangles, affectedTransparentTriangles);

				this.affectedOpaqueTriangles[regionIndex] = affectedOpaqueTriangles;
				this.affectedTransparentTriangles[regionIndex] = affectedTransparentTriangles;
			}
		}

		public void GetUsedTextures() {
			uint8 keyframe = 0;
			while (textureFrameIndices.Count == 0 || keyframe > 0) {
				let keyframeData = GetKeyframeData(keyframe);
				textureFrameIndices.Add(keyframeData.textureIndex);
				keyframe = keyframeData.nextFrame;
			}

			for (let textureIndex in textureFrameIndices) {
				if (!Terrain.usedTextureIndices.ContainsKey(textureIndex)) {
					Terrain.usedTextureIndices.Add(textureIndex, new .());
				}
			}
		}
		
		public void Decode() {
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			for (let textureFrame in textureFrameIndices) {
				for (let i < quadCount) {
					Terrain.textures[textureFrame * quadCount + i].Decode();
				}
			}
		}

		// Derived from Spyro the Dragon [8002b578]
		// Derived from Spyro: Ripto's Rage [8002270c]
		public void Update() {
			uint8 sourceTextureIndex = ?;
			Emulator.active.ReadFromRAM(address + 8 + (int)CurrentKeyframe * 4 + 3, &sourceTextureIndex, 1);
			
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			for (let i < quadCount) {
				Terrain.textures[(int)textureIndex * quadCount + i] = Terrain.textures[(int)sourceTextureIndex * quadCount + i];
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

			Vector2[5][4] triangleUV = ?;
			for (let qi < 5) {
				let partialUV = quad.GetVramPartialUV();

				triangleUV[qi][0] = .(partialUV.left, partialUV.rightY);
				triangleUV[qi][1] = .(partialUV.right, partialUV.rightY);
				triangleUV[qi][2] = .(partialUV.right, partialUV.leftY);
				triangleUV[qi][3] = .(partialUV.left, partialUV.leftY);

				quad++;
			}

			let affectedTriangles = transparent ? affectedTransparentTriangles : affectedOpaqueTriangles;
			for (let affectedRegionTriPair in affectedTriangles) {
				let terrainRegion = Terrain.regions[affectedRegionTriPair.key];
				terrainRegion.UpdateUVs(affectedRegionTriPair.value, triangleUV, transparent);
			}
		} 
	}
}
