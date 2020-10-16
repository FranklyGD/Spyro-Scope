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

		public void ReloadAnimationGroups() {
			uint32 count = ?;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointers[(int)Emulator.rom] - 4, &count, 4);
			if (count == 0) {
				return;
			}
			collision.animationGroups = new .[count];

			let collisionModifyingGroupPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(Emulator.collisionModifyingPointerArrayAddress, &collisionModifyingGroupPointers[0], 4 * count);

			for (let groupIndex < count) {
				let animationGroup = &collision.animationGroups[groupIndex];
				animationGroup.dataPointer = collisionModifyingGroupPointers[groupIndex];
				if (animationGroup.dataPointer.IsNull) {
					continue;
				}

				Emulator.ReadFromRAM(animationGroup.dataPointer + 4, &animationGroup.count, 2);
				Emulator.ReadFromRAM(animationGroup.dataPointer + 6, &animationGroup.start, 2);
				
				uint32 triangleDataOffset = ?;
				Emulator.ReadFromRAM(animationGroup.dataPointer + 8, &triangleDataOffset, 4);

				// Analyze the animation
				uint32 keyframeCount = triangleDataOffset >> 3 - 1; // triangleDataOffset / 8
				uint8 highestUsedState = 0;
				for (let keyframeIndex < keyframeCount) {
					(uint8 fromState, uint8 toState) s = ?;
					Emulator.ReadFromRAM(animationGroup.dataPointer + 12 + keyframeIndex * 8 + 5, &s, 2);

					highestUsedState = Math.Max(highestUsedState, s.fromState);
					highestUsedState = Math.Max(highestUsedState, s.toState);
				}

				Vector upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
				Vector lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

				let stateCount = highestUsedState + 1;
				let groupVertexCount = animationGroup.count * 3;
				animationGroup.mesh = new .[stateCount];
				for (let stateIndex < stateCount) {
					Vector[] vertices = new .[groupVertexCount];
					Vector[] normals = new .[groupVertexCount];
					Renderer.Color4[] colors = new .[groupVertexCount];

					let startTrianglesState = stateIndex * animationGroup.count;
					for (let triangleIndex < animationGroup.count) {
						PackedTriangle packedTriangle = ?;
						Emulator.ReadFromRAM(animationGroup.dataPointer + triangleDataOffset + (startTrianglesState + triangleIndex) * 12, &packedTriangle, 12);
						let unpackedTriangle = packedTriangle.Unpack(true);

						let normal = Vector.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
						Renderer.Color color = .(255,255,255);

						for (let vi < 3) {
							let i = triangleIndex * 3 + vi;
							vertices[i] = unpackedTriangle[vi];
							normals[i] = normal;
							colors[i] = color;

							upperBound.x = Math.Max(upperBound.x, vertices[i].x);
							upperBound.y = Math.Max(upperBound.y, vertices[i].y);
							upperBound.z = Math.Max(upperBound.z, vertices[i].z);
							
							lowerBound.x = Math.Min(lowerBound.x, vertices[i].x);
							lowerBound.y = Math.Min(lowerBound.y, vertices[i].y);
							lowerBound.z = Math.Min(lowerBound.z, vertices[i].z);
						}
					}
					
					animationGroup.mesh[stateIndex] = new .(vertices, normals, colors);
					animationGroup.center = (upperBound + lowerBound) / 2;
					animationGroup.radius = (upperBound - animationGroup.center).Length();
				}
			}

			collision.[Friend]ClearColor();
		}

		public void Update() {
			let collisionModifyingPointerArrayAddressOld = Emulator.collisionModifyingPointerArrayAddress;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointers[(int)Emulator.rom], &Emulator.collisionModifyingPointerArrayAddress, 4);
			if (Emulator.collisionModifyingPointerArrayAddress != 0 && collisionModifyingPointerArrayAddressOld != Emulator.collisionModifyingPointerArrayAddress) {
				ReloadAnimationGroups();
			}

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
