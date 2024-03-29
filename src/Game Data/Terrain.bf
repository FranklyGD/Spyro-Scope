using OpenGL;
using System;
using System.Collections;
using System.IO;

namespace SpyroScope {
	static class Terrain {
		public static TerrainCollision collision;

		public static uint32 RegionCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(Emulator.sceneRegionPointers[(int)Emulator.active.rom] + 4, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value ;
				Emulator.active.WriteToRAM(Emulator.sceneRegionPointers[(int)Emulator.active.rom] + 4, &value, 4);
			}
		}

		public static TerrainRegion[] regions;

		public static uint32 FarAnimatedCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(Emulator.farRegionDeformPointers[(int)Emulator.active.rom] - 4, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value;
				Emulator.active.WriteToRAM(Emulator.farRegionDeformPointers[(int)Emulator.active.rom] - 4, &value, 4);
			}
		}

		public static RegionAnimation[] farAnimations;

		public static uint32 NearAnimatedCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(Emulator.nearRegionDeformPointers[(int)Emulator.active.rom] - 4, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value;
				Emulator.active.WriteToRAM(Emulator.nearRegionDeformPointers[(int)Emulator.active.rom] - 4, &value, 4);
			}
		}

		public static RegionAnimation[] nearAnimations;

		public static Dictionary<uint8, Dictionary<uint32, List<int>>> usedTextureIndices;
		public static TextureQuad[] textures;
		public static TextureScroller[] textureScrollers;
		public static TextureSwapper[] textureSwappers;

		public enum RenderMode {
			Collision,
			Far,
			NearLQ,
			NearHQ
		}
		public static RenderMode renderMode = .Collision;
		
		public static bool solid = true;
		public static bool wireframe = true;
		public static bool textured = true;

		static bool useFade = false;
		public static bool UsingFade {
			get => useFade;
			set {
				if (value) {
					for (let region in regions) {
						region.ApplyNearColor(true);
					}
				} else if (colored) {
					for (let region in regions) {
						region.ApplyNearColor(false);
					}
				} else {
					for (let region in regions) {
						region.ClearNearColor();
					}
				}

				useFade = value;
			}
		}

		static bool colored = true;
		public static bool Colored {
			get => colored;
			set {
				if (value) {
					for (let region in regions) {
						region.ApplyNearColor(useFade);
					}
				} else {
					for (let region in regions) {
						region.ClearNearColor();
					}
				}

				colored = value;
			}
		}

		public static bool decoded;

		public static void Load() {
			Reload();

			if (Emulator.active.loadingStatus == .Idle) {
				ReloadAnimations();
			}
		}

		public static void Dispose() {
			DeleteAndNullify!(collision);

			DeleteContainerAndItems!(regions);
			regions = null;
			decoded = false;

			if (farAnimations != null) {
				for (var item in farAnimations) {
					item.Dispose();
				}
				DeleteAndNullify!(farAnimations);
			}

			if (nearAnimations != null) {
				for (var item in nearAnimations) {
					item.Dispose();
				}
				DeleteAndNullify!(nearAnimations);
			}
			
			if (textureScrollers != null) {
				for (var item in textureScrollers) {
					item.Dispose();
				}
				DeleteAndNullify!(textureScrollers);
			}
				
			if (textureSwappers != null) {
				for (var item in textureSwappers) {
					item.Dispose();
				}
				DeleteAndNullify!(textureSwappers);
			}

			if (usedTextureIndices != null) {
				for (let usedTextureIndex in usedTextureIndices) {
					for (let region in usedTextureIndex.value) {
						delete region.value;
					}
					delete usedTextureIndex.value;
				}
				delete usedTextureIndices;
			}

			DeleteAndNullify!(textures);
		}

		public static void Reload() {
			// Collision
			delete collision;
			if (Emulator.active.installment == .SpyroTheDragon && (Emulator.active.gameState == 13 || Emulator.active.gameState == 14)) {
				collision = null;
			} else {
				Emulator.Address address = ?;
				Emulator.collisionDataPointers[(int)Emulator.active.rom].Read(&address);

				Emulator.Address deformAddress = ?;
				Emulator.collisionDeformDataPointers[(int)Emulator.active.rom].Read(&deformAddress);

				collision = new .(address, deformAddress);
			}

			usedTextureIndices = new .();

			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			Emulator.sceneRegionPointers[(int)Emulator.active.rom].Read(&sceneDataRegionArrayAddress);
			let sceneRegionCount = RegionCount;

			// Remove any existing parsed data
			DeleteContainerAndItems!(regions);

			// Parse all terrain regions
			regions = new .[sceneRegionCount];

			Emulator.Address[] sceneDataRegionAddresses = new .[sceneRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegionAddresses[0], sceneRegionCount);
			for (let regionIndex < sceneRegionCount) {
				let region = new TerrainRegion(sceneDataRegionAddresses[regionIndex]);

				Dictionary<uint8, List<uint8>> usedRegionTextureIndices = new .();
				region.GetUsedTextures(usedRegionTextureIndices);
				// Add texture indices
				for (let usedTextureIndex in usedRegionTextureIndices) {
					// Add new entry if it does not exist
					if (!usedTextureIndices.ContainsKey(usedTextureIndex.key)) {
						usedTextureIndices.Add((usedTextureIndex.key, new .()));
					}

					// Add this region (always new)
					usedTextureIndices[usedTextureIndex.key].Add(regionIndex, new .());

					// Add all face indices used in this region
					for (let faces in usedTextureIndex.value) {
						usedTextureIndices[usedTextureIndex.key][regionIndex].Add(faces);
					}
				}
				DeleteDictionaryAndValues!(usedRegionTextureIndices);

				regions[regionIndex] = region;
			}
			delete sceneDataRegionAddresses;

			// Scrolling textures
			if (textureScrollers != null) {
				for (let item in textureScrollers) {
					item.Dispose();
				}
				delete textureScrollers;
			}

			uint32 textureScrollerCount = 0;
			let textureScrollerPointer = Emulator.textureScrollerPointers[(int)Emulator.active.rom];
			if (Emulator.active.loadingStatus == .Idle) {
				Emulator.active.ReadFromRAM(textureScrollerPointer - 4, &textureScrollerCount, 4);
			}

			textureScrollers = new .[textureScrollerCount];
			if (textureScrollerCount > 0) {
				Emulator.Address<Emulator.Address> textureScrollerArrayAddress = ?;
				textureScrollerPointer.Read(&textureScrollerArrayAddress);
	
				Emulator.Address[] textureScrollerAddresses = new .[textureScrollerCount];
				textureScrollerArrayAddress.ReadArray(&textureScrollerAddresses[0], textureScrollerCount);
				for (let i < textureScrollerCount) {
					let scroller = TextureScroller(textureScrollerAddresses[i]);
					scroller.GetUsedTextures();
					textureScrollers[i] = scroller;
				}
				delete textureScrollerAddresses;
			}

			// Swapping textures
			if (textureSwappers != null) {
				for (let item in textureSwappers) {
					item.Dispose();
				}
				delete textureSwappers;
			}


			uint32 textureSwapperCount = 0;
			let textureSwapperPointer = Emulator.textureSwapperPointers[(int)Emulator.active.rom];
			if (Emulator.active.loadingStatus == .Idle) {
				Emulator.active.ReadFromRAM(textureSwapperPointer - 4, &textureSwapperCount, 4);
			}

			textureSwappers = new .[textureSwapperCount];
			if (textureSwapperCount > 0) {
				Emulator.Address<Emulator.Address> textureScrollerArrayAddress = ?;
				textureSwapperPointer.Read(&textureScrollerArrayAddress);

				Emulator.Address[] textureScrollerAddresses = new .[textureSwapperCount];
				textureScrollerArrayAddress.ReadArray(&textureScrollerAddresses[0], textureSwapperCount);
				for (let i < textureSwapperCount) {
					let swapper = TextureSwapper(textureScrollerAddresses[i]);
					swapper.GetUsedTextures();
					textureSwappers[i] = swapper;
				}
				delete textureScrollerAddresses;
			}

			// Get max amount of possible textures
			var highestUsedIndex = -1;
			for (let textureIndex in usedTextureIndices.Keys) {
				if (textureIndex > highestUsedIndex) {
					highestUsedIndex = textureIndex;
				}
			}

			if (textures != null) {
				delete textures;
			}
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;

			let totalQuadCount = (highestUsedIndex + 1) * quadCount;
			Emulator.Address<TextureQuad> textureDataAddress = ?;
			Emulator.textureDataPointers[(int)Emulator.active.rom].Read(&textureDataAddress);
			textures = new .[totalQuadCount];
			textureDataAddress.ReadArray(&textures[0], totalQuadCount);

			for (let regionIndex < sceneRegionCount) {
				regions[regionIndex].Reload();
				if (colored) {
					regions[regionIndex].ApplyNearColor(useFade);
				}
			}
			
			for (let scrollerIndex < textureScrollerCount) {
				textureScrollers[scrollerIndex].Reload();
			}

			for (let swapperIndex < textureSwapperCount) {
				textureSwappers[swapperIndex].Reload();
			}

			for (let usedTextureIndex in usedTextureIndices) {
				for (let regionFaces in usedTextureIndex.value) {
					let region = regions[regionFaces.key];
					List<int> opaqueTriangles = scope .();
					List<int> transparentTriangles = scope .();

					region.GetTriangleFromTexture(usedTextureIndex.key, opaqueTriangles, transparentTriangles);

					TextureQuad* quad = &Terrain.textures[usedTextureIndex.key * quadCount];
					if (Emulator.active.installment != .SpyroTheDragon) {
						quad++;
					}

					Vector2[5][4] uvs = ?;
					for (let qi < 5) {
						uvs[qi] = quad.GetVramUVs();
						quad++;
					}

					region.UpdateUVs(opaqueTriangles, uvs, false);
					region.UpdateUVs(transparentTriangles, uvs, true);
				}
			}

			// Delete animations as the new loaded mesh may be incompatible
			if (nearAnimations != null) {
				for (let item in nearAnimations) {
					item.Dispose();
				}
				DeleteAndNullify!(nearAnimations);
			}

			// Derived from Spyro: Ripto's Rage [80023994] TODO
			/*float clock = 0;

			Emulator.Address warpingRegionArrayPointer = ?;
			Emulator.warpingRegionPointers[(int)Emulator.active.rom].Read(&warpingRegionArrayPointer);
			uint32 waterRegionOffset = ?;
			Emulator.active.ReadFromRAM(warpingRegionArrayPointer, &waterRegionOffset, 4);
			warpingRegionArrayPointer += waterRegionOffset;
			uint32 waterRegionCount = ?;
			Emulator.active.ReadFromRAM(warpingRegionArrayPointer, &waterRegionCount, 4);
			uint32[] warpData = new .[waterRegionCount];
			Emulator.active.ReadFromRAM(warpingRegionArrayPointer + 4, warpData.CArray(), waterRegionCount * 4);
			for (let i < waterRegionCount) {
				let regionIndex = warpData[i] & 0xff;
				let begin = warpingRegionArrayPointer + (warpData[i] >> 0x10);
				let end = begin + (warpData[i] >> 6 & 0x3fc);
				let count = (int)(end - begin) / 4;

				uint32[] dataArray = scope .[count];
				Emulator.active.ReadFromRAM(begin, dataArray.CArray(), count);
				for (let ii < count) {
					let data = dataArray[ii];
					visualMeshes[regionIndex].vertices Math.Cos((float)(data + clock) / 128 * Math.PI_f * 2) * 20 + (data >> 0x10) |  & 0xfffffc00;
				}
			}
			delete warpData;*/
		}

		public static void Decode() {
			if (usedTextureIndices != null) {
				// Convert any used VRAM textures for previewing
				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
				let quadDecodeCount = Emulator.active.installment == .SpyroTheDragon ? 5 : 6;
	
				// Temporarily remove affected textures
				List<(uint8, Dictionary<uint32, List<int>>)> tempAnimated = scope .();
	
				if (textureScrollers != null) {
					for (let textureScroller in textureScrollers) {
						if (Terrain.usedTextureIndices.GetAndRemove(textureScroller.textureIndex) case .Ok(var pair)) {
							tempAnimated.Add(pair);
						}
					}
				}
				
				if (textureSwappers != null) {
					for (let textureSwapper in textureSwappers) {
						if (Terrain.usedTextureIndices.GetAndRemove(textureSwapper.textureIndex) case .Ok(var pair)) {
							tempAnimated.Add(pair);
						}
					}
				}
	
				// The loop is done in reverse to counteract strange used texture info indices
				// in "Spyro the Dragon", by overwriting the incorrect decoded parts with correct ones
				let textureIndices = scope List<uint8>(usedTextureIndices.Keys);
				for (var textureIndex = textureIndices.Count - 1; textureIndex >= 0; textureIndex--) {
					for (let i < quadDecodeCount) {
						let textureQuadIndex = textureIndices[textureIndex] * quadCount + i;
						textures[textureQuadIndex].Decode();
					}
				}
	
				// Restore and decode the remaining textures with special functions
				for (let animated in tempAnimated) {
					usedTextureIndices.Add(animated);
				}
	
				if (textureScrollers != null) {
					for (let textureScroller in textureScrollers) {
						textureScroller.Decode();
					}
				}
					
				if (textureSwappers != null) {
					for (let textureSwapper in textureSwappers) {
						textureSwapper.Decode();
					}
				}
			}

			decoded = true;
		}

		public static void Update() {
			if (renderMode == .Collision && collision != null) {
				collision.Update();
			} else {
				if (farAnimations != null) {
					for (let animation in farAnimations) {
						animation.Update(regions[animation.regionIndex].farMesh);
					}
				}

				if (nearAnimations != null) {
					for (let animation in nearAnimations) {
						let region = regions[animation.regionIndex];
						animation.Update(region.nearMesh);
						animation.UpdateSubdivided(region);
					}
				}
			}

			UpdateTextureInfo(true);
			
			for (let terrainRegion in regions) {
				terrainRegion.farMesh.Update();
				terrainRegion.nearMesh.Update();
				terrainRegion.nearMeshSubdivided.Update();
				terrainRegion.nearMeshTransparent.Update();
				terrainRegion.nearMeshTransparentSubdivided.Update();
			}
		}

		public static void Draw() {
			Renderer.SetTint(.(255,255,255));
			Renderer.BeginSolid();

			if (renderMode == .Collision && collision != null) {
				if (solid) {
					collision.Draw();
				}
				if (wireframe) {
					if (solid) {
						Renderer.SetTint(.(192,192,192));
					}

					Renderer.BeginWireframe();
					collision.Draw();
				}
				
				Renderer.BeginWireframe();
				collision.DrawDeformFrames();
				Renderer.BeginSolid();

				collision.DrawGrid();
			} else if (regions != null) {
				Renderer.BeginRetroShading();
				Renderer.halfWhiteTexture.Bind();

				if (renderMode == .Far) {
					if (solid) {
						for (let visualMesh in regions) {
							visualMesh.DrawFar();
						}
					}

					if (wireframe) {
						if (solid) {
							Renderer.SetTint(.(192,192,192));
						}

						Renderer.BeginWireframe();
						for (let visualMesh in regions) {
							visualMesh.DrawFar();
						}
					}
					
					Renderer.SetTint(.(255,255,255));
				} else {
					if (textured && !useFade && VRAM.decoded != null) {
						VRAM.decoded.Bind();
					}

					if (solid) {
						DrawNearLQ();
					}

					if (wireframe) {
						if (solid) {
							Renderer.SetTint(.(192,192,192));
						}

						Renderer.BeginWireframe();
						DrawNearLQ();
					}
					
					Renderer.SetTint(.(255,255,255));
				}
				
				Renderer.BeginDefaultShading();
				Renderer.whiteTexture.Bind();
			}
				
			// Restore polygon mode to default
			Renderer.BeginSolid();
		}

		static void DrawNearLQ() {
			if (renderMode == .NearLQ) {
				for (let visualMesh in regions) {
					visualMesh.DrawNear();
				}
			} else {
				for (let visualMesh in regions) {
					visualMesh.DrawNearSubdivided();
				}
			}
				
			GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
			GL.glDepthMask(GL.GL_FALSE);  

			if (renderMode == .NearLQ) {
				for (let visualMesh in regions) {
					visualMesh.DrawNearTransparent();
				}
			} else {
				for (let visualMesh in regions) {
					visualMesh.DrawNearTransparentSubdivided();
				}
			}

			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
			GL.glDepthMask(GL.GL_TRUE);
		}

		public static void ReloadAnimations() {
			if (farAnimations != null) {
				for (var item in farAnimations) {
					item.Dispose();
				}
				delete farAnimations;
			}

			uint32 count = FarAnimatedCount;
			farAnimations = new .[count];

			Emulator.Address sceneDeformArray = ?;
			Emulator.farRegionDeformPointers[(int)Emulator.active.rom].Read(&sceneDeformArray);
			var animationPointers = scope Emulator.Address[count];
			Emulator.active.ReadFromRAM(sceneDeformArray, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &farAnimations[animationIndex];
				*animation = .(animationPointers[animationIndex]);

				let region = regions[animation.regionIndex];
				var triOrQuad = scope bool[region.FarLOD.faceCount];

				for (let i < triOrQuad.Count) {
					triOrQuad[i] = region.farFaces[i].isTriangle;
				}

				animation.Reload(region.farMesh2GameIndices, triOrQuad, region.farFaceIndices, region.farMesh);
			}
			
			if (nearAnimations != null) {
				for (var item in nearAnimations) {
					item.Dispose();
				}
				delete nearAnimations;
			}

			count = NearAnimatedCount;
			nearAnimations = new .[count];

			Emulator.nearRegionDeformPointers[(int)Emulator.active.rom].Read(&sceneDeformArray);
			animationPointers = scope Emulator.Address[count];
			Emulator.active.ReadFromRAM(sceneDeformArray, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &nearAnimations[animationIndex];
				*animation = .(animationPointers[animationIndex]);

				let region = regions[animation.regionIndex];
				var triOrQuad = scope bool[region.NearLOD.faceCount];

				for (let i < triOrQuad.Count) {
					triOrQuad[i] = region.GetNearFace(i).isTriangle;
				}

				animation.Reload(region.nearMesh2GameIndices, triOrQuad, region.nearFaceIndices, region.nearMesh);
			}
		}

		public static void UpdateTextureInfo(bool updateUVs) {
			for (let textureScroller in textureScrollers) {
				textureScroller.Update();
				textureScroller.UpdateUVs(false);
				textureScroller.UpdateUVs(true);
			}

			for (let textureSwapper in textureSwappers) {
				textureSwapper.Update();
				textureSwapper.UpdateUVs(false);
				textureSwapper.UpdateUVs(true);
			}
		}

		public static void Export(String file) {
			FileStream stream = new .();
			stream.Create(file);

			// Collision
			let collisionTriangles = collision.[Friend]triangles;
			stream.Write((int32)collisionTriangles.Count);
			stream.Write(Span<CollisionTriangle>(collisionTriangles.Ptr, collisionTriangles.Count));
			
			// Texture Quad Info
			stream.Write((uint32)textures.Count);
			stream.Write(Span<TextureQuad>(textures));

			// Visual
			stream.Write((uint32)regions.Count);
			for (let region in regions) {
				stream.Write(region.metadata);
				Emulator.Address address = region.[Friend]address + 0x1c;

				// Far
				uint32[] packedVertices = scope .[region.FarLOD.vertexCount];
				Emulator.active.ReadFromRAM(address, packedVertices.CArray(), packedVertices.Count * 4);
				stream.Write(Span<uint32>(packedVertices));
				address += packedVertices.Count * 4;
				
				Renderer.Color4[] colors = scope .[region.FarLOD.colorCount];
				Emulator.active.ReadFromRAM(address, colors.CArray(), colors.Count * 4);
				stream.Write(Span<Renderer.Color4>(colors));
				address += colors.Count * 4;

				TerrainRegion.FarFace[] fface = scope .[region.FarLOD.faceCount];
				Emulator.active.ReadFromRAM(address, fface.CArray(), fface.Count * sizeof(TerrainRegion.FarFace));
				stream.Write(Span<TerrainRegion.FarFace>(fface));
				address += fface.Count * sizeof(TerrainRegion.FarFace);

				// Near
				packedVertices = scope .[region.NearLOD.vertexCount];
				Emulator.active.ReadFromRAM(address, packedVertices.CArray(), packedVertices.Count * 4);
				stream.Write(Span<uint32>(packedVertices));
				address += packedVertices.Count * 4;

				colors = scope .[(int)region.NearLOD.colorCount * 2];
				Emulator.active.ReadFromRAM(address, colors.CArray(), colors.Count * 4);
				stream.Write(Span<Renderer.Color4>(colors));
				address += colors.Count * 4;

				TerrainRegion.NearFace[] nfaces = scope .[region.NearLOD.faceCount];
				Emulator.active.ReadFromRAM(address, nfaces.CArray(), nfaces.Count * sizeof(TerrainRegion.NearFace));
				stream.Write(Span<TerrainRegion.NearFace>(nfaces));
			}

			delete stream;
		}
	}
}