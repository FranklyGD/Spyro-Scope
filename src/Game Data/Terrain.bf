using System;
using System.Collections;
using System.Threading;

namespace SpyroScope {
	class Terrain {
		public CollisionTerrain collision = .();
		public TerrainRegion[] visualMeshes;

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
		}

		public void Reload() {
			collision.Reload();

			Emulator.Address<Emulator.Address> sceneDataRegionArrayPointer = ?;
			Emulator.Address<Emulator.Address> sceneDataRegionArrayPointerAddress = (.)0x800673d4;
			sceneDataRegionArrayPointerAddress.Read(&sceneDataRegionArrayPointer);
			uint32 sceneDataRegionCount = ?;
			Emulator.Address<uint32> sceneDataRegionCountAddress = (.)0x800673d8;
			sceneDataRegionCountAddress.Read(&sceneDataRegionCount);

			if (visualMeshes != null) {
				for (var item in visualMeshes) {
					item.Dispose();
				}
				DeleteAndNullify!(visualMeshes);
			}
			visualMeshes = new .[sceneDataRegionCount];

			Emulator.Address[] sceneDataRegions = scope .[sceneDataRegionCount];
			sceneDataRegionArrayPointer.ReadArray(&sceneDataRegions[0], sceneDataRegionCount);

			for (let regionIndex < sceneDataRegionCount) {
				visualMeshes[regionIndex] = .(sceneDataRegions[regionIndex]);
			}
		}

		public void Update() {
			collision.Update();
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
						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNear();
						}
					}
				}
				case .Collision : {
					collision.Draw(wireframe);
				}
			}
				
			// Restore polygon mode to default
			Renderer.BeginSolid();
		}
	}
}
