using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class Terrain {
		public TerrainCollision collision ~ delete _;
		public TerrainRegion[] visualMeshes;
		public RegionAnimation[] animations;
		public static int highestUsedTextureIndex = -1;
		public static TextureLOD[] texturesLODs;
		public static TextureLOD1[] texturesLODs1;
		public static Texture terrainTexture;
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

			delete terrainTexture;
			delete texturesLODs;
			delete texturesLODs1;
		}

		public void Reload() {
			delete textureScrollers;
			delete textureSwappers;

			uint32[] textureBuffer = new .[(1024 * 4) * 512](0,); // VRAM but four times wider

			// Get max amount of possible textures
			if (Emulator.installment == .SpyroTheDragon) {
				//delete texturesLODs1;
				Emulator.Address<TextureLOD1> textureDataAddress = ?;
				Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
				texturesLODs1 = new .[128];
				textureDataAddress.ReadArray(&texturesLODs1[0], 128);
			} else {
				//delete texturesLODs;
				Emulator.Address<TextureLOD> textureDataAddress = ?;
				Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
				texturesLODs = new .[128];
				textureDataAddress.ReadArray(&texturesLODs[0], 128);
			}

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
				visualMeshes[regionIndex] = region;

				if (region.highestUsedTextureIndex > highestUsedTextureIndex) { 
					highestUsedTextureIndex = region.highestUsedTextureIndex;
				}
			}
			delete sceneDataRegionAddresses;

			// Convert any used VRAM textures for previewing
			for (let textureIndex < highestUsedTextureIndex + 1) {
				TextureQuad* quad = ?;
				int quadCount = ?;
				if (Emulator.installment == .SpyroTheDragon) {
					quad = &Terrain.texturesLODs1[textureIndex].D1;
					quadCount = 5;//21;
				} else {
					quad = &Terrain.texturesLODs[textureIndex].farQuad;
					quadCount = 6;
				}
				
				for (let i < quadCount) {
					let mode = quad.texturePage & 0x80 > 0;
					let pixelWidth = mode ? 2 : 1;
					let tpageCell = quad.GetTPageCell();
					let vramPageCoords = (tpageCell.x * 64) + ((tpageCell.y * 256) * 1024);
					let vramCoords = vramPageCoords * 4 + ((int)quad.left * pixelWidth + (int)quad.leftSkew * 1024 * 4);

					let quadTexture = quad.GetTextureData();
					let width = mode ? 64 : 32;
					for (let x < width) {
						for (let y < 32) {
							textureBuffer[(vramCoords + x + y * 1024 * 4)] = quadTexture[x / pixelWidth + y * 32];
						}
					}
					delete quadTexture;
					quad++;
				}
			}

			terrainTexture = new .(1024 * 4, 512, OpenGL.GL.GL_SRGB_ALPHA, OpenGL.GL.GL_RGBA, &textureBuffer[0]);
			terrainTexture.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

			Texture.Unbind();
			delete textureBuffer;

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

			// Scrolling textures
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
					textureSwappers[i] = .(textureScrollerAddresses[i], visualMeshes);
				}
				delete textureScrollerAddresses;
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
						terrainTexture.Bind();

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