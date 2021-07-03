namespace SpyroScope {
	class NearFaceInspector : Inspector {
		Property rotationProperty;
		public this() : base("Near Face") {
			Anchor = .(0,1,0,1);
			Offset = .(4,-4,24,-4);

			area.Offset.Shift(0, 128 + 1);

			if (Emulator.active.installment == .SpyroTheDragon) {
				AddProperty("Texture #", 0x8, 0, 7);
				rotationProperty = AddProperty("Rotation", 0x9, 0, 2);
				AddProperty("Depth Offset", 0xc, 3, 3);
				AddProperty("Flip Face", 0xc, 1);
				AddProperty("Double Sided", 0xc, 2);
			} else {
				AddProperty("Texture #", 0xc, 0, 7);
				rotationProperty = AddProperty("Rotation", 0xd, 4, 2);
				AddProperty("Depth Offset", 0xd, 0, 2);
				AddProperty("Flip Face", 0xd, 2);
				AddProperty("Double Sided", 0xd, 3);
			}
		}

		public override void OnDataSet(Emulator.Address address, void* reference) {
			let faceReference = (TerrainRegion.NearFace*)reference;

			rotationProperty.ReadOnly = !faceReference.isTriangle;
		}

		public override void OnDataModified(Emulator.Address address, void* reference) {
			let regionIndex = ViewerSelection.currentRegionIndex;
			if (regionIndex > -1) {
				let region = Terrain.regions[regionIndex];
				let currentTriangleIndex = ViewerSelection.currentTriangleIndex;

				int faceIndex = ?;

				if (ViewerSelection.currentRegionTransparent) {
				    faceIndex = region.nearFaceTransparentIndices[currentTriangleIndex];
				} else {
				    faceIndex = region.nearFaceIndices[currentTriangleIndex];
				}

				region.SetNearFace((.)reference, faceIndex);
			}
		}

		public override void Draw() {
			base.Draw();
			
			let regionIndex = ViewerSelection.currentRegionIndex;
			if (regionIndex > -1) {
				let region = Terrain.regions[regionIndex];
				let currentTriangleIndex = ViewerSelection.currentTriangleIndex;

				int faceIndex = ?;
				if (ViewerSelection.currentRegionTransparent) {
					faceIndex = region.nearFaceTransparentIndices[currentTriangleIndex];
				} else {
					faceIndex = region.nearFaceIndices[currentTriangleIndex];
				}
	
				let face = region.GetNearFace(faceIndex);
	
				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
				TextureQuad* textureInfo = &Terrain.textures[face.renderInfo.textureIndex * quadCount];
				if (Emulator.active.installment != .SpyroTheDragon) {
					textureInfo++;
				}
	
				var partialUV = textureInfo[0].GetVramPartialUV();
				DrawUtilities.Rect(drawn.top + WindowApp.bitmapFont.height, drawn.top + WindowApp.bitmapFont.height + 128, drawn.left + WindowApp.bitmapFont.characterWidth, drawn.left + WindowApp.bitmapFont.characterWidth + 128, partialUV.leftY, partialUV.leftY + (1f / 16), partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
	
				const int[4][2] offsets = .(
					(128, 0),
					(128 + 64, 0),
					(128, 64),
					(128 + 64, 64),
				);
				for (let qi < 4) {
					var offset = offsets[qi];
					offset[0] += WindowApp.bitmapFont.characterWidth * 2;
					offset[1] += WindowApp.bitmapFont.height;
	
					partialUV = textureInfo[1 + qi].GetVramPartialUV();
					DrawUtilities.Rect(drawn.top + offset[1], drawn.top + offset[1] + 64, drawn.left + offset[0], drawn.left + offset[0] + 64, partialUV.leftY, partialUV.leftY + (1f / 16), partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
				}
			}
		}
	}
}