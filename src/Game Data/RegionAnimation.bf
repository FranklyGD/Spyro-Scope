using System;
using System.Collections;

namespace SpyroScope {
	struct RegionAnimation {
		public Emulator.Address dataPointer;
		public uint8 regionIndex;
		public uint32 count;
		public Vector center;
		public float radius;
		public Mesh sourceMesh;
		public Mesh[] meshStates;
		public uint32 sourceStart;

		public struct KeyframeData {
			public uint8 flag, a, nextKeyframe, b, interpolation, fromState, toState, c;
		}

		public uint8 CurrentKeyframe {
			get {
				uint8 currentKeyframe = ?;
				Emulator.ReadFromRAM(dataPointer + 2, &currentKeyframe, 1);
				return currentKeyframe;
			}
		}

		public void Dispose() {
			DeleteContainerAndItems!(meshStates);
		}

		public void Reload(TerrainRegion[] terrainMeshes) mut {
			Emulator.ReadFromRAM(dataPointer + 4, &regionIndex, 2);
			Emulator.ReadFromRAM(dataPointer + 6, &count, 2);

			uint32 vertexDataOffset = ?;
			Emulator.ReadFromRAM(dataPointer + 8, &vertexDataOffset, 4);

			// Analyze the animation
			uint32 keyframeCount = vertexDataOffset >> 3 - 1; // triangleDataOffset / 8
			uint8 highestUsedState = 0;
			for (let keyframeIndex < keyframeCount) {
				(uint8 fromState, uint8 toState) s = ?;
				Emulator.ReadFromRAM(dataPointer + 12 + keyframeIndex * 8 + 5, &s, 2);

				highestUsedState = Math.Max(highestUsedState, s.fromState);
				highestUsedState = Math.Max(highestUsedState, s.toState);
			}

			Vector upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
			Vector lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

			let stateCount = highestUsedState + 1;
			let vertexCount = count / 4;

			sourceMesh = terrainMeshes[regionIndex].nearMesh;

			// Find triangles using these vertices
			sourceStart = uint32.MaxValue;
			let terrainRegionIndicies = terrainMeshes[regionIndex].nearMeshIndices;
			let indices = scope List<int>();
			for (var i = 0; i < terrainRegionIndicies.Count; i += 3) {
				if (terrainRegionIndicies[i] < vertexCount ||
					terrainRegionIndicies[i + 1] < vertexCount ||
					terrainRegionIndicies[i + 2] < vertexCount) {

					indices.Add(terrainRegionIndicies[i]);
					indices.Add(terrainRegionIndicies[i + 1]);
					indices.Add(terrainRegionIndicies[i + 2]);

					sourceStart = Math.Min(sourceStart, (.)i);
				}
			}

			let vertices = scope Vector[vertexCount];
			meshStates = new .[stateCount];
			for (let stateIndex < stateCount) {
				let startVertexState = stateIndex * vertexCount;

				for (let vertexIndex < vertexCount) {
					uint32 packedVertex = ?;
					Emulator.ReadFromRAM(dataPointer + vertexDataOffset + ((startVertexState + vertexIndex) * 4), &packedVertex, 4);
					let unpackedVertex = TerrainRegion.UnpackVertex(packedVertex);
					vertices[vertexIndex] = unpackedVertex;

					upperBound.x = Math.Max(upperBound.x, unpackedVertex.x);
					upperBound.y = Math.Max(upperBound.y, unpackedVertex.y);
					upperBound.z = Math.Max(upperBound.z, unpackedVertex.z);
					
					lowerBound.x = Math.Min(lowerBound.x, unpackedVertex.x);
					lowerBound.y = Math.Min(lowerBound.y, unpackedVertex.y);
					lowerBound.z = Math.Min(lowerBound.z, unpackedVertex.z);
				}
				
				center = (upperBound + lowerBound) / 2;
				radius = (upperBound - center).Length();

				Vector[] v = new .[indices.Count];
				Vector[] n = new .[indices.Count];
				Renderer.Color4[] c = new .[indices.Count];

				for (let i < indices.Count) {
					v[i] = vertices[indices[i]];
					c[i] = .(255,255,255);
				}

				for (var i = 0; i < indices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = .(0,0,1);
				}

				meshStates[stateIndex] = new .(v,n,c);
			}
		}

		public void Update() {
			let currentKeyframe = CurrentKeyframe;

			KeyframeData keyframeData = GetKeyframeData(currentKeyframe);

			let interpolation = (float)keyframeData.interpolation / (256);

			if (keyframeData.fromState >= meshStates.Count || keyframeData.toState >= meshStates.Count) {
				return; // Don't bother since it picked up garbage data
			}

			for (let i < meshStates[0].vertices.Count) {
				Vector fromVertex = meshStates[keyframeData.fromState].vertices[i];
				Vector toVertex = meshStates[keyframeData.toState].vertices[i];
				Vector fromNormal = meshStates[keyframeData.fromState].normals[i];
				Vector toNormal = meshStates[keyframeData.toState].normals[i];

				sourceMesh.vertices[sourceStart + i] = fromVertex + (toVertex - fromVertex) * interpolation;
				sourceMesh.normals[sourceStart + i] = fromNormal + (toNormal - fromNormal) * interpolation;
			}

			/*if (overlay == .Deform) {
				Renderer.Color transitionColor = keyframeData.fromState == keyframeData.toState ? .(255,128,0) : .((.)((1 - interpolation) * 255), (.)(interpolation * 255), 0);
				for (let i < animationGroup.count * 3) {
					let vertexIndex = animationGroup.start * 3 + i;
					collisionMesh.colors[vertexIndex] = transitionColor;
				}
			}*/

			sourceMesh.Update();
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(dataPointer + 12 + ((uint32)keyframeIndex) * 8, &keyframeData, 8);
			return keyframeData;
		}
	}
}
