using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class Terrain {
		public CollisionTerrain collision = .();
		public TerrainRegion[] visualMeshes;
		public RegionAnimation[] animations;
		public static TextureLOD[] texturesLODs;
		public Texture[] textures;

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
			DeleteContainerAndItems!(textures);
			delete texturesLODs;
		}

		public void Reload() {
			collision.Reload();

			DeleteContainerAndItems!(textures);
			textures = new .[1];
			textures[0] = new .(1024, 512, OpenGL.GL.GL_RGBA, OpenGL.GL.GL_UNSIGNED_SHORT_5_5_5_1, &Emulator.vramSnapshot[0]);
			textures[0].Bind();
			
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_SWIZZLE_A, GL.GL_ONE);

			Texture.Unbind();

			Emulator.Address<TextureLOD> textureDataAddress = ?;
			Emulator.Address<Emulator.Address> textureDataPointer = (.)0x800673f4;
			textureDataPointer.Read(&textureDataAddress);
			texturesLODs = new .[0x100];
			textureDataAddress.ReadArray(&texturesLODs[0], 0x100);

			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			var sceneDataRegionArrayPointer = Emulator.sceneDataRegionArrayPointers[(int)Emulator.rom];
			sceneDataRegionArrayPointer.Read(&sceneDataRegionArrayAddress);
			uint32 sceneDataRegionCount = ?;
			Emulator.ReadFromRAM(sceneDataRegionArrayPointer + 4, &sceneDataRegionCount, 4);

			if (visualMeshes != null) {
				for (var item in visualMeshes) {
					item.Dispose();
				}
				DeleteAndNullify!(visualMeshes);
			}
			visualMeshes = new .[sceneDataRegionCount];

			Emulator.Address[] sceneDataRegions = scope .[sceneDataRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegions[0], sceneDataRegionCount);
			for (let regionIndex < sceneDataRegionCount) {
				visualMeshes[regionIndex] = .(sceneDataRegions[regionIndex]);
			}

			Emulator.Address waterRegionArrayPointer = ?;
			Emulator.waterRegionArrayPointers[(int)Emulator.rom].Read(&waterRegionArrayPointer);
			uint32 waterRegionOffset = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer, &waterRegionOffset, 4);
			uint32 waterRegionCount = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset, &waterRegionCount, 4);
			(uint8 regionIndex, uint8, uint8, uint8)[] waterData = scope .[waterRegionCount];
			if (waterRegionCount > 0) {
				Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset + 4, &waterData[0], waterRegionCount * 4);
				for (let waterRegionData in waterData) {
					visualMeshes[waterRegionData.regionIndex].isWater = true;
				}
			}
		}

		public void Update() {
			collision.Update();
			if (animations != null) {
				for (let animation in animations) {
					animation.Update();
				}
			}

			let terrainAnimationPointerArrayAddressOld = Emulator.terrainAnimationPointerArrayAddress;
			Emulator.sceneDataRegionAnimationArrayPointers[(int)Emulator.rom].Read(&Emulator.terrainAnimationPointerArrayAddress);
			if (Emulator.collisionModifyingPointerArrayAddress != 0 && terrainAnimationPointerArrayAddressOld != Emulator.terrainAnimationPointerArrayAddress) {
				ReloadAnimations();
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
						Renderer.SetModel(visualMeshes[drawnRegion].offset * 16, .Scale(16));
						visualMeshes[drawnRegion].farMesh.Draw();
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

					if (drawnRegion > -1) {
						Renderer.SetModel(visualMeshes[drawnRegion].offset * 16, .Scale(16));
						visualMeshes[drawnRegion].nearMesh.Draw();
					} else {
						textures[0].Bind();
						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNear();
						}
						Renderer.whiteTexture.Bind();
					}
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
