using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class Terrain {
		public CollisionTerrain collision = .();
		public TerrainRegion[] visualMeshes;
		public RegionAnimation[] animations;
		public static TextureLOD[] texturesLODs;
		public Texture terrainTexture;

		public enum RenderMode {
			Collision,
			Near,
			Far
		}
		public RenderMode renderMode = .Collision;
		public bool wireframe;
		public int drawnRegion = -1;

		public ~this() {
			collision.Dispose();

			if (visualMeshes != null) {
				for (var item in visualMeshes) {
					item.Dispose();
				}
			}
			delete visualMeshes;

			if (animations != null) {
				for (var item in animations) {
					item.Dispose();
				}
			}
			delete animations;
			delete terrainTexture;
			delete texturesLODs;
		}

		public void Reload() {
			collision.Reload();

			delete terrainTexture;
			delete texturesLODs;
			uint32[] textureBuffer = new .[(1024 * 4) * 512](0,); // VRAM but four times wider

			// Get max amount of possible textures
			Emulator.Address<TextureLOD> textureDataAddress = ?;
			Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
			texturesLODs = new .[128];
			textureDataAddress.ReadArray(&texturesLODs[0], 128);

			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			var sceneDataRegionArrayPointer = Emulator.sceneDataRegionArrayPointers[(int)Emulator.rom];
			sceneDataRegionArrayPointer.Read(&sceneDataRegionArrayAddress);
			uint32 sceneDataRegionCount = ?;
			Emulator.ReadFromRAM(sceneDataRegionArrayPointer + 4, &sceneDataRegionCount, 4);

			// Remove any existing parsed data
			if (visualMeshes != null) {
				for (var item in visualMeshes) {
					item.Dispose();
				}
				DeleteAndNullify!(visualMeshes);
			}

			visualMeshes = new .[sceneDataRegionCount];

			// Parse all terrain regions
			let usedTextureIndices = new List<int>(); // Also get all used texture indices while we are at it
			Emulator.Address[] sceneDataRegions = new .[sceneDataRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegions[0], sceneDataRegionCount);
			for (let regionIndex < sceneDataRegionCount) {
				visualMeshes[regionIndex] = .(sceneDataRegions[regionIndex]);

				for (let textureIndex in visualMeshes[regionIndex].usedTextureIndices) {
					let usedIndex = usedTextureIndices.FindIndex(scope (x) => x == textureIndex);
					if (usedIndex == -1) {
						usedTextureIndices.Add(textureIndex);
					}
				}
			}
			delete sceneDataRegions;

			// Convert any used VRAM textures for previewing
			for (let usedTextureIndex in usedTextureIndices) {
				let textureLOD = &texturesLODs[usedTextureIndex];
				var quad = &textureLOD.nearQuad;
				
				for (let i < 6) {
					let mode = quad.texturePage & 0x80 > 0;
					let pixelWidth = mode ? 2 : 1;
					let pageCoords = quad.GetPageCoordinates();
					let vramPageCoords = (pageCoords.x * 64) + (pageCoords.y * 256 * 1024);
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
			delete usedTextureIndices;

			terrainTexture = new .(1024 * 4, 512, OpenGL.GL.GL_SRGB_ALPHA, OpenGL.GL.GL_RGBA, &textureBuffer[0]);
			terrainTexture.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

			Texture.Unbind();
			delete textureBuffer;

			// Delete animations as the new loaded mesh may be incompatible
			if (animations != null) {
				for (let item in animations) {
					item.Dispose();
				}
				DeleteAndNullify!(animations);
			}

			/*Emulator.Address waterRegionArrayPointer = ?;
			Emulator.waterRegionArrayPointers[(int)Emulator.rom].Read(&waterRegionArrayPointer);
			uint32 waterRegionOffset = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer, &waterRegionOffset, 4);
			uint32 waterRegionCount = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset, &waterRegionCount, 4);
			(uint8 regionIndex, uint8, uint8, uint8)[] waterData = new .[waterRegionCount];
			if (waterRegionCount > 0) {
				Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset + 4, &waterData[0], waterRegionCount * 4);
				// Must be for the wavy animation
			}
			delete waterData;*/
		}

		public void Update() {
			collision.Update();

			let terrainAnimationPointerArrayAddressOld = Emulator.terrainAnimationPointerArrayAddress;
			Emulator.sceneDataRegionAnimationArrayPointers[(int)Emulator.rom].Read(&Emulator.terrainAnimationPointerArrayAddress);
			if (Emulator.collisionModifyingPointerArrayAddress != 0 && terrainAnimationPointerArrayAddressOld != Emulator.terrainAnimationPointerArrayAddress) {
				ReloadAnimations();
			}

			if (animations != null) {
				for (let animation in animations) {
					animation.Update();
				}
			}
		}

		public void Draw() {
			Renderer.SetTint(.(255,255,255));
			Renderer.BeginSolid();

			switch (renderMode) {
				case .Far : {
					if (wireframe) {
						Renderer.BeginWireframe();
					}

					if (drawnRegion > -1) {
						visualMeshes[drawnRegion].DrawFar();
					} else {
						for (let visualMesh in visualMeshes) {
							visualMesh.DrawFar();
						}
					}
				}
				case .Near : {
					if (wireframe) {
						Renderer.BeginWireframe();
					}

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
			Emulator.ReadFromRAM(Emulator.sceneDataRegionAnimationArrayPointers[(int)Emulator.rom] - 4, &count, 4);
			if (count == 0) {
				return;
			}
			delete animations;
			animations = new .[count];

			let animationPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(Emulator.terrainAnimationPointerArrayAddress, &animationPointers[0], 4 * count);

			for (let animationIndex < count) {
				let animation = &animations[animationIndex];

				animation.dataPointer = animationPointers[animationIndex];

				if (!animation.dataPointer.IsNull) {
					animation.Reload(visualMeshes);
				}
			}
		}
	}
}
