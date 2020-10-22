using System.Collections;

namespace SpyroScope {
	struct TerrainRegion {
		Emulator.Address address;
		public Mesh farMesh;
		public List<uint32> farMeshIndices = new .();
		public Mesh nearMesh;
		public List<uint32> nearMeshIndices = new .();
		public Vector offset;

		public bool isWater = false;

		// Region Metadata
		// Derived from Spyro: Ripto's Rage [80028b84]
		struct RegionMetadata {
			public uint16 centerY, centerX, a, centerZ;
			public uint16 offsetY, offsetX, b, offsetZ;
			public uint8 vertexCount, colorCount, faceCount, c;
			public uint8 vertexCount2, colorCount2, faceCount2;
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
		}

		public void Reload() mut {
			RegionMetadata metadata = ?;
			Emulator.ReadFromRAM(address, &metadata, sizeof(RegionMetadata));

			offset = .(metadata.offsetX, metadata.offsetY, metadata.offsetZ);

			let regionDataAddress = address + 0x1c;
			// Low Poly Count / Far Mesh
			farMesh = GenerateMesh(regionDataAddress, metadata.vertexCount, metadata.colorCount, metadata.faceCount, false);
			// High Poly Count / Near Mesh
			nearMesh = GenerateMesh(regionDataAddress + ((int)metadata.vertexCount + (int)metadata.colorCount + (int)metadata.faceCount * 2) * 4, metadata.vertexCount2, metadata.colorCount2, metadata.faceCount2, true);
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
				
				Vector[4] triangleVertices = ?;
				Renderer.Color[4] triangleColors = ?;
				float[4][2] triangleUV = ?;
	
				if (isNear) {
					uint32[] regionTriangles = scope .[faceSize * 4];
					Emulator.ReadFromRAM(regionPointer + (vertexSize + colorSize * 2) * 4, &regionTriangles[0], faceSize * 4 * 4);
	
					Renderer.Color4[] vertexColors = scope .[colorSize * 2];
					Emulator.ReadFromRAM(regionPointer + vertexSize * 4, &vertexColors[0], colorSize * 2 * 4);
	
					// Derived from Spyro: Ripto's Rage
					// Vertex Indexing [80024a00]
					// Color Indexing [80024c84]
					for (let i < faceSize) {
						uint32 packedTriangleIndex = regionTriangles[i * 4];
						uint32 packedColorIndex = regionTriangles[i * 4 + 1];
						uint32 packedTextureIndex = regionTriangles[i * 4 + 3];
	
						uint8[4] unpackedTrianglesIndex = *(uint8[4]*)&packedTriangleIndex;
						uint8[4] unpackedColorsIndex = *(uint8[4]*)&packedColorIndex;
						uint8[4] unpackedTextureIndex = *(uint8[4]*)&packedTextureIndex;
						uint8 textureIndex = unpackedTextureIndex[0];

						let nearQuad = Terrain.texturesLODs[textureIndex % 128].nearQuad;
						let partialUV = nearQuad.GetVramPartialUV();
						const let quadSize = TextureLOD.TextureQuad.quadSize;
						const let fullQuadSize = quadSize * 2;

						triangleUV[1] = .(partialUV.right, partialUV.rightY - quadSize);
						triangleUV[2] = .(partialUV.right, partialUV.rightY);
						triangleUV[3] = .(partialUV.left, partialUV.leftY + quadSize);

						bool triangle = unpackedTrianglesIndex[0] == unpackedTrianglesIndex[1];
						bool flipSide = unpackedTextureIndex[1] & 0b0100 > 0;
						bool doubleSide = unpackedTextureIndex[1] & 0b1000 > 0;
	
						if (triangle) {
							int first = 1;
							int second = 3;
	
							if (flipSide) {
								first = 3;
								second = 1;
							}

							triangleVertices[0] = sourceVertices[unpackedTrianglesIndex[first]];
							triangleVertices[1] = sourceVertices[unpackedTrianglesIndex[2]];
							triangleVertices[2] = sourceVertices[unpackedTrianglesIndex[second]];
							triangleColors[0] = vertexColors[unpackedColorsIndex[first]];
							triangleColors[1] = vertexColors[unpackedColorsIndex[2]];
							triangleColors[2] = vertexColors[unpackedColorsIndex[second]];
							
							nearMeshIndices.Add(unpackedTrianglesIndex[second]);
							nearMeshIndices.Add(unpackedTrianglesIndex[2]);
							nearMeshIndices.Add(unpackedTrianglesIndex[first]);

							vertexList.Add(triangleVertices[2]);
							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[0]);
							
							colorList.Add(triangleColors[2]);
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[0]);

							uvList.Add(triangleUV[first]);
							uvList.Add(triangleUV[2]);
							uvList.Add(triangleUV[second]);
						} else {
							triangleUV[0] = .(partialUV.left, partialUV.leftY);

							if (flipSide) {
								Swap!(unpackedTrianglesIndex[0], unpackedTrianglesIndex[3]);
								Swap!(unpackedTrianglesIndex[2], unpackedTrianglesIndex[1]);
							}
	
							triangleVertices[0] = sourceVertices[unpackedTrianglesIndex[1]];
							triangleVertices[1] = sourceVertices[unpackedTrianglesIndex[2]];
							triangleVertices[2] = sourceVertices[unpackedTrianglesIndex[3]];
							triangleVertices[3] = sourceVertices[unpackedTrianglesIndex[0]];
							
							triangleColors[0] = vertexColors[unpackedColorsIndex[1]];
							triangleColors[1] = vertexColors[unpackedColorsIndex[2]];
							triangleColors[2] = vertexColors[unpackedColorsIndex[3]];
							triangleColors[3] = vertexColors[unpackedColorsIndex[0]];
	
							if (flipSide) {
								Swap!(triangleColors[0], triangleColors[1]);
								Swap!(triangleColors[2], triangleColors[3]);
								Swap!(triangleUV[0], triangleUV[1]);
								Swap!(triangleUV[2], triangleUV[3]);
							}

							nearMeshIndices.Add(unpackedTrianglesIndex[2]);
							nearMeshIndices.Add(unpackedTrianglesIndex[1]);
							nearMeshIndices.Add(unpackedTrianglesIndex[0]);

							nearMeshIndices.Add(unpackedTrianglesIndex[2]);
							nearMeshIndices.Add(unpackedTrianglesIndex[0]);
							nearMeshIndices.Add(unpackedTrianglesIndex[3]);

							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[0]);
							vertexList.Add(triangleVertices[3]);
	
							vertexList.Add(triangleVertices[1]);
							vertexList.Add(triangleVertices[3]);
							vertexList.Add(triangleVertices[2]);
							
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[0]);
							colorList.Add(triangleColors[3]);
	
							colorList.Add(triangleColors[1]);
							colorList.Add(triangleColors[3]);
							colorList.Add(triangleColors[2]);

							uvList.Add(triangleUV[2]);
							uvList.Add(triangleUV[1]);
							uvList.Add(triangleUV[0]);

							uvList.Add(triangleUV[2]);
							uvList.Add(triangleUV[0]);
							uvList.Add(triangleUV[3]);
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
