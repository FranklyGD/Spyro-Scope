using System.Collections;

namespace SpyroScope {
	class TerrainRegion {
		Emulator.Address address;

		// Region Metadata
		// Derived from Spyro: Ripto's Rage [80028b84]
		public struct RegionMetadata {
			public uint16 centerY, centerX, a, centerZ;
			public uint16 offsetY, offsetX, b, offsetZ;
			public uint8 farVertexCount, farColorCount, farFaceCount, c;
			public uint8 nearVertexCount, nearColorCount, nearFaceCount, warpStart;

			public bool verticallyScaledDown { get => a & 0b1000000000000 > 0; }
		}
		public RegionMetadata metadata;

		/// Vertical scale of the near part of the mesh
		public int verticalScale { get {
			if (Emulator.active.installment == .SpyroTheDragon) {
				return 8;
			} else {
				return metadata.verticallyScaledDown ? 2 : 16;
			}
		} }

		public FarFace[] farFaces ~ delete _;

		public Mesh farMesh ~ delete _;
		public List<uint8> farMesh2GameIndices = new .() ~ delete _;
		/// Used to convert mesh triangle index to face index
		public List<int> farFaceIndices = new .() ~ delete _;

		Vector3[] nearVertices;
		Renderer.Color4[] nearColors ~ delete _;
		NearFace[] nearFaces ~ delete _;
		
		public Mesh nearMesh ~ delete _;
		public Mesh nearMeshSubdivided ~ delete _;
		public List<uint8> nearMesh2GameIndices = new .() ~ delete _;
		/// Used to convert mesh triangle index to face index
		public List<int> nearFaceIndices = new .() ~ delete _;

		public Mesh nearMeshTransparent ~ delete _;
		public Mesh nearMeshTransparentSubdivided ~ delete _;
		public List<uint8> nearMesh2GameTransparentIndices = new .() ~ delete _;
		/// Used to convert mesh triangle index to face index (transparent)
		public List<int> nearFaceTransparentIndices = new .() ~ delete _;

		public int highestUsedTextureIndex = -1;

		public struct FarFace {
			public uint32 packedVertexIndices, packedColorIndices;

			public uint8[4] UnpackVertexIndices() {
				uint8[4] indices;
				if (Emulator.active.installment == .SpyroTheDragon) {
					indices[0] = (.)(packedVertexIndices >> 14 & 0x3f); //((packedVertexIndices >> 11) & 0x1f8) >> 3;
					indices[1] = (.)(packedVertexIndices >> 20 & 0x3f); //((packedVertexIndices >> 17) & 0x1f8) >> 3;
					indices[2] = (.)(packedVertexIndices >> 26 & 0x3f); //((packedVertexIndices >> 23) & 0x1f8) >> 3;
					indices[3] = (.)(packedVertexIndices >> 8 & 0x3f); //((packedVertexIndices >> 5) & 0x1f8) >> 3;
				} else {
					indices[0] = (.)(packedVertexIndices >> 10 & 0x7f); //((packedVertexIndices >> 7) & 0x3fc) >> 2;
					indices[1] = (.)(packedVertexIndices >> 17 & 0x7f); //((packedVertexIndices >> 14) & 0x3fc) >> 2;
					indices[2] = (.)(packedVertexIndices >> 24 & 0x7f); //((packedVertexIndices >> 21) & 0x3fc) >> 2;
					indices[3] = (.)(packedVertexIndices >> 3 & 0x7f); //(packedVertexIndices & 0x3fc) >> 2;
				}
				return indices;
			}

			public uint8[4] UnpackColorIndices() {
				uint8[4] indices;
				if (Emulator.active.installment == .SpyroTheDragon) {
					indices[0] = (.)(packedColorIndices >> 14 & 0x3f); //((packedColorIndices >> 12) & 0xfc) >> 2;
					indices[1] = (.)(packedColorIndices >> 20 & 0x3f); //((packedColorIndices >> 18) & 0xfc) >> 2;
					indices[2] = (.)(packedColorIndices >> 26 & 0x3f); //((packedColorIndices >> 24) & 0xfc) >> 2;
					indices[3] = (.)(packedColorIndices >> 8 & 0x3f); //((packedColorIndices >> 6) & 0xfc) >> 2;
				} else {
					indices[0] = (.)(packedColorIndices >> 11 & 0x7f); //((packedColorIndices >> 9) & 0x1fc) >> 2;
					indices[1] = (.)(packedColorIndices >> 18 & 0x7f); //((packedColorIndices >> 16) & 0x1fc) >> 2;
					indices[2] = (.)(packedColorIndices >> 25 & 0x7f); //((packedColorIndices >> 23) & 0x1fc) >> 2;
					indices[3] = (.)(packedColorIndices >> 4 & 0x7f); //((packedColorIndices >> 2) & 0x1fc) >> 2;
				}
				return indices;
			}
			
			public bool isTriangle { get => Emulator.active.installment == .SpyroTheDragon ?
				(packedVertexIndices >> 14 & 0x3f) == (packedVertexIndices >> 8 & 0x3f) :
				(packedVertexIndices >> 10 & 0x7f) == (packedVertexIndices >> 3 & 0x7f)
			;}
		}

		public struct NearFace {
			public uint8[4] trianglesIndices, colorsIndices, a, b;

			public bool isTriangle { get => trianglesIndices[0] == trianglesIndices[1]; }

			public struct RenderInfo {
				public uint8 texture, flipSideDepth, a, b;
				
				public bool transparent { get => Emulator.active.installment == .SpyroTheDragon && texture & 0x80 > 0; }
				// For "Ripto's Rage" and "Year of the Dragon", the transparency flag for it can be found on a per texture basis
				// Refer to "TextureQuad" for an implementation of the mentioned above

				public uint8 textureIndex { get => BitEdit.Get!(texture, 0x7f); set mut => BitEdit.Set!(texture, value, 0x7f); }
				public uint8 depthOffset { get => BitEdit.Get!(flipSideDepth, 0b0011); set mut => BitEdit.Set!(flipSideDepth, value, 0b0011); }
				public bool doubleSided { get => BitEdit.Get!(flipSideDepth, 0b1000) > 0; set mut => BitEdit.Set!(flipSideDepth, value, 0b1000); }
				public uint8 rotation {
					get => Emulator.active.installment == .SpyroTheDragon ? BitEdit.Get!(flipSideDepth, 0b0011) : BitEdit.Get!(flipSideDepth, 0b00110000) >> 4;
					set mut {
						if (Emulator.active.installment == .SpyroTheDragon) {
							BitEdit.Set!(flipSideDepth, value, 0b0011);
						} else {
							BitEdit.Set!(flipSideDepth, value << 4, 0b00110000);
						}
					}
				}
			}
			public RenderInfo* renderInfo  { get mut => Emulator.active.installment == .SpyroTheDragon ?  (.)&a: (.)&b; };
			public bool flipped {
				get mut => Emulator.active.installment == .SpyroTheDragon ? BitEdit.Get!(b[0], 0b0010) > 0: BitEdit.Get!(renderInfo.flipSideDepth, 0b0100) > 0;
				set mut {
					if (Emulator.active.installment == .SpyroTheDragon) {
						BitEdit.Set!(b[0], value, 0b0010);
					} else {
						BitEdit.Set!(renderInfo.flipSideDepth, value, 0b0100);
					}
				}
			}
		}

		public this(Emulator.Address address) {
			this.address = address;
			
			Emulator.active.ReadFromRAM(address, &metadata, sizeof(RegionMetadata));
		}

		/// Sets the position of the mesh's vertex with the index the game uses
		public void SetNearVertex(uint8 index, Vector3Int position, bool updateGame = false) {
			for (let meshVertexIndex < nearMesh2GameIndices.Count) {
				let vertexIndex = nearMesh2GameIndices[meshVertexIndex];
				if (vertexIndex == index) {
					nearMesh.vertices[meshVertexIndex] = position;
				}
			}
			nearVertices[index] = position;
			if (updateGame) {
				let regionPointer = address + 0x1c +
					((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2 +
					metadata.nearVertexCount + (int)metadata.nearColorCount * 2) * 4;
				Emulator.active.WriteToRAM(regionPointer, &nearVertices[index], (int)index * 4);
			}
		}

		public void Reload() {
			// Low Poly Count / Far Mesh
			GenerateFarMesh(address + 0x1c, metadata.farVertexCount, metadata.farColorCount, metadata.farFaceCount);
			// High Poly Count / Near Mesh
			GenerateNearMesh(address + 0x1c + ((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2) * 4, metadata.nearVertexCount, metadata.nearColorCount, metadata.nearFaceCount);
		}

		public void GetUsedTextures() {
			Emulator.Address regionPointer = address + 0x1c + ((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2) * 4;
			if (nearFaces == null) {
				nearFaces = new .[metadata.nearFaceCount];
				Emulator.active.ReadFromRAM(regionPointer + ((int)metadata.nearVertexCount + (int)metadata.nearColorCount * 2) * 4, nearFaces.CArray(), (int)metadata.nearFaceCount * sizeof(NearFace));
			}

			for (let i < metadata.nearFaceCount) {
				let textureIndex = nearFaces[i].renderInfo.textureIndex;

				if (!Terrain.usedTextureIndices.Contains(textureIndex)) {
					Terrain.usedTextureIndices.Add(textureIndex);
				}
			}
		}

		void GenerateFarMesh(Emulator.Address regionPointer, int vertexSize, int colorSize, int faceSize) {
			List<Vector3> vertexList = scope .();
			List<Renderer.Color> colorList = scope .();

			uint32[] packedVertices = scope .[vertexSize];
			Emulator.active.ReadFromRAM(regionPointer, packedVertices.CArray(), vertexSize * 4);
			nearVertices = scope .[vertexSize];
			for (let i < vertexSize) {
				nearVertices[i] = UnpackVertex(packedVertices[i]);
			}

			// Used for swapping around values
			Vector3[4] triangleVertices = ?;
			Renderer.Color[4] triangleColors = ?;
			
			uint8[4] triangleIndices, colorIndices;

			farFaces = new .[faceSize * 2];
			Emulator.active.ReadFromRAM(regionPointer + (vertexSize + colorSize) * 4, farFaces.CArray(), faceSize * sizeof(FarFace));

			Renderer.Color4[] vertexColors = scope .[colorSize];
			Emulator.active.ReadFromRAM(regionPointer + vertexSize * 4, vertexColors.CArray(), colorSize * 4);

			// Derived from Spyro the Dragon
			// Vertex Indexing [80026378]
			// Color Indexing [800264d4]

			// Derived from Spyro: Ripto's Rage
			// Vertex Indexing [80028e10]
			// Color Indexing [80028f28]
			for (let i < faceSize) {
				let face = farFaces[i];
				triangleIndices = face.UnpackVertexIndices();

				triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
				triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
				triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);

				colorIndices = face.UnpackColorIndices();

				triangleColors[0] = vertexColors[colorIndices[0]];
				triangleColors[1] = vertexColors[colorIndices[1]];
				triangleColors[2] = vertexColors[colorIndices[2]];

				if (triangleIndices[0] == triangleIndices[3]) {
					farMesh2GameIndices.Add(triangleIndices[0]);
					farMesh2GameIndices.Add(triangleIndices[2]);
					farMesh2GameIndices.Add(triangleIndices[1]);

					vertexList.Add(triangleVertices[0]);
					vertexList.Add(triangleVertices[2]);
					vertexList.Add(triangleVertices[1]);
					
					colorList.Add(triangleColors[0]);
					colorList.Add(triangleColors[2]);
					colorList.Add(triangleColors[1]);

					farFaceIndices.Add(i);
				} else {
					triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3] % packedVertices.Count]);
					triangleColors[3] = vertexColors[colorIndices[3]];
					
					farMesh2GameIndices.Add(triangleIndices[0]);
					farMesh2GameIndices.Add(triangleIndices[2]);
					farMesh2GameIndices.Add(triangleIndices[1]);
					
					farMesh2GameIndices.Add(triangleIndices[0]);
					farMesh2GameIndices.Add(triangleIndices[1]);
					farMesh2GameIndices.Add(triangleIndices[3]);

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

					farFaceIndices.Add(i);
					farFaceIndices.Add(i);
				}
			}

			Vector3[] v = new .[vertexList.Count];
			Vector3[] n = new .[vertexList.Count];
			Renderer.Color4[] c = new .[vertexList.Count];
			float[][2] u = new .[vertexList.Count];

			for (let i < vertexList.Count) {
				v[i] = vertexList[i];
				n[i] = .(0,0,1);
				c[i] = colorList[i];
				u[i] = .(0,0);
			}

			farMesh = new .(v, u, n, c);
		}

		void GenerateNearMesh(Emulator.Address regionPointer, int vertexSize, int colorSize, int faceSize) {
			List<uint32> activeIndexList = ?;
			List<Vector3> activeVertexList = ?;
			List<Renderer.Color> activeColorList = ?;
			List<float[2]> activeUvList = ?;
			
			List<uint32> activeIndexSubList = ?;
			List<Vector3> activeVertexSubList = ?;
			List<Renderer.Color> activeColorSubList = ?;
			List<float[2]> activeUvSubList = ?;

			List<uint8> activeNearMesh2GameIndices = ?;
			List<int> activeNearFaceIndices = ?;

			uint32[] packedVertices = scope .[vertexSize];
			Emulator.active.ReadFromRAM(regionPointer, packedVertices.CArray(), vertexSize * 4);
			nearVertices = scope .[vertexSize];
			for (let i < vertexSize) {
				nearVertices[i] = UnpackVertex(packedVertices[i]);
			}

			// Used for swapping around values
			float[4][2] triangleUV = ?;
			
			List<uint32> indexList = scope .();
			List<Vector3> vertexList = scope .();
			List<Renderer.Color> colorList = scope .();
			List<float[2]> uvList = scope .();
			
			List<uint32> indexTransparentList = scope .();
			List<Vector3> vertexTransparentList = scope .();
			List<Renderer.Color> colorTransparentList = scope .();
			List<float[2]> uvTransparentList = scope .();

			List<uint32> indexSubList = scope .();
			List<Vector3> vertexSubList = scope .();
			List<Renderer.Color> colorSubList = scope .();
			List<float[2]> uvSubList = scope .();

			List<uint32> indexTransparentSubList = scope .();
			List<Vector3> vertexTransparentSubList = scope .();
			List<Renderer.Color> colorTransparentSubList = scope .();
			List<float[2]> uvTransparentSubList = scope .();

			if (nearFaces == null) {
				nearFaces = new .[faceSize];
				Emulator.active.ReadFromRAM(regionPointer + (vertexSize + colorSize * 2) * 4, nearFaces.CArray(), faceSize * sizeof(NearFace));
			}

			nearColors = new .[colorSize * 2];
			Emulator.active.ReadFromRAM(regionPointer + vertexSize * 4, nearColors.CArray(), colorSize * 2 * 4);

			// Derived from Spyro: Ripto's Rage
			// Vertex Indexing [80024a00]
			// Color Indexing [80024c84]
			for (let i < faceSize) {
				var regionFace = nearFaces[i];
				var trianglesIndices = regionFace.trianglesIndices;
				var colorIndices = regionFace.colorsIndices;
				let textureIndex = regionFace.renderInfo.textureIndex;
				let flipSide = regionFace.flipped;
				var textureRotation = regionFace.renderInfo.rotation;
				
				uint8[2] indexSwap = flipSide ? .(2,1) : .(1,2);

				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
				TextureQuad* quad = ?;
				TextureQuad* quadSet = &Terrain.textures[textureIndex * quadCount];
				quad = quadSet = Emulator.active.installment == .SpyroTheDragon ? quadSet : quadSet + 1;
				var partialUV = quad.GetVramPartialUV();

				triangleUV[0] = .(partialUV.left, partialUV.rightY);
				triangleUV[1] = .(partialUV.right, partialUV.rightY);
				triangleUV[2] = .(partialUV.right, partialUV.leftY);
				triangleUV[3] = .(partialUV.left, partialUV.leftY);

				if (quad.GetTransparency() || regionFace.renderInfo.transparent) {
					// Low LOD
					activeIndexList = indexTransparentList;
					activeVertexList = vertexTransparentList;
					activeColorList = colorTransparentList;
					activeUvList = uvTransparentList;

					// High LOD
					activeIndexSubList = indexTransparentSubList;
					activeVertexSubList = vertexTransparentSubList;
					activeColorSubList = colorTransparentSubList;
					activeUvSubList = uvTransparentSubList;

					// Conversion Table
					activeNearMesh2GameIndices = nearMesh2GameTransparentIndices;
					activeNearFaceIndices = nearFaceTransparentIndices;
				} else {
					// Low LOD
					activeIndexList = indexList;
					activeVertexList = vertexList;
					activeColorList = colorList;
					activeUvList = uvList;
					
					// High LOD
					activeIndexSubList = indexSubList;
					activeVertexSubList = vertexSubList;
					activeColorSubList = colorSubList;
					activeUvSubList = uvSubList;
					
					// Conversion Table
					activeNearMesh2GameIndices = nearMesh2GameIndices;
					activeNearFaceIndices = nearFaceIndices;
				}

				if (regionFace.isTriangle) {
					// Low quality textures
					var baseIndex = (uint32)activeIndexList.Count;
					
					var indices = activeIndexList.GrowUnitialized(3);
					var vertices = activeVertexList.GrowUnitialized(3);
					var colors = activeColorList.GrowUnitialized(3);
					var uvs = activeUvList.GrowUnitialized(3);

					var M2Gindices = activeNearMesh2GameIndices.GrowUnitialized(3);

					float[3][2] rotatedTriangleUV = .(
						triangleUV[(0 - textureRotation) & 3],
						triangleUV[(2 - textureRotation) & 3],
						triangleUV[(3 - textureRotation) & 3]
					);


					indices[0] = baseIndex;
					indices[1] = baseIndex + indexSwap[0];
					indices[2] = baseIndex + indexSwap[1];

					M2Gindices[0] = trianglesIndices[3];
					M2Gindices[1] = trianglesIndices[2];
					M2Gindices[2] = trianglesIndices[1];

					vertices[0] = nearVertices[M2Gindices[0]];
					vertices[1] = nearVertices[M2Gindices[1]];
					vertices[2] = nearVertices[M2Gindices[2]];
					
					colors[0] = nearColors[colorIndices[3]];
					colors[1] = nearColors[colorIndices[2]];
					colors[2] = nearColors[colorIndices[1]];
					
					uvs[0] = rotatedTriangleUV[2];
					uvs[1] = rotatedTriangleUV[1];
					uvs[2] = rotatedTriangleUV[0];

					// High quality textures
					Vector3[5] midpoints = ?;
					midpoints[0] = (vertices[0] + vertices[1]) / 2; // Top
					midpoints[1] = (vertices[1] + vertices[2]) / 2; // Diagonal
					midpoints[2] = (vertices[2] + vertices[0]) / 2; // Left

					Renderer.Color[5] midcolors = ?;
					midcolors[0] = Renderer.Color.Lerp(colors[0], colors[1], 0.5f);
					midcolors[1] = Renderer.Color.Lerp(colors[1], colors[2], 0.5f);
					midcolors[2] = Renderer.Color.Lerp(colors[2], colors[0], 0.5f);

					Vector3[4][3] subQuadVertices = .(
						(midpoints[2], midpoints[0], vertices[0]),
						(midpoints[1], vertices[1], midpoints[0]),
						(vertices[2], midpoints[1], midpoints[2]),
						(midpoints[2], midpoints[1], midpoints[0])
					);

					Renderer.Color[4][3] subQuadColors = .(
						(midcolors[2], midcolors[0], colors[0]),
						(midcolors[1], colors[1], midcolors[0]),
						(colors[2], midcolors[1], midcolors[2]),
						(midcolors[2], midcolors[1], midcolors[0])
					);

					const uint8[4][3] rotationOrder = .(
						(0,1,2),
						(1,3,0),
						(3,2,1),
						(2,0,3)
					);
					let subQuadIndexRotation = rotationOrder[textureRotation];

					// Corner triangles
					baseIndex = (uint32)activeIndexSubList.Count;
					
					indices = activeIndexSubList.GrowUnitialized(12);
					vertices = activeVertexSubList.GrowUnitialized(12);
					colors = activeColorSubList.GrowUnitialized(12);
					uvs = activeUvSubList.GrowUnitialized(12);

					for (let ti < 3) {
						let offset = ti * 3;

						indices[0 + offset] = baseIndex + (.)offset;
						indices[1 + offset] = baseIndex + (.)offset + indexSwap[0];
						indices[2 + offset] = baseIndex + (.)offset + indexSwap[1];

						vertices[0 + offset] = subQuadVertices[ti][2];
						vertices[1 + offset] = subQuadVertices[ti][1];
						vertices[2 + offset] = subQuadVertices[ti][0];

						colors[0 + offset] = subQuadColors[ti][2];
						colors[1 + offset] = subQuadColors[ti][1];
						colors[2 + offset] = subQuadColors[ti][0];

						quad = quadSet + 1 + subQuadIndexRotation[ti];
						partialUV = quad.GetVramPartialUV();
						let quadRotation = quad.GetQuadRotation();
						let quadFlip = quad.GetFlip();

						triangleUV[0] = .(partialUV.left, partialUV.rightY);
						triangleUV[1] = .(partialUV.right, partialUV.rightY);
						triangleUV[2] = .(partialUV.right, partialUV.leftY);
						triangleUV[3] = .(partialUV.left, partialUV.leftY);

						rotatedTriangleUV = .(
							triangleUV[(0 - (textureRotation + quadRotation)) & 3],
							triangleUV[(2 - (textureRotation + quadRotation)) & 3],
							triangleUV[(3 - (textureRotation + quadRotation)) & 3]
						);
						
						if (quadFlip) {
							Swap!(rotatedTriangleUV[0], rotatedTriangleUV[1]);
						}
						
						uvs[0 + offset] = rotatedTriangleUV[2];
						uvs[1 + offset] = rotatedTriangleUV[1];
						uvs[2 + offset] = rotatedTriangleUV[0];
					}

					// Center triangle
					indices[9] = baseIndex + 9;
					indices[10] = baseIndex + 9 + indexSwap[0];
					indices[11] = baseIndex + 9 + indexSwap[1];

					vertices[9] = subQuadVertices[3][2];
					vertices[10] = subQuadVertices[3][1];
					vertices[11] = subQuadVertices[3][0];

					colors[9] = subQuadColors[3][2];
					colors[10] = subQuadColors[3][1];
					colors[11] = subQuadColors[3][0];

					quad = quadSet + 1 + subQuadIndexRotation[0];
					partialUV = quad.GetVramPartialUV();
					let quadRotation = quad.GetQuadRotation();
					let quadFlip = quad.GetFlip();
					
					triangleUV[0] = .(partialUV.left, partialUV.rightY);
					triangleUV[1] = .(partialUV.right, partialUV.rightY);
					triangleUV[2] = .(partialUV.right, partialUV.leftY);
					triangleUV[3] = .(partialUV.left, partialUV.leftY);

					rotatedTriangleUV = .(
						triangleUV[(0 - (textureRotation + quadRotation)) & 3],
						triangleUV[(2 - (textureRotation + quadRotation)) & 3],
						triangleUV[(1 - (textureRotation + quadRotation)) & 3]
					);

					if (quadFlip) {
						Swap!(rotatedTriangleUV[0], rotatedTriangleUV[1]);
					}

					uvs[9] = rotatedTriangleUV[1];
					uvs[10] = rotatedTriangleUV[2];
					uvs[11] = rotatedTriangleUV[0];

					activeNearFaceIndices.Add(i);
				} else {
					// Low quality textures
					var baseIndex = (uint32)activeIndexList.Count;

					var indices = activeIndexList.GrowUnitialized(6);
					var vertices = activeVertexList.GrowUnitialized(6);
					var colors = activeColorList.GrowUnitialized(6);
					var uvs = activeUvList.GrowUnitialized(6);
					
					var M2Gindices = activeNearMesh2GameIndices.GrowUnitialized(6);

					const uint8[2][2] swap = .(.(0,2), .(2,0));
					const int8[2] oppositeIndex = .(1,3);
					for (let qti < 2) {
						let offset = qti * 3;

						indices[0 + offset] = baseIndex + (.)offset;
						indices[1 + offset] = baseIndex + (.)offset + indexSwap[0];
						indices[2 + offset] = baseIndex + (.)offset + indexSwap[1];

						M2Gindices[0 + offset] = trianglesIndices[oppositeIndex[qti]];
						M2Gindices[1 + offset] = trianglesIndices[swap[qti][0]];
						M2Gindices[2 + offset] = trianglesIndices[swap[qti][1]];

						vertices[0 + offset] = nearVertices[M2Gindices[0 + offset]];
						vertices[1 + offset] = nearVertices[M2Gindices[1 + offset]];
						vertices[2 + offset] = nearVertices[M2Gindices[2 + offset]];

						colors[0 + offset] = nearColors[colorIndices[oppositeIndex[qti]]];
						colors[1 + offset] = nearColors[colorIndices[swap[qti][0]]];
						colors[2 + offset] = nearColors[colorIndices[swap[qti][1]]];

						uvs[0 + offset] = triangleUV[oppositeIndex[qti]];
						uvs[1 + offset] = triangleUV[swap[qti][0]];
						uvs[2 + offset] = triangleUV[swap[qti][1]];
					}

					// High quality textures
					Vector3[5] midpoints = ?;
					midpoints[0] = (vertices[3] + vertices[4]) / 2; // Top
					midpoints[1] = (vertices[0] + vertices[1]) / 2; // Bottom
					midpoints[2] = (vertices[3] + vertices[5]) / 2; // Left
					midpoints[3] = (vertices[0] + vertices[2]) / 2; // Right
					midpoints[4] = (midpoints[0] + midpoints[1]) / 2;

					Renderer.Color[5] midcolors = ?;
					midcolors[0] = Renderer.Color.Lerp(colors[3], colors[4], 0.5f);
					midcolors[1] = Renderer.Color.Lerp(colors[0], colors[1], 0.5f);
					midcolors[2] = Renderer.Color.Lerp(colors[3], colors[5], 0.5f);
					midcolors[3] = Renderer.Color.Lerp(colors[0], colors[2], 0.5f);
					midcolors[4] = Renderer.Color.Lerp(colors[1], colors[4], 0.5f);

					Vector3[4][4] subQuadVertices = .(
						.(midpoints[2], midpoints[4], midpoints[0], vertices[3]),
						.(midpoints[4], midpoints[3], vertices[2], midpoints[0]),
						.(vertices[5], midpoints[1], midpoints[4], midpoints[2]),
						.(midpoints[1], vertices[0], midpoints[3], midpoints[4]),
					);

					Renderer.Color[4][4] subQuadColors = .(
						.(midcolors[2], midcolors[4], midcolors[0], colors[3]),
						.(midcolors[4], midcolors[3], colors[2], midcolors[0]),
						.(colors[5], midcolors[1], midcolors[4], midcolors[2]),
						.(midcolors[1], colors[0], midcolors[3], midcolors[4]),
					);
					
					baseIndex = (uint32)activeIndexSubList.Count;

					indices = activeIndexSubList.GrowUnitialized(24);
					vertices = activeVertexSubList.GrowUnitialized(24);
					colors = activeColorSubList.GrowUnitialized(24);
					uvs = activeUvSubList.GrowUnitialized(24);

					for (let qi < 4) {
						quad++;
						partialUV = quad.GetVramPartialUV();
						let quadRotation = quad.GetQuadRotation();
						let quadFlip = quad.GetFlip();

						triangleUV[0] = .(partialUV.left, partialUV.rightY);
						triangleUV[1] = .(partialUV.right, partialUV.rightY);
						triangleUV[2] = .(partialUV.right, partialUV.leftY);
						triangleUV[3] = .(partialUV.left, partialUV.leftY);

						float[4][2] rotatedTriangleUV = .(
							triangleUV[(0 - quadRotation) & 3],
							triangleUV[(1 - quadRotation) & 3],
							triangleUV[(2 - quadRotation) & 3],
							triangleUV[(3 - quadRotation) & 3]
						);

						if (quadFlip) {
							Swap!(rotatedTriangleUV[0], rotatedTriangleUV[2]);
						}

						for (let qti < 2) {
							let offset = qi * 6 + qti * 3;
							
							indices[0 + offset] = baseIndex + (.)offset;
							indices[1 + offset] = baseIndex + (.)offset + indexSwap[0];
							indices[2 + offset] = baseIndex + (.)offset + indexSwap[1];

							vertices[0 + offset] = subQuadVertices[qi][oppositeIndex[qti]];
							vertices[1 + offset] = subQuadVertices[qi][swap[qti][0]];
							vertices[2 + offset] = subQuadVertices[qi][swap[qti][1]];

							colors[0 + offset] = subQuadColors[qi][oppositeIndex[qti]];
							colors[1 + offset] = subQuadColors[qi][swap[qti][0]];
							colors[2 + offset] = subQuadColors[qi][swap[qti][1]];

							uvs[0 + offset] = rotatedTriangleUV[oppositeIndex[qti]];
							uvs[1 + offset] = rotatedTriangleUV[swap[qti][0]];
							uvs[2 + offset] = rotatedTriangleUV[swap[qti][1]];
						}
					}

					activeNearFaceIndices.Add(i);
					activeNearFaceIndices.Add(i);
				}
			}

			uint32[] indx = new .[indexList.Count];
			
			for (let i < indexList.Count) {
				indx[i] = indexList[i];
			}

			Vector3[] v = new .[vertexList.Count];
			Vector3[] n = new .[vertexList.Count];
			Renderer.Color4[] c = new .[vertexList.Count];
			float[][2] u = new .[vertexList.Count];

			for (let i < vertexList.Count) {
				v[i] = vertexList[i];
				n[i] = .(0,0,1);
				c[i] = colorList[i];
				u[i] = uvList[i];
			}

			nearMesh = new .(v, u, n, c, indx);

			indx = new .[indexSubList.Count];

			for (let i < indexSubList.Count) {
				indx[i] = indexSubList[i];
			}

			v = new .[vertexSubList.Count];
			n = new .[vertexSubList.Count];
			c = new .[vertexSubList.Count];
			u = new .[vertexSubList.Count];
			
			for (let i < vertexSubList.Count) {
				v[i] = vertexSubList[i];
				n[i] = .(0,0,1);
				c[i] = colorSubList[i];
				u[i] = uvSubList[i];
			}
			
			nearMeshSubdivided = new .(v, u, n, c, indx);
			
			indx = new .[indexTransparentList.Count];

			for (let i < indexTransparentList.Count) {
				indx[i] = indexTransparentList[i];
			}

			v = new .[vertexTransparentList.Count];
			n = new .[vertexTransparentList.Count];
			c = new .[vertexTransparentList.Count];
			u = new .[vertexTransparentList.Count];

			for (let i < vertexTransparentList.Count) {
				v[i] = vertexTransparentList[i];
				n[i] = .(0,0,1);
				c[i] = colorTransparentList[i];
				u[i] = uvTransparentList[i];
			}

			nearMeshTransparent = new .(v, u, n, c, indx);

			indx = new .[indexTransparentSubList.Count];

			for (let i < indexTransparentSubList.Count) {
				indx[i] = indexTransparentSubList[i];
			}

			v = new .[vertexTransparentSubList.Count];
			n = new .[vertexTransparentSubList.Count];
			c = new .[vertexTransparentSubList.Count];
			u = new .[vertexTransparentSubList.Count];

			for (let i < vertexTransparentSubList.Count) {
				v[i] = vertexTransparentSubList[i];
				n[i] = .(0,0,1);
				c[i] = colorTransparentSubList[i];
				u[i] = uvTransparentSubList[i];
			}

			nearMeshTransparentSubdivided = new .(v, u, n, c, indx);
		}
	
		// Derived from Spyro: Ripto's Rage
		// Far [80028c2c]
		// Near [80024664]
		public static Vector3Int UnpackVertex(uint32 packedVertex) {
			Vector3Int vertex = ?;
	
			vertex.x = (.)(packedVertex >> 21);
			vertex.y = (.)(packedVertex >> 10 & 0x7ff);
			vertex.z = (.)((packedVertex & 0x3ff) << 1);
	
			return vertex;
		}

		// This should almost be a complete copy of the mesh generation of UVs
		// but because of how this is separated for optimization reasons its partially different
		// TODO: Get all possible UV Quad/Face options working
		public void UpdateUVs(List<int> affectedTriangles, float[4 * 5][2] triangleUV, bool transparent) {
			for (let triangleIndex in affectedTriangles) {
				let faceIndices = transparent ? nearFaceTransparentIndices : nearFaceIndices;
				let regionMesh = transparent ? nearMeshTransparent : nearMesh;
				let regionMeshSubdivided = transparent ? nearMeshTransparentSubdivided : nearMeshSubdivided;

				for (var i < affectedTriangles.Count) {
					let triangleIndex = affectedTriangles[i];
					let vertexIndex = triangleIndex * 3;
					let subdividedVertexIndex = triangleIndex * 3 * 4;

					let nearFaceIndex = faceIndices[triangleIndex];
					TerrainRegion.NearFace regionFace = nearFaces[nearFaceIndex];
					let textureRotation = regionFace.renderInfo.rotation;

					if (regionFace.isTriangle) {
						float[3][2] rotatedTriangleUV = .(
							triangleUV[(0 - textureRotation) & 3],
							triangleUV[(2 - textureRotation) & 3],
							triangleUV[(3 - textureRotation) & 3]
						);

						regionMesh.uvs[0 + vertexIndex] = rotatedTriangleUV[2];
						regionMesh.uvs[1 + vertexIndex] = rotatedTriangleUV[1];
						regionMesh.uvs[2 + vertexIndex] = rotatedTriangleUV[0];

						const uint8[4][3] rotationOrder = .(
							(0,1,2),
							(1,3,0),
							(3,2,1),
							(2,0,3)
						);
						let subQuadIndexRotation = rotationOrder[textureRotation];

						int offset = ?;
						for (let ti < 3) {
							let offset2 = ti * 3;
							offset = (1 + subQuadIndexRotation[ti]) * 4;

							rotatedTriangleUV = .(
								triangleUV[((0 - (textureRotation)) & 3) + offset],
								triangleUV[((2 - (textureRotation)) & 3) + offset],
								triangleUV[((3 - (textureRotation)) & 3) + offset]
							);

							regionMeshSubdivided.uvs[0 + offset2 + subdividedVertexIndex] = rotatedTriangleUV[2];
							regionMeshSubdivided.uvs[1 + offset2 + subdividedVertexIndex] = rotatedTriangleUV[1];
							regionMeshSubdivided.uvs[2 + offset2 + subdividedVertexIndex] = rotatedTriangleUV[0];
						}

						offset = (1 + subQuadIndexRotation[0]) * 4;

						rotatedTriangleUV = .(
							triangleUV[((0 - (textureRotation)) & 3) + offset],
							triangleUV[((2 - (textureRotation)) & 3) + offset],
							triangleUV[((1 - (textureRotation)) & 3) + offset]
						);

						regionMeshSubdivided.uvs[9 + subdividedVertexIndex] = rotatedTriangleUV[1];
						regionMeshSubdivided.uvs[10 + subdividedVertexIndex] = rotatedTriangleUV[2];
						regionMeshSubdivided.uvs[11 + subdividedVertexIndex] = rotatedTriangleUV[0];
					} else {
						const int8[2][2] swap = .(.(0,2), .(2,0));
						const int8[2] oppositeIndex = .(1,3);
						for (let qti < 2) {
							let offset = qti * 3;

							regionMesh.uvs[0 + offset + vertexIndex] = triangleUV[oppositeIndex[qti]];
							regionMesh.uvs[1 + offset + vertexIndex] = triangleUV[swap[qti][0]];
							regionMesh.uvs[2 + offset + vertexIndex] = triangleUV[swap[qti][1]];
						}

						// There hasn't seem to be a use for animated rotated subquads...
						// Come back to this when its relevant
						let quadRotation = 0;

						for (let qi < 4) {
							let offset2 = (1 + qi) * 4;

							float[4][2] rotatedTriangleUV = .(
								triangleUV[((0 - quadRotation) & 3) + offset2],
								triangleUV[((1 - quadRotation) & 3) + offset2],
								triangleUV[((2 - quadRotation) & 3) + offset2],
								triangleUV[((3 - quadRotation) & 3) + offset2]
							);

							/*if (quadFlip) {
								Swap!(rotatedTriangleUV[0], rotatedTriangleUV[2]);
							}*/

							
							for (let qti < 2) {
								let offset = qi * 6 + qti * 3;

								regionMeshSubdivided.uvs[0 + offset + subdividedVertexIndex] = rotatedTriangleUV[oppositeIndex[qti]];
								regionMeshSubdivided.uvs[1 + offset + subdividedVertexIndex] = rotatedTriangleUV[swap[qti][0]];
								regionMeshSubdivided.uvs[2 + offset + subdividedVertexIndex] = rotatedTriangleUV[swap[qti][1]];
							}
						}

						i++;
					}
				}
				
				regionMesh.SetDirty(.UV);
				regionMeshSubdivided.SetDirty(.UV);
			}
		}

		public NearFace* GetNearFace(int faceIndex) {
			return &nearFaces[faceIndex];
		}

		public void SetNearFace(NearFace* face, int faceIndex) {
			Emulator.Address<NearFace> faceAddress = (.)address + 0x1c +
				((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2 + // Pass over all far data
				(int)metadata.nearVertexCount + (int)metadata.nearColorCount * 2 + // Pass over previous near data
				faceIndex * 4) * 4;// Index the face
			Emulator.active.WriteToRAM(faceAddress, face, sizeof(NearFace));
			nearFaces[faceIndex] = *face;

			let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
			TextureQuad* quad = &Terrain.textures[face.renderInfo.textureIndex * quadCount];
			if (Emulator.active.installment != .SpyroTheDragon) {
				quad++;
			}

			float[4 * 5][2] triangleUV = ?;
			for (let qi < 5) {
				let partialUV = quad.GetVramPartialUV();

				let offset = qi * 4;
				triangleUV[0 + offset] = .(partialUV.left, partialUV.rightY);
				triangleUV[1 + offset] = .(partialUV.right, partialUV.rightY);
				triangleUV[2 + offset] = .(partialUV.right, partialUV.leftY);
				triangleUV[3 + offset] = .(partialUV.left, partialUV.leftY);

				quad++;
			}

			let transparent = Emulator.active.installment == .SpyroTheDragon ? quad.GetTransparency() : face.renderInfo.transparent;

			let affectedTriangles = scope List<int>();
			let faceIndices = transparent ? nearFaceTransparentIndices : nearFaceIndices;
			for (let i < faceIndices.Count) {
				let fi = faceIndices[i];
				if (fi == faceIndex) {
					affectedTriangles.Add(i);
				}
			}
			UpdateUVs(affectedTriangles, triangleUV, transparent);

			// Flip normals by swapping index order
			Mesh[2] meshSet = transparent ? .(nearMeshTransparent, nearMeshTransparentSubdivided) : .(nearMesh, nearMeshSubdivided);

			var di0 = 1 + (uint8)face.flipped % 2;
			var di1 = 1 + ((uint8)face.flipped + 1) % 2;
			for (let triangleIndex in affectedTriangles) {
				let baseTriangleIndex = triangleIndex * 3;

				// Low LOD
				meshSet[0].indices[baseTriangleIndex + 1] = (.)baseTriangleIndex + di0;
				meshSet[0].indices[baseTriangleIndex + 2] = (.)baseTriangleIndex + di1;

				// High LOD
				for (let i < 4) {
					let baseSubdividedTriangleIndex = baseTriangleIndex * 4 + i * 3;
					
					meshSet[1].indices[baseSubdividedTriangleIndex + 1] = (.)baseSubdividedTriangleIndex + di0;
					meshSet[1].indices[baseSubdividedTriangleIndex + 2] = (.)baseSubdividedTriangleIndex + di1;
				}
			}

			// Force update the region's mesh
			meshSet[0].Update();
			meshSet[1].Update();
		}

		public void DrawFar() {
			Matrix3 scale = .Scale(16, 16, Emulator.active.installment == .SpyroTheDragon ? 8 : 16);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			farMesh.Draw();
		}
		
		public void DrawNear() {
			Matrix3 scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMesh.Draw();
		}

		public void DrawNearTransparent() {
			Matrix3 scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshTransparent.Draw();
		}

		public void DrawNearSubdivided() {
			Matrix3 scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshSubdivided.Draw();
		}

		public void DrawNearTransparentSubdivided() {
			Matrix3 scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshTransparentSubdivided.Draw();
		}
	}
}
