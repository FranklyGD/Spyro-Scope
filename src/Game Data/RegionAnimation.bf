using System;
using System.Collections;

namespace SpyroScope {
	struct RegionAnimation {
		public Emulator.Address address;
		public uint8 regionIndex;
		public uint16 count;
		public Vector center;
		public float radius;

		public Mesh[] meshStates;
		public List<int> animatedTriangles;

		public struct KeyframeData {
			public uint8 flag, a, nextKeyframe, b, interpolation, fromState, toState, c;
		}

		public uint8 CurrentKeyframe {
			get {
				uint8 currentKeyframe = ?;
				Emulator.ReadFromRAM(address + 2, &currentKeyframe, 1);
				return currentKeyframe;
			}
		}

		public this(Emulator.Address address) {
			this = ?;
			this.address = address;

			if (address.IsNull)
				return;

			Emulator.ReadFromRAM(address + 4, &regionIndex, 2);
		}

		public void Dispose() {
			DeleteContainerAndItems!(meshStates);
			delete animatedTriangles;
		}

		public void Reload(List<uint8> mesh2GameIndices, bool[] triOrQuad, List<int> faceIndices, Mesh mesh) mut {
			Emulator.ReadFromRAM(address + 6, &count, 2);

			uint32 vertexDataOffset = ?;
			Emulator.ReadFromRAM(address + 8, &vertexDataOffset, 4);

			// Analyze the animation
			uint32 keyframeCount = (vertexDataOffset >> 3) - 1; // triangleDataOffset / 8
			uint8 highestUsedState = 0;
			for (let keyframeIndex < keyframeCount) {
				(uint8 fromState, uint8 toState) s = ?;
				Emulator.ReadFromRAM(address + 12 + keyframeIndex * 8 + 5, &s, 2);

				highestUsedState = Math.Max(highestUsedState, s.fromState);
				highestUsedState = Math.Max(highestUsedState, s.toState);
			}

			Vector upperBound = .(float.NegativeInfinity,float.NegativeInfinity,float.NegativeInfinity);
			Vector lowerBound = .(float.PositiveInfinity,float.PositiveInfinity,float.PositiveInfinity);

			let stateCount = highestUsedState + 1;
			let vertexCount = count / 4;

			// Find triangles using these vertices
			List<uint32> gameVertexIndices = scope .();
			animatedTriangles = new .();
			for (var i = 0; i < mesh2GameIndices.Count; i += 3) {
				if (triOrQuad[faceIndices[i / 3]]) {
					if (mesh2GameIndices[i] < vertexCount ||
						mesh2GameIndices[i + 1] < vertexCount ||
						mesh2GameIndices[i + 2] < vertexCount) {
							
						// Include affected triangles and its vertices
						gameVertexIndices.Add(mesh2GameIndices[i]);
						gameVertexIndices.Add(mesh2GameIndices[i + 1]);
						gameVertexIndices.Add(mesh2GameIndices[i + 2]);
	
						animatedTriangles.Add(i);
					}
				} else {
					if (mesh2GameIndices[i] < vertexCount ||
						mesh2GameIndices[i + 1] < vertexCount ||
						mesh2GameIndices[i + 2] < vertexCount ||
						mesh2GameIndices[i + 3] < vertexCount ||
						mesh2GameIndices[i + 4] < vertexCount ||
						mesh2GameIndices[i + 5] < vertexCount) {

						gameVertexIndices.Add(mesh2GameIndices[i]);
						gameVertexIndices.Add(mesh2GameIndices[i + 1]);
						gameVertexIndices.Add(mesh2GameIndices[i + 2]);

						gameVertexIndices.Add(mesh2GameIndices[i + 3]);
						gameVertexIndices.Add(mesh2GameIndices[i + 4]);
						gameVertexIndices.Add(mesh2GameIndices[i + 5]);

						animatedTriangles.Add(i);
						animatedTriangles.Add(i + 3);
					}
					
					i += 3;
				}
			}

			let vertices = scope Vector[vertexCount];
			meshStates = new .[stateCount];
			for (let stateIndex < stateCount) {
				let startVertexState = stateIndex * vertexCount;

				let animatedVertices = scope uint32[vertexCount];
				Emulator.ReadFromRAM(address + vertexDataOffset + (startVertexState * 4), &animatedVertices[0], vertexCount * 4);

				for (let vertexIndex < vertexCount) {
					let unpackedVertex = TerrainRegion.UnpackVertex(animatedVertices[vertexIndex]);
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

				Vector[] v = new .[gameVertexIndices.Count];
				Vector[] n = new .[gameVertexIndices.Count];
				Renderer.Color4[] c = new .[gameVertexIndices.Count];

				for (let i < gameVertexIndices.Count) {
					let nearIndex = gameVertexIndices[i];
					if (nearIndex < vertexCount) {
						v[i] = vertices[nearIndex];
					} else {
						// Include the vertices of the affected triangles
						// even though they are not modified
						v[i] = mesh.vertices[animatedTriangles[i / 3] + (i % 3)];
					}
					c[i] = .(255,255,255);
					n[i] = .(0,0,1);
				}

				meshStates[stateIndex] = new .(v,n,c);
			}
		}

		public void Update(Mesh mesh) {
			let currentKeyframe = CurrentKeyframe;

			KeyframeData keyframeData = GetKeyframeData(currentKeyframe);

			let interpolation = (float)keyframeData.interpolation / 256;

			if (keyframeData.fromState >= meshStates.Count || keyframeData.toState >= meshStates.Count) {
				return; // Don't bother since it picked up garbage data
			}

			// Update all vertices that are meant to move between states
			for (let i < meshStates[0].vertices.Count) {
				Vector fromVertex = meshStates[keyframeData.fromState].vertices[i];
				Vector toVertex = meshStates[keyframeData.toState].vertices[i];
				
				mesh.vertices[animatedTriangles[i / 3] + (i % 3)] = fromVertex + (toVertex - fromVertex) * interpolation;
			}

			mesh.SetDirty();
		}

		public void UpdateSubdivided(TerrainRegion region) {
			for (var i < animatedTriangles.Count) {
				let triangleIndex = animatedTriangles[i];
				
				Vector* vertices = &region.nearMesh.vertices[triangleIndex];

				var regionFace = region.GetNearFace(region.nearFaceIndices[triangleIndex / 3]);
				if (regionFace.isTriangle) {
					Vector[5] midpoints = ?;
					midpoints[0] = (vertices[0] + vertices[1]) / 2; // Top
					midpoints[1] = (vertices[1] + vertices[2]) / 2; // Diagonal
					midpoints[2] = (vertices[2] + vertices[0]) / 2; // Left

					Vector[4][3] subQuadVertices = .(
						(midpoints[2], midpoints[0], vertices[0]),
						(midpoints[1], vertices[1], midpoints[0]),
						(vertices[2], midpoints[1], midpoints[2]),
						(midpoints[2], midpoints[1], midpoints[0])
					);

					if (regionFace.flipped) {
						Swap!(subQuadVertices[1], subQuadVertices[2]);
					}

					// Corner triangles
					vertices = &region.nearMeshSubdivided.vertices[triangleIndex * 4];
					for (let ti < 3) {
						let offset = ti * 3;

						vertices[0 + offset] = subQuadVertices[ti][2];
						vertices[1 + offset] = subQuadVertices[ti][1];
						vertices[2 + offset] = subQuadVertices[ti][0];
					}
					
					// Center triangle
					vertices[9] = subQuadVertices[3][2];
					vertices[10] = subQuadVertices[3][1];
					vertices[11] = subQuadVertices[3][0];
				} else {

					// High quality textures
					Vector[5] midpoints = ?;
					midpoints[0] = (vertices[3] + vertices[4]) / 2; // Top
					midpoints[1] = (vertices[0] + vertices[1]) / 2; // Bottom
					midpoints[2] = (vertices[3] + vertices[5]) / 2; // Left
					midpoints[3] = (vertices[0] + vertices[2]) / 2; // Right
					midpoints[4] = (midpoints[0] + midpoints[1]) / 2;

					Vector[4][4] subQuadVertices = .(
						.(midpoints[2], midpoints[4], midpoints[0], vertices[3]),
						.(midpoints[4], midpoints[3], vertices[2], midpoints[0]),
						.(vertices[5], midpoints[1], midpoints[4], midpoints[2]),
						.(midpoints[1], vertices[0], midpoints[3], midpoints[4]),
					);

					if (regionFace.flipped) {
						Swap!(subQuadVertices[1], subQuadVertices[2]);
					}

					vertices = &region.nearMeshSubdivided.vertices[triangleIndex * 4];
					for (let qi < 4) {
						let offset = qi * 6;

						vertices[0 + offset] = subQuadVertices[qi][3];
						vertices[1 + offset] = subQuadVertices[qi][2];
						vertices[2 + offset] = subQuadVertices[qi][0];

						vertices[3 + offset] = subQuadVertices[qi][0];
						vertices[4 + offset] = subQuadVertices[qi][2];
						vertices[5 + offset] = subQuadVertices[qi][1];
					}

					i++;
				}
			}

			region.nearMeshSubdivided.SetDirty();
		}

		public KeyframeData GetKeyframeData(uint8 keyframeIndex) {
			KeyframeData keyframeData = ?;
			Emulator.ReadFromRAM(address + 12 + ((uint32)keyframeIndex) * 8, &keyframeData, 8);
			return keyframeData;
		}
	}
}
