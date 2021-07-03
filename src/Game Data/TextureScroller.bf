using OpenGL;
using System.Collections;

namespace SpyroScope {
	struct TextureScroller {
		Emulator.Address address;
		public uint8 textureIndex;
		
		public Dictionary<uint8, List<int>> affectedOpaqueTriangles = new .();
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
			for (let pair in affectedOpaqueTriangles) {
				delete pair.value;
			}
			affectedOpaqueTriangles.Clear();
			for (let pair in affectedTransparentTriangles) {
				delete pair.value;
			}
			affectedTransparentTriangles.Clear();

			if (address.IsNull)
				return;

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
			if (!Terrain.usedTextureIndices.ContainsKey(textureIndex)) {
				Terrain.usedTextureIndices.Add(textureIndex, new .());
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
