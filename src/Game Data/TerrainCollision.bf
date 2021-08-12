using System;
using System.Collections;

namespace SpyroScope {
	class TerrainCollision {
		public readonly Emulator.Address address;
		public readonly Emulator.Address deformArrayAddress;

		uint32 deformArrayCount;

		// Collision Grid
		Vector3Int dimensions;
		public int16[,,] grid;
		public uint16[] cells ~ delete _;
		const int cellSize = 1 << 0xc;

		public bool visualizeGrid;

		public uint32 TriangleCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(address, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value;
				Emulator.active.WriteToRAM(address, &value, 4);
				triangles.Count = value;
			}
		}

		List<CollisionTriangle> triangles ~ delete _;

		public uint32 SpecialTriangleCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(address + 4, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value;
				Emulator.active.WriteToRAM(address + 4, &value, 4);
				flagIndices.Count = value;
			}
		}

		public List<uint8> flagIndices ~ delete _;
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
					Emulator.active.ReadFromRAM(dataPointer + 2, &currentKeyframe, 1);
					return currentKeyframe;
				}
			}

			public struct KeyframeData {
				public uint8 flag, a, nextKeyframe, b, interpolation, fromState, toState, c;
			}

			public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
				AnimationGroup.KeyframeData keyframeData = ?;
				Emulator.active.ReadFromRAM(dataPointer + 12 + ((uint32)keyframeIndex) * 8, &keyframeData, 8);
				return keyframeData;
			}
		}
		public AnimationGroup[] animationGroups;

		public this(Emulator.Address address, Emulator.Address deformAddress, uint32 deformGroupCount) {
			this.address = address;
			this.deformArrayCount = deformGroupCount;
			this.deformArrayAddress = deformAddress;
			
			Reload();
		}

		public ~this() {
			delete grid;

			DeleteDeformGroups();
			delete animationGroups;
			delete mesh;
			delete waterSurfaceTriangles;
			delete collisionTypes;
		}

		public void AddTriangle(Vector3Int[3] triangle) {
			let triangleIndex = TriangleCount;
			TriangleCount = triangleIndex + 1;
			SetTriangle(triangleIndex, triangle, true, false);
			GenerateMesh();
		}

		
		public Vector3Int[3] GetTriangle(int triangleIndex) {
			return triangles[triangleIndex].Unpack();
		}

		/// Sets the position of the mesh's triangle with the index the game uses
		public void SetTriangle(int triangleIndex, Vector3Int[3] triangle, bool updateGame = false, bool updateMesh = true) {
			triangles[triangleIndex] = CollisionTriangle.Pack(triangle);

			if (updateMesh) {
				let unpackedTriangle = triangles[triangleIndex].Unpack();
				let meshTriangle = (Vector3*)&mesh.vertices[triangleIndex * 3];
				meshTriangle[0] = unpackedTriangle[0];
				meshTriangle[1] = unpackedTriangle[1];
				meshTriangle[2] = unpackedTriangle[2];
	
				let meshNormal = (Vector3*)&mesh.normals[triangleIndex * 3];
				meshNormal[0] = meshNormal[1] = meshNormal[2] = Vector3.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				mesh.SetDirty(.Vertex | .Normal);
			}

			if (updateGame) {
				Emulator.Address collisionTriangleArray = ?;
				Emulator.active.ReadFromRAM(address + 20, &collisionTriangleArray, 4);
				Emulator.active.WriteToRAM(collisionTriangleArray + triangleIndex * sizeof(CollisionTriangle), &triangles[triangleIndex], sizeof(CollisionTriangle));
				
				GenerateGrid();
			}
		}

		public void Reload() {
			triangles = new .();
			Emulator.Address collisionTriangleArray = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 16 : 20), &collisionTriangleArray, 4);
			Emulator.active.ReadFromRAM(collisionTriangleArray, triangles.GrowUnitialized(TriangleCount), sizeof(CollisionTriangle) * triangles.Count);

			// Collision Grid
			// Derived from Spyro: Ripto's Rage [8003f440]
			Vector3Int dim;
			List<int16> buffer = scope .();
			var sizez = buffer.GrowUnitialized(1);
			
			Emulator.Address collisionGridZ = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 8 : 12), &collisionGridZ, 4);

			Emulator.active.ReadFromRAM(collisionGridZ, sizez, 2);
			dim.z = dimensions.z = *sizez;
			Emulator.active.ReadFromRAM(collisionGridZ + 2, buffer.GrowUnitialized(dim.z), 2 * dim.z);
			
			for (let z < dim.z) {
				if (buffer[1 + z] > -1) {
					let sizey = buffer.GrowUnitialized(1);
					Emulator.Address collisionGridY = collisionGridZ + buffer[1 + z];

					Emulator.active.ReadFromRAM(collisionGridY, sizey, 2);
					dim.y = *sizey;
					Emulator.active.ReadFromRAM(collisionGridY + 2, buffer.GrowUnitialized(dim.y), 2 * dim.y);
					
					if (dim.y > dimensions.y) {
						dimensions.y = dim.y;
					}
				}
			}

			for (let z < dim.z) {
				if (buffer[1 + z] > -1) {
					dim.y = buffer[buffer[1 + z] / 2];

					for (let y < dim.y) {
						if (buffer[buffer[1 + z] / 2 + 1 + y] > -1) {
							let sizex = buffer.GrowUnitialized(1);
							Emulator.Address collisionGridX = collisionGridZ + buffer[buffer[1 + z] / 2 + 1 + y];

							Emulator.active.ReadFromRAM(collisionGridX, sizex, 2);
							dim.x = *sizex;
							Emulator.active.ReadFromRAM(collisionGridX + 2, buffer.GrowUnitialized(dim.x), 2 * dim.x);

							if (dim.x > dimensions.x) {
								dimensions.x = dim.x;
							}
						}
					}
				}
			}

			dimensions.x++; dimensions.y++; dimensions.z++;

			grid = new .[dimensions.x, dimensions.y, dimensions.z];
			for (var cell in ref grid) {
				cell = -1;
			}
			int highestCellIndex = 0;

			sizez = buffer.Ptr;
			for (let z < *sizez) {
				if (sizez[1 + z] > -1) {
					let sizey = &buffer[sizez[1 + z] / 2];

					for (let y < *sizey) {
						if (sizey[1 + y] > -1) {
							let sizex = &buffer[sizey[1 + y] / 2];

							for (let x < *sizex) {
								let cellIndex = sizex[1 + x];
								if (cellIndex > -1) {
									grid[x,y,z] = cellIndex;
									if (cellIndex > highestCellIndex) {
										highestCellIndex = cellIndex;
									}
								}
							}
						}
					}
				}
			}

			Emulator.Address collisionCells = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 12 : 16), &collisionCells, 4);
			
			uint16 sample = ?;
			repeat {
				highestCellIndex++;
				Emulator.active.ReadFromRAM(collisionCells + highestCellIndex * 2, &sample, 2);
			} while (sample & 0x8000 == 0);
			highestCellIndex++;

			cells = new .[highestCellIndex];
			Emulator.active.ReadFromRAM(collisionCells, cells.CArray(), 2 * highestCellIndex);

			Emulator.Address collisionFlagArray = ?;

			flagIndices = new .();
			Emulator.active.ReadFromRAM(address + 24, &collisionFlagArray, 4);
			Emulator.active.ReadFromRAM(collisionFlagArray, flagIndices.GrowUnitialized(SpecialTriangleCount), sizeof(uint8) * flagIndices.Count);

			Emulator.active.ReadFromRAM(Emulator.active.collisionFlagsPointer, &collisionFlagArray, 4);
			Emulator.active.ReadFromRAM(collisionFlagArray, &collisionFlagPointerArray[0], 4 * 0x40);

			GenerateMesh();

			ReloadDeformGroups();
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
				for (let triangleIndex < animationGroup.count) {
					Vector3[3] triangle;
					for (let triangleVertexIndex < 3) {
						let vertexIndex = triangleIndex * 3 + triangleVertexIndex;

						Vector3 fromVertex = animationGroup.mesh[keyframeData.fromState].vertices[vertexIndex];
						Vector3 toVertex = animationGroup.mesh[keyframeData.toState].vertices[vertexIndex];

						triangle[triangleVertexIndex] = Math.Lerp(fromVertex, toVertex, interpolation);
					}
					let absoluteTriangleIndex = animationGroup.start + triangleIndex;

					SetTriangle(absoluteTriangleIndex, .((.)triangle[0], (.)triangle[1], (.)triangle[2]));
				}

				// While in this overlay, color the terrain mesh to show the interpolation amount between states
				if (overlay == .Deform) {
					Renderer.Color transitionColor = keyframeData.fromState == keyframeData.toState ? .(255,128,0) : .((.)((1 - interpolation) * 255), (.)(interpolation * 255), 0);
					for (let i < animationGroup.count * 3) {
						let vertexIndex = animationGroup.start * 3 + i;
						mesh.colors[vertexIndex] = transitionColor;
					}
					
					mesh.SetDirty(.Color);
				}
			}
			
			mesh.SetDirty(.Vertex);
			mesh.Update();
		}

		public void Draw() {
			if (mesh == null) {
				return;
			}

			Renderer.SetModel(.Zero, .Identity);
			mesh.Draw();
		}

		public void DrawDeformFrames() {
			if (mesh == null) {
				return;
			}

			if (overlay == .Deform) {
				Renderer.SetTint(.(255,255,0));
				for	(let animationGroup in animationGroups) {
					for (let mesh in animationGroup.mesh) {
						mesh.Draw();
					}
				}
			}
		}

		public void DrawGrid() {
			if (mesh == null) {
				return;
			}

			if (visualizeGrid) {
				for (let x < dimensions.x) {
					for (let y < dimensions.y) {
						for (let z < dimensions.z) {
							if (grid[x,y,z] != -1) {
								Vector3 cellStart = .(x << 0xc, y << 0xc, z << 0xc);

								Renderer.DrawLine(cellStart, cellStart + .(cellSize,0,0), .(255,0,0), .(255,0,0));
								Renderer.DrawLine(cellStart, cellStart + .(0,cellSize,0), .(0,255,0), .(0,255,0));
								Renderer.DrawLine(cellStart, cellStart + .(0,0,cellSize), .(0,0,255), .(0,0,255));

								for (let cellEntry in GetCell(x,y,z)) {
									let triangleIndex = cellEntry & 0x7fff;
									let triangle = Terrain.collision.mesh.vertices.CArray() + (int)triangleIndex * 3;

									let triangleCenter = (triangle[0] + triangle[1] + triangle[2]) / 3;

									Renderer.DrawLine(cellStart + .(1 << 0xb, 1 << 0xb, 1 << 0xb), triangleCenter, .(255,255,0), .(255,255,0));
								}
							}
						}
					}
				}
			}
		}

		public void ReloadDeformGroups() {
			DeleteDeformGroups();

			delete animationGroups;
			animationGroups = new .[deformArrayCount];

			let collisionModifyingGroupPointers = scope Emulator.Address[deformArrayCount];
			Emulator.active.ReadFromRAM(deformArrayAddress, collisionModifyingGroupPointers.CArray(), 4 * deformArrayCount);

			for (let groupIndex < deformArrayCount) {
				let animationGroup = &animationGroups[groupIndex];
				animationGroup.dataPointer = collisionModifyingGroupPointers[groupIndex];
				if (animationGroup.dataPointer.IsNull) {
					continue;
				}

				Emulator.active.ReadFromRAM(animationGroup.dataPointer + 4, &animationGroup.count, 2);
				Emulator.active.ReadFromRAM(animationGroup.dataPointer + 6, &animationGroup.start, 2);
				
				uint32 triangleDataOffset = ?;
				Emulator.active.ReadFromRAM(animationGroup.dataPointer + 8, &triangleDataOffset, 4);

				// Analyze the animation
				uint32 keyframeCount = (triangleDataOffset >> 3) - 1; // triangleDataOffset / 8
				uint8 highestUsedState = 0;
				for (let keyframeIndex < keyframeCount) {
					(uint8 fromState, uint8 toState) s = ?;
					Emulator.active.ReadFromRAM(animationGroup.dataPointer + 12 + keyframeIndex * 8 + 5, &s, 2);

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
						Emulator.active.ReadFromRAM(animationGroup.dataPointer + triangleDataOffset + (startTrianglesState + triangleIndex) * 12, &packedTriangle, 12);
						let unpackedTriangle = packedTriangle.UnpackAnimated();

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

		void ClearDeformGroups() {
			DeleteDeformGroups();
			animationGroups = new .[0];

			uint32 count = 0;
			Emulator.active.WriteToRAM(Emulator.active.collisionDataPointer, &count, 4);
		}

		void DeleteDeformGroups() {
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
				DeleteAndNullify!(animationGroups);
			}
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
			mesh.SetDirty(.Color);
		}

		void ClearColor() {
			for (let i < mesh.colors.Count) {
				mesh.colors[i] = .(255, 255, 255);
			}
		}

		/// Apply colors based on the flag applied on the triangles
		void ColorCollisionFlags() {
			for (int triangleIndex < SpecialTriangleCount) {
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
			for (int triangleIndex < SpecialTriangleCount) {
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
			Emulator.active.ReadFromRAM(flagPointer, &data, 8);
			return data;
		}

		void GenerateMesh() {
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
				let unpackedTriangle = triangle.Unpack();

				let normal = Vector3.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				Renderer.Color color = .(255,255,255);

				// Terrain as Water
				// Derived from Spyro: Ripto's Rage [8003e694]
				if (triangle.z & 0x4000 != 0) {
					waterSurfaceTriangles.Add(triangleIndex);
				}

				if (triangleIndex < SpecialTriangleCount) {
					let flagInfo = flagIndices[triangleIndex];

					let flagIndex = flagInfo & 0x3f;
					if (flagIndex != 0x3f) {
						let flagData = GetCollisionFlagData(flagIndex);

						if (overlay == .Flags) {
							if (flagData.type < 11 /*Emulator.collisionTypes.Count*/) {
								// Swap Ice with Supercharge if installment is "Spyro the Dragon" (Spyro 1)
								let flagType = Emulator.active.installment == .SpyroTheDragon && flagData.type == 4 ? 2 : flagData.type;
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

			ClearColor();
			ApplyColor();
		}

		public Span<uint16> GetCell(int x, int y, int z) {
			let cellStartIndex = (uint16)grid[x,y,z];

			if ((int16)cellStartIndex != -1) {
				var index = cellStartIndex;
				repeat {
					index++;
				} while (Terrain.collision.cells[index] & 0x8000 == 0);

				return .(Terrain.collision.cells, cellStartIndex, index - cellStartIndex);
			}

			return .();
		}

		public void ClearGrid() {
			dimensions = .(0,0,0);
			delete grid;
			grid = new .[0,0,0];

			delete cells;
			cells = new .[0];

			uint32 endCells = 0xffff;
			Emulator.Address collisionCells = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 12 : 16), &collisionCells, 4);
			Emulator.active.ReadFromRAM(collisionCells, &endCells, 2);

			Emulator.Address collisionGrid = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 8 : 12), &collisionGrid, 4);

			uint16 gridSize = 0;
			Emulator.active.WriteToRAM(collisionGrid, &gridSize, 2);
		}

		public void GenerateGrid() {
			Vector3Int maxPosition = ?;
			for (let i < triangles.Count) {
				let packedTriangle = triangles[i];
				let triangle = packedTriangle.Unpack();
				for (let vertex in triangle) {
					if (vertex.x > maxPosition.x) {
						maxPosition.x = vertex.x;
					}
					if (vertex.y > maxPosition.y) {
						maxPosition.y = vertex.y;
					}
					if (vertex.z > maxPosition.z) {
						maxPosition.z = vertex.z;
					}
				}
			}
			
			List<List<int>> gridSizes = scope .();
			dimensions = .((maxPosition.x / cellSize) + 1, (maxPosition.y / cellSize) + 1, (maxPosition.z / cellSize) + 1);
			List<uint16>[,,] cells = scope .[dimensions.x, dimensions.y, dimensions.z];
			int cellsMemoryAllocCount = 0;

			for (let i < triangles.Count) {
				let packedTriangle = triangles[i];
				let triangle = packedTriangle.Unpack();

				// Divide by the size of the cells in the grid
				Vector3[3] triCellPos;
				triCellPos[0] = (Vector3)triangle[0] / cellSize;
				triCellPos[1] = (Vector3)triangle[1] / cellSize;
				triCellPos[2] = (Vector3)triangle[2] / cellSize;

				// Find coordinates in grid per vertex
				for (let v < 3) {
					let vertex = triCellPos[v];
					// Create the cell if it doesn't exist

					// At vertex
					Vector3Int gridCoords;
					gridCoords.x = (.)vertex.x;
					gridCoords.y = (.)vertex.y;
					gridCoords.z = (.)vertex.z;
					
					// Add entry
					var cell = &cells[gridCoords.x, gridCoords.y, gridCoords.z];
					if (*cell == null) {
						*cell = scope:: .(8);

						// Modify grid array
						if (gridCoords.z + 1 > gridSizes.Count) {
						    gridSizes.Count = gridCoords.z + 1;
						}
						if (gridSizes[gridCoords.z] == null) {
						    gridSizes[gridCoords.z] = scope:: .();
						}
						if (gridCoords.y + 1 > gridSizes[gridCoords.z].Count) {
						    gridSizes[gridCoords.z].Count = gridCoords.y + 1;
						}
						if (gridCoords.x + 1 > gridSizes[gridCoords.z][gridCoords.y]) {
						    gridSizes[gridCoords.z][gridCoords.y] = gridCoords.x + 1;
						}
					}

					if (!(*cell).Contains((.)i)) {
						(*cell).Add((.)i);
						cellsMemoryAllocCount++;
					}

					// Along edge
					let v0 = vertex;
					let v1 = triCellPos[(v + 1) % 3];

					Vector3Int targetGridCoords;
					targetGridCoords.x = (.)v1.x;
					targetGridCoords.y = (.)v1.y;
					targetGridCoords.z = (.)v1.z;

					let travelIterations =
						Math.Abs(targetGridCoords.x - gridCoords.x) +
						Math.Abs(targetGridCoords.y - gridCoords.y) +
						Math.Abs(targetGridCoords.z - gridCoords.z) - 1;

					// Ray-trace across the grid
					if (travelIterations > 0) {
						let edge = v1 - v0;
						let edgeAbs = Vector3(Math.Abs(edge.x), Math.Abs(edge.y), Math.Abs(edge.z));
						let stepProg = Vector3(1f / edgeAbs.x, 1f / edgeAbs.y, 1f / edgeAbs.z);
	
						Vector3 edgeProg;
						edgeProg.x = edge.x == 0 ? float.PositiveInfinity : (edge.x > 0 ? 1 - (v0.x - (int)v0.x) : v0.x - (int)v0.x) / edgeAbs.x;
						edgeProg.y = edge.y == 0 ? float.PositiveInfinity : (edge.y > 0 ? 1 - (v0.y - (int)v0.y) : v0.y - (int)v0.y) / edgeAbs.y;
						edgeProg.z = edge.z == 0 ? float.PositiveInfinity : (edge.z > 0 ? 1 - (v0.z - (int)v0.z) : v0.z - (int)v0.z) / edgeAbs.z;
	
						let travel = Vector3Int((.)Math.Sign(edge.x), (.)Math.Sign(edge.y), (.)Math.Sign(edge.z));
	
						// Travel across the edge to reach the next nearest cell on the grid
						for (let iter < travelIterations) {
							if (edgeProg.x < edgeProg.y && edgeProg.x < edgeProg.z) {
								gridCoords.x += travel.x;
								edgeProg.x += stepProg.x;
							} else if (edgeProg.y < edgeProg.z) {
								gridCoords.y += travel.y;
								edgeProg.y += stepProg.y;
							} else {
								gridCoords.z += travel.z;
								edgeProg.z += stepProg.z;
							}
	
							// Add entry
							cell = &cells[gridCoords.x, gridCoords.y, gridCoords.z];
							if (*cell == null) {
								*cell = scope:: .();

								// Modify grid array
								if (gridCoords.z + 1 > gridSizes.Count) {
								    gridSizes.Count = gridCoords.z + 1;
								}
								if (gridSizes[gridCoords.z] == null) {
								    gridSizes[gridCoords.z] = scope:: .();
								}
								if (gridCoords.y + 1 > gridSizes[gridCoords.z].Count) {
								    gridSizes[gridCoords.z].Count = gridCoords.y + 1;
								}
								if (gridCoords.x + 1 > gridSizes[gridCoords.z][gridCoords.y]) {
								    gridSizes[gridCoords.z][gridCoords.y] = gridCoords.x + 1;
								}
							}

							if (!(*cell).Contains((.)i)) {
								(*cell).Add((.)i);
								cellsMemoryAllocCount++;
							}
						}
					}
				}
			}

			cellsMemoryAllocCount++; // Add space for terminator

			delete this.cells;
			this.cells = new .[cellsMemoryAllocCount];
			delete grid;
			grid = new .[dimensions.x, dimensions.y, dimensions.z];

			uint16 index = 0;
			for (let cellIndex < cells.Count) {
				let cell = cells[cellIndex];
				if (cell == null) {
					grid[cellIndex] = -1;
				} else {
					grid[cellIndex] = (.)index;
	
					for (let i < cell.Count) {
						this.cells[index + i] = cell[i];
					}
	
					this.cells[index] |= (.)0x8000; // Cell Terminator
					index += (.)cell.Count;
				}
			}
			this.cells[cellsMemoryAllocCount - 1] = (.)0x8000; // Terminator

			Emulator.Address collisionCells = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 12 : 16), &collisionCells, 4);
			Emulator.active.WriteToRAM(collisionCells, this.cells.CArray(), this.cells.Count * 2);
			
			// Write back into emulator the generated grid
			Emulator.Address collisionGrid = ?;
			Emulator.active.ReadFromRAM(address + (Emulator.active.installment == .SpyroTheDragon ? 8 : 12), &collisionGrid, 4);

			List<int16> buffer = scope .();

			int offset = gridSizes.Count + 1;

			buffer.Add((.)gridSizes.Count);
			for (let z < gridSizes.Count) {
				if (gridSizes[z] != null) {
					buffer.Add((.)offset * 2);

					offset += gridSizes[z].Count + 1;
				} else {
					buffer.Add(-1);
				}
			}

			for (let z < gridSizes.Count) {
				if (gridSizes[z] != null) {
					buffer.Add((.)gridSizes[z].Count);
					for (let y < gridSizes[z].Count) {
						if (gridSizes[z][y] > 0) {
							buffer.Add((.)offset * 2);

							offset += gridSizes[z][y] + 1;
						} else {
							buffer.Add(-1);
						}
					}
				}
			}

			for (let z < gridSizes.Count) {
				if (gridSizes[z] != null) {
					for (let y < gridSizes[z].Count) {
						if (gridSizes[z][y] > 0) {
							buffer.Add((.)gridSizes[z][y]);
							for (let x < gridSizes[z][y]) {
								buffer.Add(grid[x,y,z]);
							}
						}
					}
				}
			}

			// Commit changes
			Emulator.active.WriteToRAM(collisionGrid, buffer.Ptr, buffer.Count * 2);
		}

		public void Clear() {
			TriangleCount = 0;
			SpecialTriangleCount = 0;
			ClearDeformGroups();
			ClearGrid();
			GenerateMesh();
		}
	}
}
