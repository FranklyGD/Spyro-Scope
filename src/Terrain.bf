using System;
using System.Collections;
using System.Threading;

namespace SpyroScope {
	class Terrain {
		StaticMesh mesh;

		struct AnimationGroup {
			public uint32 dataPointer;
			public uint32 start;
			public uint32 count;
			public Vector center;
			public float radius;
			public StaticMesh[] mesh;

			public void Dispose() {
				DeleteContainerAndItems!(mesh);
			}
		}
		AnimationGroup[] animationGroups;

		public bool wireframe;
		public List<uint8> collisionTypes = new .() ~ delete _;

		public ~this() {
			for (let item in animationGroups) {
				item.Dispose();
			}
			delete animationGroups;
			delete mesh;
		}

		public void Reload() {
			let vertexCount = Emulator.collisionTriangles.Count * 3;
			Vector[] vertices = new .[vertexCount];
			Vector[] normals = new .[vertexCount];
			Renderer.Color4[] colors = new .[vertexCount];

			collisionTypes.Clear();
			for (int triangleIndex < Emulator.collisionTriangles.Count) {
				let triangle = Emulator.collisionTriangles[triangleIndex];
				let unpackedTriangle = triangle.Unpack(false);
				
				let normal = Vector.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				Renderer.Color color = .(255,255,255);

				if (triangleIndex < Emulator.specialTerrainBeginIndex) {
					let flagInfo = Emulator.collisionFlagsIndices[triangleIndex];
					
					// Terrain Collision Sound
					// Derived from Spyro: Ripto's Rage [80034f50]
					let collisionSound = flagInfo >> 6;

					let flagIndex = flagInfo & 0x3f;
					if (flagIndex != 0x3f) {
						Emulator.Address flagPointer = Emulator.collisionFlagPointerArray[flagIndex];
						uint8 flag = ?;
						Emulator.ReadFromRAM(flagPointer, &flag, 1);

						if (flag < 11 /*Emulator.collisionTypes.Count*/) {
							color = Emulator.collisionTypes[flag].color;
						} else {
							color = .(255, 0, 255);
						}

						if (!collisionTypes.Contains(flag)) {
							collisionTypes.Add(flag);
						} 
					}
				}

				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					vertices[i] = unpackedTriangle[vi];
					normals[i] = normal;
					colors[i] = color;
				}
			}

			delete mesh;
			mesh = new .(vertices, normals, colors);

			// Delete animations as the new loaded mesh may be incompatible
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
				delete animationGroups;
				animationGroups = null;
			}
		}

		public void ReloadAnimationGroups() {
			uint32 count = ?;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointer[(int)Emulator.rom] - 4, &count, 4);
			if (count == 0) {
				return;
			}
			animationGroups = new .[count];

			let collisionModifyingGroupPointers = scope uint32[count];
			Emulator.ReadFromRAM(Emulator.collisionModifyingPointerArrayAddress, &collisionModifyingGroupPointers[0], 4 * count);

			for (let groupIndex < count) {
				let animationGroup = &animationGroups[groupIndex];
				animationGroup.dataPointer = collisionModifyingGroupPointers[groupIndex];

				Emulator.ReadFromRAM(animationGroup.dataPointer + 4, &animationGroup.count, 2);
				Emulator.ReadFromRAM(animationGroup.dataPointer + 6, &animationGroup.start, 2);
				
				uint32 triangleDataOffset = ?;
				Emulator.ReadFromRAM(animationGroup.dataPointer + 8, &triangleDataOffset, 4);

				// Analyze the animation
				uint32 keyframeCount = triangleDataOffset >> 3 - 1; // / 8
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
							upperBound.x = Math.Max(upperBound.x, vertices[i].x);
							upperBound.x = Math.Max(upperBound.x, vertices[i].x);
							
							lowerBound.x = Math.Min(lowerBound.x, vertices[i].x);
							lowerBound.x = Math.Min(lowerBound.x, vertices[i].x);
							lowerBound.x = Math.Min(lowerBound.x, vertices[i].x);
						}
					}
					
					animationGroup.mesh[stateIndex] = new .(vertices, normals, colors);
					animationGroup.center = (upperBound + lowerBound) / 2;
					animationGroup.radius = (upperBound - lowerBound).Length();
				}
			}
		}

		public void Update() {
			let collisionModifyingPointerArrayAddressOld = Emulator.collisionModifyingPointerArrayAddress;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointer[(int)Emulator.rom], &Emulator.collisionModifyingPointerArrayAddress, 4);
			if (Emulator.collisionModifyingPointerArrayAddress != 0 && collisionModifyingPointerArrayAddressOld != Emulator.collisionModifyingPointerArrayAddress) {
				ReloadAnimationGroups();
			}

			if (animationGroups == null || animationGroups.Count == 0) {
				return; // Nothing to update
			}

			for (let groupIndex < animationGroups.Count) {
				let animationGroup = animationGroups[groupIndex];
				uint8 currentKeyframe = ?;
				Emulator.ReadFromRAM(animationGroup.dataPointer + 2, &currentKeyframe, 1);

				(uint8 flag, uint8, uint8 nextKeyframe, uint8, uint8 interpolation, uint8 fromState, uint8 toState, uint8) keyframeData = ?;
				Emulator.ReadFromRAM(animationGroup.dataPointer + 12 + ((uint32)currentKeyframe) * 8, &keyframeData, 8);
				
				let interpolation = (float)keyframeData.interpolation / (256);
				Renderer.Color transitionColor = keyframeData.fromState == keyframeData.toState ? .(255,128,0) : .((.)((1 - interpolation) * 255), (.)(interpolation * 255), 0);

				if (keyframeData.fromState >= animationGroup.mesh.Count || keyframeData.toState >= animationGroup.mesh.Count) {
					break; // Don't bother since it picked up garbage data
				}

				for (let i < animationGroups[groupIndex].count * 3) {
					Vector fromVertex = animationGroup.mesh[keyframeData.fromState].vertices[i];
					Vector toVertex = animationGroup.mesh[keyframeData.toState].vertices[i];
					Vector fromNormal = animationGroup.mesh[keyframeData.fromState].normals[i];
					Vector toNormal = animationGroup.mesh[keyframeData.toState].normals[i];

					let vertexIndex = animationGroup.start * 3 + i;
					mesh.vertices[vertexIndex] = fromVertex + (toVertex - fromVertex) * interpolation;
					mesh.normals[vertexIndex] = fromNormal + (toNormal - fromNormal) * interpolation;
					mesh.colors[vertexIndex] = transitionColor;
				}
			}

			mesh.Update();
		}

		public void Draw(Renderer renderer) {
			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.BeginSolid();

			if (!wireframe) {
				mesh.Draw(renderer);
				renderer.SetTint(.(128,128,128));
			}

			renderer.BeginWireframe();
			mesh.Draw(renderer);

			if (animationGroups != null) {
				renderer.SetTint(.(255,255,0));
				for	(let animationGroup in animationGroups) {
					for (let mesh in animationGroup.mesh) {
						mesh.Draw(renderer);
					}
				}
			}

			// Restore polygon mode to default
			renderer.BeginSolid();
		}
	}
}
