using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	static class Terrain {
		public static TerrainCollision collision;
		public static TerrainRegion[] regions;

		public static RegionAnimation[] farAnimations;
		public static RegionAnimation[] nearAnimations;

		public static List<int> usedTextureIndices = new .() ~ delete _;
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
		public static bool wireframe;
		public static bool decoded;

		public static void Load() {
			Reload();
			ReloadAnimations();
		}

		public static void Clear() {
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

			DeleteAndNullify!(textures);
		}

		public static void Reload() {
			// Collision
			Emulator.Address address = ?;
			Emulator.collisionDataPointers[(int)Emulator.active.rom].Read(&address);
			Emulator.Address deformAddress = ?;
			Emulator.collisionDeformDataPointers[(int)Emulator.active.rom].Read(&deformAddress);

			delete collision;
			collision = new .(address, deformAddress);

			usedTextureIndices.Clear();

			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			let sceneDataRegionArrayPointer = Emulator.sceneRegionPointers[(int)Emulator.active.rom];
			sceneDataRegionArrayPointer.Read(&sceneDataRegionArrayAddress);
			uint32 sceneRegionCount = ?;
			Emulator.active.ReadFromRAM(sceneDataRegionArrayPointer + 4, &sceneRegionCount, 4);

			// Remove any existing parsed data
			DeleteContainerAndItems!(regions);

			// Parse all terrain regions
			regions = new .[sceneRegionCount];

			Emulator.Address[] sceneDataRegionAddresses = new .[sceneRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegionAddresses[0], sceneRegionCount);
			for (let regionIndex < sceneRegionCount) {
				let region = new TerrainRegion(sceneDataRegionAddresses[regionIndex]);
				region.GetUsedTextures();
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

			let textureScrollerPointer = Emulator.textureScrollerPointers[(int)Emulator.active.rom];
			uint32 textureScrollerCount = ?;
			Emulator.active.ReadFromRAM(textureScrollerPointer - 4, &textureScrollerCount, 4);
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

			let textureSwapperPointer = Emulator.textureSwapperPointers[(int)Emulator.active.rom];
			uint32 textureSwapperCount = ?;
			Emulator.active.ReadFromRAM(textureSwapperPointer - 4, &textureSwapperCount, 4);
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
			for (let textureIndex in usedTextureIndices) {
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
			}
			
			for (let scrollerIndex < textureScrollerCount) {
				textureScrollers[scrollerIndex].Reload();
			}

			for (let swapperIndex < textureSwapperCount) {
				textureSwappers[swapperIndex].Reload();
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
			// Convert any used VRAM textures for previewing
			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			let quadDecodeCount = Emulator.active.installment == .SpyroTheDragon ? 5 : 6;

			// Temporarily remove affected textures
			if (textureScrollers != null) {
				for (let textureScroller in textureScrollers) {
					Terrain.usedTextureIndices.Remove(textureScroller.textureIndex);
				}
			}
			
			if (textureSwappers != null) {
				for (let textureSwapper in textureSwappers) {
					Terrain.usedTextureIndices.Remove(textureSwapper.textureIndex);
				}
			}

			// The loop is done in reverse to counteract strange used texture info indices
			// in "Spyro the Dragon", by overwriting the incorrect decoded parts with correct ones
			usedTextureIndices.Sort(scope (x,y) => y <=> x);

			for (let textureIndex in usedTextureIndices) {
				for (let i < quadDecodeCount) {
					Terrain.textures[textureIndex * quadCount + i].Decode();
				}
			}

			// Restore and decode the remaining textures
			
			if (textureScrollers != null) {
				for (let textureScroller in textureScrollers) {
					Terrain.usedTextureIndices.Add(textureScroller.textureIndex);
					textureScroller.Decode();
				}
			}
				
			if (textureSwappers != null) {
				for (let textureSwapper in textureSwappers) {
					Terrain.usedTextureIndices.Add(textureSwapper.textureIndex);
					textureSwapper.Decode();
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

			if (wireframe) {
				Renderer.BeginWireframe();
			}

			if (renderMode == .Collision && collision != null) {
				collision.Draw(wireframe);
			} else if (regions != null) {
				Renderer.BeginRetroShading();

				if (renderMode == .Far) {
					Renderer.halfWhiteTexture.Bind();

					for (let visualMesh in regions) {
						visualMesh.DrawFar();
					}
				} else {
					VRAM.decoded?.Bind();

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
				
				Renderer.BeginDefaultShading();
				Renderer.whiteTexture.Bind();
			}
				
			// Restore polygon mode to default
			Renderer.BeginSolid();
		}

		public static void ReloadAnimations() {
			if (farAnimations != null) {
				for (var item in farAnimations) {
					item.Dispose();
				}
				delete farAnimations;
			}

			uint32 count = ?;
			Emulator.active.ReadFromRAM(Emulator.farRegionDeformPointers[(int)Emulator.active.rom] - 4, &count, 4);

			farAnimations = new .[count];

			Emulator.Address sceneDeformArray = ?;
			Emulator.farRegionDeformPointers[(int)Emulator.active.rom].Read(&sceneDeformArray);
			var animationPointers = scope Emulator.Address[count];
			Emulator.active.ReadFromRAM(sceneDeformArray, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &farAnimations[animationIndex];
				*animation = .(animationPointers[animationIndex]);

				let region = regions[animation.regionIndex];
				var triOrQuad = scope bool[region.metadata.farFaceCount];

				for (let i < region.metadata.farFaceCount) {
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

			Emulator.active.ReadFromRAM(Emulator.nearRegionDeformPointers[(int)Emulator.active.rom] - 4, &count, 4);

			nearAnimations = new .[count];

			Emulator.nearRegionDeformPointers[(int)Emulator.active.rom].Read(&sceneDeformArray);
			animationPointers = scope Emulator.Address[count];
			Emulator.active.ReadFromRAM(sceneDeformArray, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &nearAnimations[animationIndex];
				*animation = .(animationPointers[animationIndex]);

				let region = regions[animation.regionIndex];
				var triOrQuad = scope bool[region.metadata.nearFaceCount];

				for (let i < region.metadata.nearFaceCount) {
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
	}
}