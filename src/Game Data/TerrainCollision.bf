using System;
using System.Collections;

namespace SpyroScope {
	class TerrainCollision {
		public readonly Emulator.Address address;
		public readonly Emulator.Address deformArrayAddress;

		public CollisionTriangle[] triangles ~ delete _;
		public uint32 specialTriangleCount;
		public uint8[] flagIndices ~ delete _;
		public Emulator.Address[] collisionFlagPointerArray = new .[0x40] ~ delete _;

		public Mesh mesh;

		public Vector3 upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
		public Vector3 lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

		public List<int> waterSurfaceTriangles = new .();
		public List<uint32> collisionTypes = new .();

		public enum Overlay {
			None,
			Flags,
			Deform,
			Water,
			Sound,
			Platform
		}
		public Overlay overlay = .None;

		public struct AnimationGroup {
			public Emulator.Address dataPointer;
			public uint32 start;
			public uint32 count;
			public Vector3 center;
			public float radius;
			public Mesh[] mesh;

			public void Dispose() {
				DeleteContainerAndItems!(mesh);
			}

			public uint8 CurrentKeyframe {
				get {
					uint8 currentKeyframe = ?;
					Emulator.ReadFromRAM(dataPointer + 2, &currentKeyframe, 1);
					return currentKeyframe;
				}
			}

			public struct KeyframeData {
				public uint8 flag, a, nextKeyframe, b, interpolation, fromState, toState, c;
			}

			public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
				AnimationGroup.KeyframeData keyframeData = ?;
				Emulator.ReadFromRAM(dataPointer + 12 + ((uint32)keyframeIndex) * 8, &keyframeData, 8);
				return keyframeData;
			}
		}
		public AnimationGroup[] animationGroups;

		public this(Emulator.Address address, Emulator.Address deformAddress) {
			this.address = address;
			this.deformArrayAddress = deformAddress;

			Reload();
		}

		public ~this() {
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
			}
			delete animationGroups;
			delete mesh;
			delete waterSurfaceTriangles;
			delete collisionTypes;
		}

		/// Sets the position of the mesh's triangle with the index the game uses
		public void SetNearVertex(int triangleIndex, Vector3Int[3] triangle, bool updateGame = false) {
			triangles[triangleIndex] = CollisionTriangle.Pack(triangle, false);

			let unpackedTriangle = triangles[triangleIndex].Unpack(false);
			let meshTriangle = (Vector3[3]*)&mesh.vertices[triangleIndex * 3];
			(*meshTriangle)[0] = unpackedTriangle[0];
			(*meshTriangle)[1] = unpackedTriangle[1];
			(*meshTriangle)[2] = unpackedTriangle[2];
			mesh.SetDirty();

			if (updateGame) {
				Emulator.Address collisionTriangleArray = ?;
				Emulator.ReadFromRAM(address + 20, &collisionTriangleArray, 4);
				Emulator.WriteToRAM(collisionTriangleArray + triangleIndex * sizeof(CollisionTriangle), &triangles[triangleIndex], sizeof(CollisionTriangle));
			}
		}

		public void Reload() {
			uint32 triangleCount = ?;
			Emulator.ReadFromRAM(address, &triangleCount, 4);
			Emulator.ReadFromRAM(address + 4, &specialTriangleCount, 4);

			triangles = new .[triangleCount];
			Emulator.Address collisionTriangleArray = ?;
			Emulator.ReadFromRAM(address + (Emulator.installment == .SpyroTheDragon ? 16 : 20), &collisionTriangleArray, 4);
			Emulator.ReadFromRAM(collisionTriangleArray, &triangles[0], sizeof(CollisionTriangle) * triangleCount);

			Emulator.Address collisionFlagArray = ?;

			flagIndices = new .[triangleCount];
			Emulator.ReadFromRAM(address + 24, &collisionFlagArray, 4);
			Emulator.ReadFromRAM(collisionFlagArray, &flagIndices[0], 1 * triangleCount);

			Emulator.ReadFromRAM(Emulator.collisionFlagsArrayPointers[(int)Emulator.rom], &collisionFlagArray, 4);
			Emulator.ReadFromRAM(collisionFlagArray, &collisionFlagPointerArray[0], 4 * 0x40);

			// Generate Mesh
			let vertexCount = triangles.Count * 3;
			Vector3[] vertices = new .[vertexCount];
			Vector3[] normals = new .[vertexCount];
			Renderer.Color4[] colors = new .[vertexCount];

			collisionTypes.Clear();
			waterSurfaceTriangles.Clear();

			upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
			lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

			for (let triangleIndex < triangles.Count) {
				let triangle = triangles[triangleIndex];
				let unpackedTriangle = triangle.Unpack(false);
			
				let normal = Vector3.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				Renderer.Color color = .(255,255,255);

				// Terrain as Water
				// Derived from Spyro: Ripto's Rage [8003e694]
				if (triangle.z & 0x4000 != 0) {
					waterSurfaceTriangles.Add(triangleIndex);
				}

				if (triangleIndex < specialTriangleCount) {
					let flagInfo = flagIndices[triangleIndex];

					let flagIndex = flagInfo & 0x3f;
					if (flagIndex != 0x3f) {
						let flagData = GetCollisionFlagData(flagIndex);

						if (overlay == .Flags) {
							if (flagData.type < 11 /*Emulator.collisionTypes.Count*/) {
								// Swap Ice with Supercharge if installment is "Spyro the Dragon" (Spyro 1)
								let flagType = Emulator.installment == .SpyroTheDragon && flagData.type == 4 ? 2 : flagData.type;
								color = Emulator.collisionTypes[flagType].color;
							} else {
								color = .(255, 0, 255);
							}
						}

						if (!collisionTypes.Contains(flagData.type)) {
							collisionTypes.Add(flagData.type);
						} 
					}
				}

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

			delete mesh;
			mesh = new .(vertices, normals, colors);

			ReloadDeformGroups();

			ClearColor();
			ApplyColor();
		}
		
		public void Update() {
			for (let groupIndex < animationGroups.Count) {
				let animationGroup = animationGroups[groupIndex];
				let currentKeyframe = animationGroup.CurrentKeyframe;

				AnimationGroup.KeyframeData keyframeData = animationGroup.GetKeyframeData(currentKeyframe);
				
				let interpolation = (float)keyframeData.interpolation / (256);

				if ((animationGroup.start + animationGroup.count) * 3 > mesh.vertices.Count ||
					keyframeData.fromState >= animationGroup.mesh.Count || keyframeData.toState >= animationGroup.mesh.Count) {
					break; // Don't bother since it picked up garbage data
				}

				// Update all triangles that are meant to move between states
				for (let i < animationGroup.count * 3) {
					Vector3 fromVertex = animationGroup.mesh[keyframeData.fromState].vertices[i];
					Vector3 toVertex = animationGroup.mesh[keyframeData.toState].vertices[i];
					Vector3 fromNormal = animationGroup.mesh[keyframeData.fromState].normals[i];
					Vector3 toNormal = animationGroup.mesh[keyframeData.toState].normals[i];

					let vertexIndex = animationGroup.start * 3 + i;
					mesh.vertices[vertexIndex] = fromVertex + (toVertex - fromVertex) * interpolation;
					mesh.normals[vertexIndex] = fromNormal + (toNormal - fromNormal) * interpolation;
				}

				// While in this overlay, color the terrain mesh to show the interpolation amount between states
				if (overlay == .Deform) {
					Renderer.Color transitionColor = keyframeData.fromState == keyframeData.toState ? .(255,128,0) : .((.)((1 - interpolation) * 255), (.)(interpolation * 255), 0);
					for (let i < animationGroup.count * 3) {
						let vertexIndex = animationGroup.start * 3 + i;
						mesh.colors[vertexIndex] = transitionColor;
					}
				}
			}
			
			mesh.SetDirty();
			mesh.Update();
		}

		public void Draw(bool wireframe) {
			if (mesh == null) {
				return;
			}

			Renderer.SetModel(.Zero, .Identity);

			if (!wireframe) {
				mesh.Draw();
				Renderer.SetTint(.(192,192,192));
			}

			Renderer.BeginWireframe();
			mesh.Draw();

			if (overlay == .Deform) {
				Renderer.SetTint(.(255,255,0));
				for	(let animationGroup in animationGroups) {
					for (let mesh in animationGroup.mesh) {
						mesh.Draw();
					}
				}
			}
		}

		public void ReloadDeformGroups() {
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
				DeleteAndNullify!(animationGroups);
			}

			uint32 count = ?;
			Emulator.ReadFromRAM(Emulator.collisionDeformDataPointers[(int)Emulator.rom] - 4, &count, 4);
			delete animationGroups;
			animationGroups = new .[count];

			let collisionModifyingGroupPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(deformArrayAddress, collisionModifyingGroupPointers.CArray(), 4 * count);

			for (let groupIndex < count) {
				let animationGroup = &animationGroups[groupIndex];
				animationGroup.dataPointer = collisionModifyingGroupPointers[groupIndex];
				if (animationGroup.dataPointer.IsNull) {
					continue;
				}

				Emulator.ReadFromRAM(animationGroup.dataPointer + 4, &animationGroup.count, 2);
				Emulator.ReadFromRAM(animationGroup.dataPointer + 6, &animationGroup.start, 2);
				
				uint32 triangleDataOffset = ?;
				Emulator.ReadFromRAM(animationGroup.dataPointer + 8, &triangleDataOffset, 4);

				// Analyze the animation
				uint32 keyframeCount = (triangleDataOffset >> 3) - 1; // triangleDataOffset / 8
				uint8 highestUsedState = 0;
				for (let keyframeIndex < keyframeCount) {
					(uint8 fromState, uint8 toState) s = ?;
					Emulator.ReadFromRAM(animationGroup.dataPointer + 12 + keyframeIndex * 8 + 5, &s, 2);

					highestUsedState = Math.Max(highestUsedState, s.fromState);
					highestUsedState = Math.Max(highestUsedState, s.toState);
				}

				Vector3 upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
				Vector3 lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

				let stateCount = highestUsedState + 1;
				let groupVertexCount = animationGroup.count * 3;
				animationGroup.mesh = new .[stateCount];
				for (let stateIndex < stateCount) {
					Vector3[] vertices = new .[groupVertexCount];
					Vector3[] normals = new .[groupVertexCount];
					Renderer.Color4[] colors = new .[groupVertexCount];

					let startTrianglesState = stateIndex * animationGroup.count;
					for (let triangleIndex < animationGroup.count) {
						CollisionTriangle packedTriangle = ?;
						Emulator.ReadFromRAM(animationGroup.dataPointer + triangleDataOffset + (startTrianglesState + triangleIndex) * 12, &packedTriangle, 12);
						let unpackedTriangle = packedTriangle.Unpack(true);

						let normal = Vector3.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
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

			ClearColor();
		}

		public void CycleOverlay() {
			switch (overlay) {
				case .None: overlay = .Flags;
				case .Flags: overlay = .Deform;
				case .Deform: overlay = .Water;
				case .Water: overlay = .Sound;
				case .Sound: overlay = .Platform;
				case .Platform: overlay = .None;
			}

			SetOverlay(overlay);
		}

		public void SetOverlay(Overlay overlay) {
			// Reset colors before highlighting
			ClearColor();

			this.overlay = overlay;

			ApplyColor();
		}

		void ApplyColor() {
			switch (overlay) {
				case .None:
				case .Flags: ColorCollisionFlags();
				case .Deform: // Colors applied on update 
				case .Water: ColorWater();
				case .Sound: ColorCollisionSounds();
				case .Platform: ColorPlatforms();
			}

			// Send changed color data
			mesh.SetDirty();
			mesh.Update();
		}

		void ClearColor() {
			for (let i < mesh.colors.Count) {
				mesh.colors[i] = .(255, 255, 255);
			}
		}

		/// Apply colors based on the flag applied on the triangles
		void ColorCollisionFlags() {
			for (int triangleIndex < specialTriangleCount) {
				Renderer.Color color = .(255,255,255);
				let flagInfo = flagIndices[triangleIndex];

				let flagIndex = flagInfo & 0x3f;
				if (flagIndex != 0x3f) {
					let flagData = GetCollisionFlagData(flagIndex);

					if (flagData.type < 11 /*Emulator.collisionTypes.Count*/) {
						color = Emulator.collisionTypes[flagData.type].color;
					} else {
						color = .(255, 0, 255);
					}
				}

				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					mesh.colors[i] = color;
				}
			}
		}

		/// Apply colors on triangles that are considered water surfaces
		void ColorWater() {
			for (let triangleIndex in waterSurfaceTriangles) {
				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					mesh.colors[i] = .(64, 128, 255);
				}
			}
		}

		void ColorCollisionSounds() {
			for (int triangleIndex < specialTriangleCount) {
				Renderer.Color color = .(255,255,255);
				let flagInfo = flagIndices[triangleIndex];

				// Terrain Collision Sound
				// Derived from Spyro: Ripto's Rage [80034f50]
				let collisionSound = flagInfo >> 6;

				switch (collisionSound) {
					case 1: color = .(255,128,128);
					case 2: color = .(128,255,128);
					case 3: color = .(128,128,255);
				}

				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					mesh.colors[i] = color;
				}
			}
		}

		void ColorPlatforms() {
			for (int triangleIndex < triangles.Count) {
				let normal = Vector3.Cross(
					mesh.vertices[triangleIndex * 3 + 2] - mesh.vertices[triangleIndex * 3 + 0],
					mesh.vertices[triangleIndex * 3 + 1] - mesh.vertices[triangleIndex * 3 + 0]
				);

				Vector3Int normalInt = (.)normal;
				// (GTE) Outer Product of 2 Vectors has its
				// Shift Fraction bit enabled so that it
				// shifts the final value by 12 bits to the right
				normalInt.x = normalInt.x >> 12;
				normalInt.y = normalInt.y >> 12;
				normalInt.z = normalInt.z >> 12;

				// Derived from Spyro: Ripto's Rage [8002cda0]
				var slopeDirection = normalInt;
				slopeDirection.z = 0;
				let slope = EMath.Atan2(normalInt.z, (.)EMath.VectorLength(slopeDirection));

				if (Math.Round(slope) < 0x17) { // Derived from Spyro: Ripto's Rage [80035e44]
					for (let vi < 3) {
						let i = triangleIndex * 3 + vi;
						mesh.colors[i] = .(128,255,128);
					}
				}
			}
		}

		public (uint32 type, uint32 param) GetCollisionFlagData(uint32 flagIndex) {
			Emulator.Address flagPointer = collisionFlagPointerArray[flagIndex];
			(uint32, uint32) data = ?;
			Emulator.ReadFromRAM(flagPointer, &data, 8);
			return data;
		}
	}
}
