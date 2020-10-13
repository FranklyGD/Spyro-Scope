using System;
using System.Collections;
using System.Threading;

namespace SpyroScope {
	class Terrain {
		Mesh collisionMesh;

		public struct TerrainRegion {
			public Mesh farMesh;
			public Vector offset;

			public void Dispose() {
				delete farMesh;
			}
		}
		TerrainRegion[] visualMeshes;

		public Vector upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
		public Vector lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

		public struct AnimationGroup {
			public Emulator.Address dataPointer;
			public uint32 start;
			public uint32 count;
			public Vector center;
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

		public bool wireframe;
		public List<int> waterSurfaceTriangles = new .() ~ delete _;
		public List<uint8> collisionTypes = new .() ~ delete _;

		public enum Overlay {
			None,
			Flags,
			Deform,
			Water,
			Sound,
			Platform
		}
		public Overlay overlay = .None;
		public int drawnRegion = -1;

		public ~this() {
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
			}
			delete animationGroups;
			delete collisionMesh;

			for (let item in visualMeshes) {
				item.Dispose();
			}
			delete visualMeshes;
		}

		public void Reload() {
			let vertexCount = Emulator.collisionTriangles.Count * 3;
			Vector[] vertices = new .[vertexCount];
			Vector[] normals = new .[vertexCount];
			Renderer.Color4[] colors = new .[vertexCount];

			collisionTypes.Clear();
			waterSurfaceTriangles.Clear();

			upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
			lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

			for (let triangleIndex < Emulator.collisionTriangles.Count) {
				let triangle = Emulator.collisionTriangles[triangleIndex];
				let unpackedTriangle = triangle.Unpack(false);
				
				let normal = Vector.Cross(unpackedTriangle[2] - unpackedTriangle[0], unpackedTriangle[1] - unpackedTriangle[0]);
				Renderer.Color color = .(255,255,255);

				// Terrain as Water
				// Derived from Spyro: Ripto's Rage [8003e694]
				if (triangle.data.z & 0x4000 != 0) {
					waterSurfaceTriangles.Add(triangleIndex);
				}

				if (triangleIndex < Emulator.specialTerrainTriangleCount) {
					let flagInfo = Emulator.collisionFlagsIndices[triangleIndex];

					let flagIndex = flagInfo & 0x3f;
					if (flagIndex != 0x3f) {
						Emulator.Address flagPointer = Emulator.collisionFlagPointerArray[flagIndex];
						uint8 flag = ?;
						Emulator.ReadFromRAM(flagPointer, &flag, 1);

						if (overlay == .Flags) {
							if (flag < 11 /*Emulator.collisionTypes.Count*/) {
								color = Emulator.collisionTypes[flag].color;
							} else {
								color = .(255, 0, 255);
							}
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

					upperBound.x = Math.Max(upperBound.x, vertices[i].x);
					upperBound.y = Math.Max(upperBound.y, vertices[i].y);
					upperBound.z = Math.Max(upperBound.z, vertices[i].z);

					lowerBound.x = Math.Min(lowerBound.x, vertices[i].x);
					lowerBound.y = Math.Min(lowerBound.y, vertices[i].y);
					lowerBound.z = Math.Min(lowerBound.z, vertices[i].z);
				}
			}

			delete collisionMesh;
			collisionMesh = new .(vertices, normals, colors);

			List<Vector> vertexList = scope .();
			List<Renderer.Color4> colorList = scope .();

			Emulator.Address<Emulator.Address> sceneDataRegionArrayPointer = ?;
			Emulator.Address<Emulator.Address> sceneDataRegionArrayPointerAddress = (.)0x800673d4;
			sceneDataRegionArrayPointerAddress.Read(&sceneDataRegionArrayPointer);
			uint32 sceneDataRegionCount = ?;
			Emulator.Address<uint32> sceneDataRegionCountAddress = (.)0x800673d8;
			sceneDataRegionCountAddress.Read(&sceneDataRegionCount);

			visualMeshes = new .[sceneDataRegionCount];
			Emulator.Address[] sceneDataRegions = scope .[sceneDataRegionCount];
			sceneDataRegionArrayPointer.ReadArray(&sceneDataRegions[0], sceneDataRegionCount);

			for (let regionIndex < sceneDataRegionCount) {
				let regionPointer = sceneDataRegions[regionIndex];
				(uint16 centerY, uint16 centerX, uint16 a, uint16 centerZ,
					uint16 offsetY, uint16 offsetX, uint16 b, uint16 offsetZ,
					uint8 vertexCount, uint8 colorCount, uint8 faceCount) regionMetadata = ?;
				Emulator.ReadFromRAM(regionPointer, &regionMetadata, 19);

				// Low Poly Count / Far Mesh
				if (regionMetadata.vertexCount > 0) {
					visualMeshes[regionIndex].offset = .(regionMetadata.offsetX, regionMetadata.offsetY, regionMetadata.offsetZ);
	
					uint32[] packedVertices = scope .[regionMetadata.vertexCount];
					Emulator.ReadFromRAM(regionPointer + 0x1c, &packedVertices[0], (uint16)regionMetadata.vertexCount * 4);
					
					Renderer.Color4[] vertexColors = scope .[regionMetadata.colorCount];
					Emulator.ReadFromRAM(regionPointer + 0x1c + (uint16)regionMetadata.vertexCount * 4, &vertexColors[0], (uint16)regionMetadata.colorCount * 4);

					uint32[4] triangleIndices = ?;
					Vector[4] triangleVertices = ?;
					Renderer.Color[4] triangleColors = ?;
	
					uint32[] regionTriangles = scope .[regionMetadata.faceCount * 2];
					// Derived from Spyro: Ripto's Rage
					// Vertex Indexing [80028e10]
					// Color Indexing [80028f28]
					Emulator.ReadFromRAM(regionPointer + 0x1c + (uint16)regionMetadata.vertexCount * 4 + (uint16)regionMetadata.colorCount * 4, &regionTriangles[0], (uint16)regionMetadata.faceCount * 2 * 4);
					for (let i < regionMetadata.faceCount) {
						uint32 packedTriangleIndex = regionTriangles[i * 2];
						uint32 packedTriangleColorIndex = regionTriangles[i * 2 + 1];
	
						triangleIndices[0] = packedTriangleIndex >> 10 & 0x7f; //((packedTriangleIndex >> 7) & 0x3f8) >> 3;
						triangleIndices[1] = packedTriangleIndex >> 17 & 0x7f; //((packedTriangleIndex >> 14) & 0x3f8) >> 3;
						triangleIndices[2] = packedTriangleIndex >> 24 & 0x7f; //((packedTriangleIndex >> 21) & 0x3f8) >> 3;
						triangleIndices[3] = packedTriangleIndex >> 3 & 0x7f; //(packedTriangleIndex & 0x3f8) >> 3;
	
						triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
						triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
						triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);

						triangleColors[0] = vertexColors[packedTriangleColorIndex >> 11 & 0x7f]; //((packedTriangleColorIndex >> 9) & 0x1fc) >> 2;
						triangleColors[1] = vertexColors[packedTriangleColorIndex >> 18 & 0x7f]; //((packedTriangleColorIndex >> 16) & 0x1fc) >> 2;
						triangleColors[2] = vertexColors[packedTriangleColorIndex >> 25 & 0x7f]; //((packedTriangleColorIndex >> 23) & 0x1fc) >> 2;
	
						if (triangleIndices[0] == triangleIndices[3]) {
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[1]);
							
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[1]);
						} else {
							triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3] % packedVertices.Count]);
							triangleColors[3] = vertexColors[packedTriangleColorIndex >> 4 & 0x7f]; //((packedTriangleColorIndex >> 2) & 0x1fc) >> 2;

							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[1]);
	
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[3]);
							
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[1]);

							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[3]);
						}
					}
				}
				
				Vector[] v = new .[vertexList.Count];
				Vector[] n = new .[vertexList.Count];
				Renderer.Color4[] c = new .[vertexList.Count];

				for (let i < vertexList.Count) {
					v[i] = vertexList[i];
					c[i] = colorList[i];
				}

				for (var i = 0; i < vertexList.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = .(0,0,1);
				}

				visualMeshes[regionIndex].farMesh = new .(v, n, c);

				vertexList.Clear();
				colorList.Clear();
			}

			// Delete animations as the new loaded mesh may be incompatible
			if (animationGroups != null) {
				for (let item in animationGroups) {
					item.Dispose();
				}
				DeleteAndNullify!(animationGroups);
			}

			ClearColor();
			ApplyColor();
		}

		// Derived from Spyro: Ripto's Rage [80028c2c]
		Vector UnpackVertex(uint32 packedVertex) {
			Vector vertex = ?;

			vertex.x = packedVertex >> 21;
			vertex.y = packedVertex >> 10 & 0x7ff;
			vertex.z = (packedVertex & 0x3ff) << 1;

			return vertex;
		}

		public void ReloadAnimationGroups() {
			uint32 count = ?;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointers[(int)Emulator.rom] - 4, &count, 4);
			if (count == 0) {
				return;
			}
			animationGroups = new .[count];

			let collisionModifyingGroupPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(Emulator.collisionModifyingPointerArrayAddress, &collisionModifyingGroupPointers[0], 4 * count);

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

		public void Update() {
			if (collisionMesh == null || collisionMesh.vertices.Count == 0) {
				return; // No mesh to update
			}

			let collisionModifyingPointerArrayAddressOld = Emulator.collisionModifyingPointerArrayAddress;
			Emulator.ReadFromRAM(Emulator.collisionModifyingDataPointers[(int)Emulator.rom], &Emulator.collisionModifyingPointerArrayAddress, 4);
			if (Emulator.collisionModifyingPointerArrayAddress != 0 && collisionModifyingPointerArrayAddressOld != Emulator.collisionModifyingPointerArrayAddress) {
				ReloadAnimationGroups();
			}

			if (animationGroups == null || animationGroups.Count == 0) {
				return; // Nothing to update
			}

			for (let groupIndex < animationGroups.Count) {
				let animationGroup = animationGroups[groupIndex];
				let currentKeyframe = animationGroup.CurrentKeyframe;

				AnimationGroup.KeyframeData keyframeData = animationGroup.GetKeyframeData(currentKeyframe);
				
				let interpolation = (float)keyframeData.interpolation / (256);

				if ((animationGroup.start + animationGroup.count) * 3 > collisionMesh.vertices.Count ||
					keyframeData.fromState >= animationGroup.mesh.Count || keyframeData.toState >= animationGroup.mesh.Count) {
					break; // Don't bother since it picked up garbage data
				}

				for (let i < animationGroup.count * 3) {
					Vector fromVertex = animationGroup.mesh[keyframeData.fromState].vertices[i];
					Vector toVertex = animationGroup.mesh[keyframeData.toState].vertices[i];
					Vector fromNormal = animationGroup.mesh[keyframeData.fromState].normals[i];
					Vector toNormal = animationGroup.mesh[keyframeData.toState].normals[i];

					let vertexIndex = animationGroup.start * 3 + i;
					collisionMesh.vertices[vertexIndex] = fromVertex + (toVertex - fromVertex) * interpolation;
					collisionMesh.normals[vertexIndex] = fromNormal + (toNormal - fromNormal) * interpolation;
				}

				if (overlay == .Deform) {
					Renderer.Color transitionColor = keyframeData.fromState == keyframeData.toState ? .(255,128,0) : .((.)((1 - interpolation) * 255), (.)(interpolation * 255), 0);
					for (let i < animationGroup.count * 3) {
						let vertexIndex = animationGroup.start * 3 + i;
						collisionMesh.colors[vertexIndex] = transitionColor;
					}
				}
			}

			collisionMesh.Update();
		}

		public void Draw() {
			Renderer.SetTint(.(255,255,255));
			Renderer.BeginSolid();

			if (drawnRegion > -1) {
				Renderer.SetModel(visualMeshes[drawnRegion].offset * 16, .Scale(16));
				visualMeshes[drawnRegion].farMesh.Draw();
			} else {
				for (let i < visualMeshes.Count) {
					Renderer.SetModel(visualMeshes[i].offset * 16, .Scale(16));
					visualMeshes[i].farMesh.Draw();
				}
			}

			if (collisionMesh == null) {
				return;
			}

			Renderer.SetModel(.Zero, .Identity);

			if (!wireframe) {
				collisionMesh.Draw();
				Renderer.SetTint(.(128,128,128));
			}

			Renderer.BeginWireframe();
			collisionMesh.Draw();

			if (overlay == .Deform && animationGroups != null) {
				Renderer.SetTint(.(255,255,0));
				for	(let animationGroup in animationGroups) {
					for (let mesh in animationGroup.mesh) {
						mesh.Draw();
					}
				}
			}

			// Restore polygon mode to default
			Renderer.BeginSolid();
		}

		public void CycleOverlay() {
			// Reset colors before highlighting
			ClearColor();

			switch (overlay) {
				case .None: overlay = .Flags;
				case .Flags: overlay = .Deform;
				case .Deform: overlay = .Water;
				case .Water: overlay = .Sound;
				case .Sound: overlay = .Platform;
				case .Platform: overlay = .None;
			}

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
			collisionMesh.Update();
		}

		void ClearColor() {
			for (let i < collisionMesh.colors.Count) {
				collisionMesh.colors[i] = .(255, 255, 255);
			}
		}

		/// Apply colors based on the flag applied on the triangles
		void ColorCollisionFlags() {
			for (int triangleIndex < Emulator.specialTerrainTriangleCount) {
				Renderer.Color color = .(255,255,255);
				let flagInfo = Emulator.collisionFlagsIndices[triangleIndex];

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
				}

				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					collisionMesh.colors[i] = color;
				}
			}
		}
		
		/// Apply colors on triangles that are considered water surfaces
		void ColorWater() {
			for (let triangleIndex in waterSurfaceTriangles) {
				for (let vi < 3) {
					let i = triangleIndex * 3 + vi;
					collisionMesh.colors[i] = .(64, 128, 255);
				}
			}
		}

		void ColorCollisionSounds() {
			for (int triangleIndex < Emulator.specialTerrainTriangleCount) {
				Renderer.Color color = .(255,255,255);
				let flagInfo = Emulator.collisionFlagsIndices[triangleIndex];

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
					collisionMesh.colors[i] = color;
				}
			}
		}

		void ColorPlatforms() {
			for (int triangleIndex < Emulator.collisionTriangles.Count) {
				let normal = Vector.Cross(
					collisionMesh.vertices[triangleIndex * 3 + 2] - collisionMesh.vertices[triangleIndex * 3 + 0],
					collisionMesh.vertices[triangleIndex * 3 + 1] - collisionMesh.vertices[triangleIndex * 3 + 0]
				);

				VectorInt normalInt = normal.ToVectorInt();
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
						collisionMesh.colors[i] = .(128,255,128);
					}
				}
			}
		}
	}
}
