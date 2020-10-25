using System.Collections;

namespace SpyroScope {
	struct TerrainRegion {
		Emulator.Address address;

		// Region Metadata
		// Derived from Spyro: Ripto's Rage [80028b84]
		public struct RegionMetadata {
			public uint16 centerY, centerX, a, centerZ;
			public uint16 offsetY, offsetX, b, offsetZ;
			public uint8 farVertexCount, farColorCount, farFaceCount, c;
			public uint8 nearVertexCount, nearColorCount, nearFaceCount;
		}
		public RegionMetadata metadata;

		public Mesh farMesh;
		public List<uint32> farMeshIndices = new .();
		public Mesh nearMesh;
		public List<uint32> nearMeshIndices = new .();
		public List<int> nearFaceIndices = new .();
		public Vector offset;

		public bool isWater = false;

		public List<int> usedTextureIndices = new .();

		public struct NearFace {
			public uint8[4] trianglesIndices, colorsIndices, a;

			public bool isTriangle { get => trianglesIndices[0] == trianglesIndices[1]; }

			public struct RenderInfo {
				uint8 texture, flipSideDepth, a, b;

				public uint8 textureIndex { get => texture % 128; }
				public uint8 depthOffset { get => flipSideDepth & 0b0011; }
				public bool flipped { get => flipSideDepth & 0b0100 > 0; }
				public bool doubleSided { get => flipSideDepth & 0b1000 > 0; }
				public uint8 rotation { get => (flipSideDepth & 0b00110000) >> 4; }
			}
			public RenderInfo renderInfo;
		}

		public this(Emulator.Address address) {
			this = ?;
			this.address = address;

			Reload();
		}

		public void Dispose() mut {
			address = 0;

			delete farMesh;
			delete nearMesh;
			delete farMeshIndices;
			delete nearMeshIndices;
			delete usedTextureIndices;
			delete nearFaceIndices;
		}

		public void Reload() mut {
			Emulator.ReadFromRAM(address, &metadata, sizeof(RegionMetadata));

			offset = .(metadata.offsetX, metadata.offsetY, metadata.offsetZ);

			// Low Poly Count / Far Mesh
			farMesh = GenerateMesh(address + 0x1c, metadata.farVertexCount, metadata.farColorCount, metadata.farFaceCount, false);
			// High Poly Count / Near Mesh
			nearMesh = GenerateMesh(address + 0x1c + ((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2) * 4, metadata.nearVertexCount, metadata.nearColorCount, metadata.nearFaceCount, true);
		}

		Mesh GenerateMesh(Emulator.Address regionPointer, int vertexSize, int colorSize, int faceSize, bool isNear) mut {
			List<Vector> vertexList = scope .();
			List<Renderer.Color> colorList = scope .();
			List<float[2]> uvList = scope .();
	
			if (vertexSize > 0) {
				uint32[] packedVertices = scope .[vertexSize];
				Emulator.ReadFromRAM(regionPointer, &packedVertices[0], vertexSize * 4);
				Vector[] sourceVertices = scope .[vertexSize];
				for (let i < vertexSize) {
					sourceVertices[i] = UnpackVertex(packedVertices[i]);
				}

				// Used for swapping around values
				Vector[4] triangleVertices = ?;
				Renderer.Color[4] triangleColors = ?;
				float[4][2] triangleUV = ?;
	
				if (isNear) {
					NearFace[] regionFaces = scope .[faceSize];
					Emulator.ReadFromRAM(regionPointer + (vertexSize + colorSize * 2) * 4, &regionFaces[0], faceSize * 4 * 4);
	
					Renderer.Color4[] vertexColors = scope .[colorSize * 2];
					Emulator.ReadFromRAM(regionPointer + vertexSize * 4, &vertexColors[0], colorSize * 2 * 4);
	
					// Derived from Spyro: Ripto's Rage
					// Vertex Indexing [80024a00]
					// Color Indexing [80024c84]
					for (let i < faceSize) {
						var regionFace = regionFaces[i];
						var trianglesIndices = regionFace.trianglesIndices;
						var colorIndices = regionFace.colorsIndices;
						let textureIndex = regionFace.renderInfo.textureIndex;
						let flipSide = regionFace.renderInfo.flipped;
						let textureRotation = regionFace.renderInfo.rotation;

						let usedIndex = usedTextureIndices.FindIndex(scope (x) => x == textureIndex);
						if (usedIndex == -1) {
							usedTextureIndices.Add(textureIndex);
						}

						let nearQuad = Terrain.texturesLODs[textureIndex].nearQuad;
						let partialUV = nearQuad.GetVramPartialUV();
						const let quadSize = TextureLOD.TextureQuad.quadSize;
						
						triangleUV[0] = .(partialUV.right, partialUV.rightY - quadSize);
						triangleUV[1] = .(partialUV.left, partialUV.leftY);
						triangleUV[2] = .(partialUV.left, partialUV.leftY + quadSize);
						triangleUV[3] = .(partialUV.right, partialUV.rightY);
	
						if (regionFace.isTriangle) {
							int first = 1;
							int second = 3;
	
							if (flipSide) {
								first = 3;
								second = 1;
							}

							triangleVertices[0] = sourceVertices[trianglesIndices[first]];
							triangleVertices[1] = sourceVertices[trianglesIndices[2]];
							triangleVertices[2] = sourceVertices[trianglesIndices[second]];
							triangleColors[0] = vertexColors[colorIndices[first]];
							triangleColors[1] = vertexColors[colorIndices[2]];
							triangleColors[2] = vertexColors[colorIndices[second]];
							
							nearMeshIndices.Add(trianglesIndices[second]);
							nearMeshIndices.Add(trianglesIndices[2]);
							nearMeshIndices.Add(trianglesIndices[first]);

							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[0]);
							
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[0]);

							float[3][2] rotatedTriangleUV = .(
								triangleUV[(0 - textureRotation + 4) % 4],
								triangleUV[(1 - textureRotation + 4) % 4],
								triangleUV[(2 - textureRotation + 4) % 4]
								);

							if (flipSide) {
								uvList.Add(rotatedTriangleUV[2]);
								uvList.Add(rotatedTriangleUV[0]);
								uvList.Add(rotatedTriangleUV[1]);
							} else {
								uvList.Add(rotatedTriangleUV[1]);
								uvList.Add(rotatedTriangleUV[0]);
								uvList.Add(rotatedTriangleUV[2]);
							}

							nearFaceIndices.Add(i);
						} else {
							if (flipSide) {
								Swap!(trianglesIndices[0], trianglesIndices[1]);
								Swap!(trianglesIndices[2], trianglesIndices[3]);
							}
	
							triangleVertices[0] = sourceVertices[trianglesIndices[1]];
							triangleVertices[1] = sourceVertices[trianglesIndices[2]];
							triangleVertices[2] = sourceVertices[trianglesIndices[3]];
							triangleVertices[3] = sourceVertices[trianglesIndices[0]];
							
							triangleColors[0] = vertexColors[colorIndices[1]];
							triangleColors[1] = vertexColors[colorIndices[2]];
							triangleColors[2] = vertexColors[colorIndices[3]];
							triangleColors[3] = vertexColors[colorIndices[0]];
	
							if (flipSide) {
								Swap!(triangleColors[0], triangleColors[3]);
								Swap!(triangleColors[2], triangleColors[1]);
								Swap!(triangleUV[0], triangleUV[1]);
								Swap!(triangleUV[2], triangleUV[3]);
							}

							nearMeshIndices.Add(trianglesIndices[2]);
							nearMeshIndices.Add(trianglesIndices[1]);
							nearMeshIndices.Add(trianglesIndices[3]);

							nearMeshIndices.Add(trianglesIndices[3]);
							nearMeshIndices.Add(trianglesIndices[1]);
							nearMeshIndices.Add(trianglesIndices[0]);
							
							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[2]);
							
							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[3]);
							
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[2]);
							
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[3]);
							
							uvList.Add(triangleUV[0]);
							uvList.Add(triangleUV[3]);
							uvList.Add(triangleUV[1]);
							
							uvList.Add(triangleUV[1]);
							uvList.Add(triangleUV[3]);
							uvList.Add(triangleUV[2]);

							nearFaceIndices.Add(i);
							nearFaceIndices.Add(i);
						}
					}
				} else {
					uint32[4] triangleIndices = ?;
	
					uint32[] regionTriangles = scope .[faceSize * 2];
					Emulator.ReadFromRAM(regionPointer + (vertexSize + colorSize) * 4, &regionTriangles[0], faceSize * 2 * 4);
	
					Renderer.Color4[] vertexColors = scope .[colorSize];
					Emulator.ReadFromRAM(regionPointer + vertexSize * 4, &vertexColors[0], colorSize * 4);
	
					// Derived from Spyro: Ripto's Rage
					// Vertex Indexing [80028e10]
					// Color Indexing [80028f28]
					for (let i < faceSize) {
						uint32 packedTriangleIndex = regionTriangles[i * 2];
						uint32 packedColorIndex = regionTriangles[i * 2 + 1];
	
						triangleIndices[0] = packedTriangleIndex >> 10 & 0x7f; //((packedTriangleIndex >> 7) & 0x3f8) >> 3;
						triangleIndices[1] = packedTriangleIndex >> 17 & 0x7f; //((packedTriangleIndex >> 14) & 0x3f8) >> 3;
						triangleIndices[2] = packedTriangleIndex >> 24 & 0x7f; //((packedTriangleIndex >> 21) & 0x3f8) >> 3;
						triangleIndices[3] = packedTriangleIndex >> 3 & 0x7f; //(packedTriangleIndex & 0x3f8) >> 3;
	
						triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
						triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
						triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);
	
						triangleColors[0] = vertexColors[packedColorIndex >> 11 & 0x7f]; //((packedTriangleColorIndex >> 9) & 0x1fc) >> 2;
						triangleColors[1] = vertexColors[packedColorIndex >> 18 & 0x7f]; //((packedTriangleColorIndex >> 16) & 0x1fc) >> 2;
						triangleColors[2] = vertexColors[packedColorIndex >> 25 & 0x7f]; //((packedTriangleColorIndex >> 23) & 0x1fc) >> 2;
	
						if (triangleIndices[0] == triangleIndices[3]) {
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[1]);
							
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[1]);

							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
						} else {
							triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3] % packedVertices.Count]);
							triangleColors[3] = vertexColors[packedColorIndex >> 4 & 0x7f]; //((packedTriangleColorIndex >> 2) & 0x1fc) >> 2;
	
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
							
							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
							
							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
							uvList.Add(.(0,0));
						}
					}
				}
			}
	
			Vector[] v = new .[vertexList.Count];
			Vector[] n = new .[vertexList.Count];
			Renderer.Color4[] c = new .[vertexList.Count];
			float[][2] u = new .[vertexList.Count];
	
			for (let i < vertexList.Count) {
				v[i] = vertexList[i];
				u[i] = uvList[i];
				c[i] = colorList[i];
			}
	
			for (var i = 0; i < vertexList.Count; i += 3) {
				n[i] = n[i+1] = n[i+2] = .(0,0,1);
			}
	
			return new .(v, u, n, c);
		}
	
		// Derived from Spyro: Ripto's Rage
		// Far [80028c2c]
		// Near [80024664]
		public static Vector UnpackVertex(uint32 packedVertex) {
			Vector vertex = ?;
	
			vertex.x = packedVertex >> 21;
			vertex.y = packedVertex >> 10 & 0x7ff;
			vertex.z = (packedVertex & 0x3ff) << 1;
	
			return vertex;
		}

		public NearFace GetNearFace(int index) {
			NearFace face = ?;
			Emulator.ReadFromRAM(address + 0x1c +
				((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2) * 4 + // Pass over all far data
				((int)metadata.nearVertexCount + (int)metadata.nearColorCount * 2) * 4 + // Pass over previous near data
				(index * 4) * 4,// Index the face
				&face, sizeof(NearFace));
			return face;
		}
		
		public void DrawFar() {
			Renderer.SetModel(offset * 16, .Scale(16));
			farMesh.Draw();
		}

		public void DrawNear() {
			Renderer.SetModel(offset * 16, .Scale(16,16, isWater ? 2 : 16));
			nearMesh.Draw();
		}
	}
}
