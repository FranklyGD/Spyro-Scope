using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class Terrain {
		public TerrainCollision collision ~ delete _;
		public TerrainRegion[] visualMeshes;
		public RegionAnimation[] animations;
		public static List<int> usedTextureIndices = new .() ~ delete _;
		public static TextureQuad[] textureInfos;
		public static TextureScroller[] textureScrollers;
		public static TextureSwapper[] textureSwappers;

		public enum RenderMode {
			Collision,
			Near,
			Far
		}
		public RenderMode renderMode = .Collision;
		public bool wireframe;
		public int drawnRegion = -1;
		public bool decoded;

		public this() {
			Emulator.Address address = ?;
			Emulator.collisionDataPointers[(int)Emulator.rom].Read(&address);
			Emulator.Address deformAddress = ?;
			Emulator.collisionDeformDataPointers[(int)Emulator.rom].Read(&deformAddress);
			collision = new .(address, deformAddress);

			Reload();
			ReloadAnimations();
		}

		public ~this() {
			DeleteContainerAndItems!(visualMeshes);

			for (var item in animations) {
				item.Dispose();
			}
			delete animations;

			for (var item in textureScrollers) {
				item.Dispose();
			}
			delete textureScrollers;

			for (var item in textureSwappers) {
				item.Dispose();
			}
			delete textureSwappers;

			delete textureInfos;
		}

		public void Reload() {
			usedTextureIndices.Clear();

			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			let sceneDataRegionArrayPointer = Emulator.sceneRegionPointers[(int)Emulator.rom];
			sceneDataRegionArrayPointer.Read(&sceneDataRegionArrayAddress);
			uint32 sceneRegionCount = ?;
			Emulator.ReadFromRAM(sceneDataRegionArrayPointer + 4, &sceneRegionCount, 4);

			// Remove any existing parsed data
			DeleteContainerAndItems!(visualMeshes);

			// Parse all terrain regions
			visualMeshes = new .[sceneRegionCount];

			Emulator.Address[] sceneDataRegionAddresses = new .[sceneRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegionAddresses[0], sceneRegionCount);
			for (let regionIndex < sceneRegionCount) {
				let region = new TerrainRegion(sceneDataRegionAddresses[regionIndex]);
				region.GetUsedTextures();
				visualMeshes[regionIndex] = region;
			}
			delete sceneDataRegionAddresses;

			// Scrolling textures
			let textureScrollerPointer = Emulator.textureScrollerPointers[(int)Emulator.rom];
			uint32 textureScrollerCount = ?;
			Emulator.ReadFromRAM(textureScrollerPointer - 4, &textureScrollerCount, 4);
			textureScrollers = new .[textureScrollerCount];
			if (textureScrollerCount > 0) {
				Emulator.Address<Emulator.Address> textureScrollerArrayAddress = ?;
				textureScrollerPointer.Read(&textureScrollerArrayAddress);
	
				Emulator.Address[] textureScrollerAddresses = new .[textureScrollerCount];
				textureScrollerArrayAddress.ReadArray(&textureScrollerAddresses[0], textureScrollerCount);
				for (let i < textureScrollerCount) {
					textureScrollers[i] = .(textureScrollerAddresses[i], visualMeshes);
				}
				delete textureScrollerAddresses;
			}

			// Swapping textures
			let textureSwapperPointer = Emulator.textureSwapperPointers[(int)Emulator.rom];
			uint32 textureSwapperCount = ?;
			Emulator.ReadFromRAM(textureSwapperPointer - 4, &textureSwapperCount, 4);
			textureSwappers = new .[textureSwapperCount];
			if (textureSwapperCount > 0) {
				Emulator.Address<Emulator.Address> textureScrollerArrayAddress = ?;
				textureSwapperPointer.Read(&textureScrollerArrayAddress);

				Emulator.Address[] textureScrollerAddresses = new .[textureSwapperCount];
				textureScrollerArrayAddress.ReadArray(&textureScrollerAddresses[0], textureSwapperCount);
				for (let i < textureSwapperCount) {
					let swapper = TextureSwapper(textureScrollerAddresses[i], visualMeshes);
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

			let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;

			let totalQuadCount = (highestUsedIndex + 1) * quadCount;
			Emulator.Address<TextureQuad> textureDataAddress = ?;
			Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
			textureInfos = new .[totalQuadCount];
			textureDataAddress.ReadArray(&textureInfos[0], totalQuadCount);

			for (let regionIndex < sceneRegionCount) {
				visualMeshes[regionIndex].Reload();
			}
			
			for (let scrollerIndex < textureScrollerCount) {
				textureScrollers[scrollerIndex].Reload();
			}

			for (let swapperIndex < textureSwapperCount) {
				textureSwappers[swapperIndex].Reload();
			}

			

			// Delete animations as the new loaded mesh may be incompatible
			if (animations != null) {
				for (let item in animations) {
					item.Dispose();
				}
				DeleteAndNullify!(animations);
			}

			// Derived from Spyro: Ripto's Rage [80023994] TODO
			/*float clock = 0;

			Emulator.Address warpingRegionArrayPointer = ?;
			Emulator.warpingRegionPointers[(int)Emulator.rom].Read(&warpingRegionArrayPointer);
			uint32 waterRegionOffset = ?;
			Emulator.ReadFromRAM(warpingRegionArrayPointer, &waterRegionOffset, 4);
			warpingRegionArrayPointer += waterRegionOffset;
			uint32 waterRegionCount = ?;
			Emulator.ReadFromRAM(warpingRegionArrayPointer, &waterRegionCount, 4);
			uint32[] warpData = new .[waterRegionCount];
			Emulator.ReadFromRAM(warpingRegionArrayPointer + 4, warpData.CArray(), waterRegionCount * 4);
			for (let i < waterRegionCount) {
				let regionIndex = warpData[i] & 0xff;
				let begin = warpingRegionArrayPointer + (warpData[i] >> 0x10);
				let end = begin + (warpData[i] >> 6 & 0x3fc);
				let count = (int)(end - begin) / 4;

				uint32[] dataArray = scope .[count];
				Emulator.ReadFromRAM(begin, dataArray.CArray(), count);
				for (let ii < count) {
					let data = dataArray[ii];
					visualMeshes[regionIndex].vertices Math.Cos((float)(data + clock) / 128 * Math.PI_f * 2) * 20 + (data >> 0x10) |  & 0xfffffc00;
				}
			}
			delete warpData;*/
		}

		public void Decode() {
			let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;

			// Convert any used VRAM textures for previewing
			let quadDecodeCount = Emulator.installment == .SpyroTheDragon ? 5 : 6;
			for (let textureIndex in usedTextureIndices) {
				for (let i < quadDecodeCount) {
					Terrain.textureInfos[textureIndex * quadCount + i].Decode();
				}
			}

			for (let scrollerIndex < textureScrollers.Count) {
				textureScrollers[scrollerIndex].Decode();
			}

			decoded = true;
		}

		public void Update() {
			if (renderMode == .Collision) {
				collision.Update();
			} else {
				if (animations != null) {
					for (let animation in animations) {
						animation.Update();
					}
				}
			}

			UpdateTextureInfo(true);
			
			for (let terrainRegion in visualMeshes) {
				terrainRegion.nearMesh.Update();
				terrainRegion.nearMeshTransparent.Update();
			}
		}

		public void Draw() {
			Renderer.SetTint(.(255,255,255));
			Renderer.BeginSolid();

			if (wireframe) {
				Renderer.BeginWireframe();
			}

			switch (renderMode) {
				case .Far : {
					if (drawnRegion > -1) {
						visualMeshes[drawnRegion].DrawFar();
					} else {
						for (let visualMesh in visualMeshes) {
							visualMesh.DrawFar();
						}
					}
				}
				case .Near : {
					Renderer.BeginRetroShading();

					if (drawnRegion > -1) {
						visualMeshes[drawnRegion].DrawNear();
					} else {
						VRAM.decoded?.Bind();

						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNear();
						}
						
						GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
						GL.glDepthMask(GL.GL_FALSE);  

						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNearTransparent();
						}

						GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
						GL.glDepthMask(GL.GL_TRUE);  

						Renderer.whiteTexture.Bind();

					}

					Renderer.BeginDefaultShading();
				}
				case .Collision : {
					collision.Draw(wireframe);
				}
			}
				
			// Restore polygon mode to default
			Renderer.BeginSolid();
		}

		void ReloadAnimations() {
			uint32 count = ?;
			Emulator.ReadFromRAM(Emulator.sceneRegionDeformPointers[(int)Emulator.rom] - 4, &count, 4);

			delete animations;
			animations = new .[count];

			Emulator.Address sceneDeformArray = ?;
			Emulator.sceneRegionDeformPointers[(int)Emulator.rom].Read(&sceneDeformArray);
			let animationPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(sceneDeformArray, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &animations[animationIndex];

				*animation = .(animationPointers[animationIndex]);
				animation.Reload(visualMeshes);
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