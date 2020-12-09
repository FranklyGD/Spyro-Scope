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
			if (Emulator.installment == .SpyroTheDragon) {
				return 8;
			} else {
				return metadata.verticallyScaledDown ? 2 : 16;
			}
		} }

		public Mesh farMesh ~ delete _;
		public List<uint32> farMeshIndices = new .() ~ delete _;

		Vector[] nearVertices;
		Renderer.Color4[] nearColors ~ delete _;
		public NearFace[] nearFaces ~ delete _;
		
		public Mesh nearMesh ~ delete _;
		public Mesh nearMeshSubdivided ~ delete _;
		public List<uint8> nearMesh2GameIndices = new .() ~ delete _;
		public List<int> nearFaceIndices = new .() ~ delete _;
		public List<uint8> nearTri2TextureIndices = new .() ~ delete _;

		public Mesh nearMeshTransparent ~ delete _;
		public Mesh nearMeshTransparentSubdivided ~ delete _;
		public List<uint8> nearMesh2GameTransparentIndices = new .() ~ delete _;
		public List<int> nearFaceTransparentIndices = new .() ~ delete _;
		public List<uint8> nearTri2TransparentTextureIndices = new .() ~ delete _;

		public int highestUsedTextureIndex = -1;

		public struct NearFace {
			public uint8[4] trianglesIndices, colorsIndices, a, b;

			public bool isTriangle { get => trianglesIndices[0] == trianglesIndices[1]; }

			public struct RenderInfo {
				public uint8 texture, flipSideDepth, a, b;
				
				public bool transparent { get => Emulator.installment == .SpyroTheDragon && texture & 0x80 > 0; }
				// For "Ripto's Rage" and "Year of the Dragon", the transparency flag for it can be found on a per texture basis
				// Refer to "TextureQuad" for an implementation of the mentioned above

				public uint8 textureIndex { get => texture & 0x7f; }
				public uint8 depthOffset { get => flipSideDepth & 0b0011; }
				public bool doubleSided { get => flipSideDepth & 0b1000 > 0; }
				public uint8 rotation { get => Emulator.installment == .SpyroTheDragon ? flipSideDepth & 0b0011 : (flipSideDepth & 0b00110000) >> 4; }
			}
			public RenderInfo* renderInfo  { get mut => Emulator.installment == .SpyroTheDragon ?  (.)&a: (.)&b; };
			public bool flipped { get mut => (Emulator.installment == .SpyroTheDragon ? (b[0] & 0b0010) : (renderInfo.flipSideDepth & 0b0100)) > 0; }
		}

		public this(Emulator.Address address) {
			this.address = address;
			
			Emulator.ReadFromRAM(address, &metadata, sizeof(RegionMetadata));
		}

		/// Sets the position of the mesh's vertex with the index the game uses
		public void SetNearVertex(uint8 index, VectorInt position, bool updateGame = false) {
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
				Emulator.WriteToRAM(regionPointer, &nearVertices[index], (int)index * 4);
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
			nearFaces = scope .[metadata.nearFaceCount];
			Emulator.ReadFromRAM(regionPointer + ((int)metadata.nearVertexCount + (int)metadata.nearColorCount * 2) * 4, nearFaces.CArray(), (int)metadata.nearFaceCount * sizeof(NearFace));

			for (let i < metadata.nearFaceCount) {
				let textureIndex = nearFaces[i].renderInfo.textureIndex;

				if (!Terrain.usedTextureIndices.Contains(textureIndex)) {
					Terrain.usedTextureIndices.Add(textureIndex);
				}
			}
		}

		void GenerateFarMesh(Emulator.Address regionPointer, int vertexSize, int colorSize, int faceSize) {
			List<Vector> vertexList = scope .();
			List<Renderer.Color> colorList = scope .();

			uint32[] packedVertices = scope .[vertexSize];
			Emulator.ReadFromRAM(regionPointer, packedVertices.CArray(), vertexSize * 4);
			nearVertices = scope .[vertexSize];
			for (let i < vertexSize) {
				nearVertices[i] = UnpackVertex(packedVertices[i]);
			}

			// Used for swapping around values
			Vector[4] triangleVertices = ?;
			Renderer.Color[4] triangleColors = ?;
			
			uint32[4] triangleIndices = ?;

			uint32[] regionTriangles = scope .[faceSize * 2];
			Emulator.ReadFromRAM(regionPointer + (vertexSize + colorSize) * 4, regionTriangles.CArray(), faceSize * 2 * 4);

			Renderer.Color4[] vertexColors = scope .[colorSize];
			Emulator.ReadFromRAM(regionPointer + vertexSize * 4, vertexColors.CArray(), colorSize * 4);

			// Derived from Spyro the Dragon
			// Vertex Indexing [80026378]
			// Color Indexing [800264d4]

			// Derived from Spyro: Ripto's Rage
			// Vertex Indexing [80028e10]
			// Color Indexing [80028f28]
			for (let i < faceSize) {
				uint32 packedTriangleIndex = regionTriangles[i * 2];
				uint32 packedColorIndex = regionTriangles[i * 2 + 1];

				if (Emulator.installment == .SpyroTheDragon) {
					triangleIndices[0] = packedTriangleIndex >> 14 & 0x3f; //((packedTriangleIndex >> 11) & 0x1f8) >> 3;
					triangleIndices[1] = packedTriangleIndex >> 20 & 0x3f; //((packedTriangleIndex >> 17) & 0x1f8) >> 3;
					triangleIndices[2] = packedTriangleIndex >> 26 & 0x3f; //((packedTriangleIndex >> 23) & 0x1f8) >> 3;
					triangleIndices[3] = packedTriangleIndex >> 8 & 0x3f; //((packedTriangleIndex >> 5) & 0x1f8) >> 3;
				} else {
					triangleIndices[0] = packedTriangleIndex >> 10 & 0x7f; //((packedTriangleIndex >> 7) & 0x3fc) >> 2;
					triangleIndices[1] = packedTriangleIndex >> 17 & 0x7f; //((packedTriangleIndex >> 14) & 0x3fc) >> 2;
					triangleIndices[2] = packedTriangleIndex >> 24 & 0x7f; //((packedTriangleIndex >> 21) & 0x3fc) >> 2;
					triangleIndices[3] = packedTriangleIndex >> 3 & 0x7f; //(packedTriangleIndex & 0x3fc) >> 2;
				}

				triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
				triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
				triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);

				if (Emulator.installment == .SpyroTheDragon) {
					triangleColors[0] = vertexColors[packedColorIndex >> 14 & 0x3f]; //((packedTriangleIndex >> 12) & 0xfc) >> 2;
					triangleColors[1] = vertexColors[packedColorIndex >> 20 & 0x3f]; //((packedTriangleIndex >> 18) & 0xfc) >> 2;
					triangleColors[2] = vertexColors[packedColorIndex >> 26 & 0x3f]; //((packedTriangleIndex >> 24) & 0xfc) >> 2;
				} else {
					triangleColors[0] = vertexColors[packedColorIndex >> 11 & 0x7f]; //((packedTriangleColorIndex >> 9) & 0x1fc) >> 2;
					triangleColors[1] = vertexColors[packedColorIndex >> 18 & 0x7f]; //((packedTriangleColorIndex >> 16) & 0x1fc) >> 2;
					triangleColors[2] = vertexColors[packedColorIndex >> 25 & 0x7f]; //((packedTriangleColorIndex >> 23) & 0x1fc) >> 2;
				}

				if (triangleIndices[0] == triangleIndices[3]) {
					vertexList.Add(triangleVertices[0]);
					vertexList.Add(triangleVertices[2]);
					vertexList.Add(triangleVertices[1]);
					
					colorList.Add(triangleColors[0]);
					colorList.Add(triangleColors[2]);
					colorList.Add(triangleColors[1]);
				} else {
					triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3] % packedVertices.Count]);
					
					if (Emulator.installment == .SpyroTheDragon) {
						triangleColors[3] = vertexColors[packedColorIndex >> 8 & 0x3f]; //((packedTriangleColorIndex >> 6) & 0xfc) >> 2;
					} else {
						triangleColors[3] = vertexColors[packedColorIndex >> 4 & 0x7f]; //((packedTriangleColorIndex >> 2) & 0x1fc) >> 2;
					}

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

			Vector[] v = new .[vertexList.Count];
			Vector[] n = new .[vertexList.Count];
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
			List<Vector> activeVertexList = ?;
			List<Renderer.Color> activeColorList = ?;
			List<float[2]> activeUvList = ?;
			
			List<Vector> activeVertexSubList = ?;
			List<Renderer.Color> activeColorSubList = ?;
			List<float[2]> activeUvSubList = ?;

			List<uint8> activeNearMeshIndices = ?;
			List<int> activeNearFaceIndices = ?;
			List<uint8> activeNearTextureIndices = ?;

			uint32[] packedVertices = scope .[vertexSize];
			Emulator.ReadFromRAM(regionPointer, packedVertices.CArray(), vertexSize * 4);
			nearVertices = scope .[vertexSize];
			for (let i < vertexSize) {
				nearVertices[i] = UnpackVertex(packedVertices[i]);
			}

			// Used for swapping around values
			float[4][2] triangleUV = ?;

			List<Vector> vertexList = scope .();
			List<Renderer.Color> colorList = scope .();
			List<float[2]> uvList = scope .();

			List<Vector> vertexTransparentList = scope .();
			List<Renderer.Color> colorTransparentList = scope .();
			List<float[2]> uvTransparentList = scope .();

			List<Vector> vertexSubList = scope .();
			List<Renderer.Color> colorSubList = scope .();
			List<float[2]> uvSubList = scope .();

			List<Vector> vertexTransparentSubList = scope .();
			List<Renderer.Color> colorTransparentSubList = scope .();
			List<float[2]> uvTransparentSubList = scope .();

			nearFaces = new .[faceSize];
			Emulator.ReadFromRAM(regionPointer + (vertexSize + colorSize * 2) * 4, nearFaces.CArray(), faceSize * sizeof(NearFace));

			nearColors = new .[colorSize * 2];
			Emulator.ReadFromRAM(regionPointer + vertexSize * 4, nearColors.CArray(), colorSize * 2 * 4);

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

				let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;
				TextureQuad* quad = ?;
				TextureQuad* quadSet = &Terrain.textureInfos[textureIndex * quadCount];
				quad = quadSet = Emulator.installment == .SpyroTheDragon ? quadSet : quadSet + 1;
				var partialUV = quad.GetVramPartialUV();

				triangleUV[0] = .(partialUV.left, partialUV.rightY);
				triangleUV[1] = .(partialUV.right, partialUV.rightY);
				triangleUV[2] = .(partialUV.right, partialUV.leftY);
				triangleUV[3] = .(partialUV.left, partialUV.leftY);

				if (quad.GetTransparency() || regionFace.renderInfo.transparent) {
					activeVertexList = vertexTransparentList;
					activeColorList = colorTransparentList;
					activeUvList = uvTransparentList;
					activeVertexSubList = vertexTransparentSubList;
					activeColorSubList = colorTransparentSubList;
					activeUvSubList = uvTransparentSubList;
					activeNearMeshIndices = nearMesh2GameTransparentIndices;
					activeNearFaceIndices = nearFaceTransparentIndices;
					activeNearTextureIndices = nearTri2TransparentTextureIndices;
				} else {
					activeVertexList = vertexList;
					activeColorList = colorList;
					activeUvList = uvList;
					activeVertexSubList = vertexSubList;
					activeColorSubList = colorSubList;
					activeUvSubList = uvSubList;
					activeNearMeshIndices = nearMesh2GameIndices;
					activeNearFaceIndices = nearFaceIndices;
					activeNearTextureIndices = nearTri2TextureIndices;
				}

				if (regionFace.isTriangle) {
					// Low quality textures
					float[3][2] rotatedTriangleUV = .(
						triangleUV[(0 - textureRotation) & 3],
						triangleUV[(2 - textureRotation) & 3],
						triangleUV[(3 - textureRotation) & 3]
					);

					int8[2] indexSwap = flipSide ? .(1,3) : .(3,1);

					activeNearMeshIndices.Add(trianglesIndices[indexSwap[0]]);
					activeNearMeshIndices.Add(trianglesIndices[2]);
					activeNearMeshIndices.Add(trianglesIndices[indexSwap[1]]);

					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[0]]]);
					activeVertexList.Add(nearVertices[trianglesIndices[2]]);
					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[1]]]);

					activeColorList.Add(nearColors[colorIndices[indexSwap[0]]]);
					activeColorList.Add(nearColors[colorIndices[2]]);
					activeColorList.Add(nearColors[colorIndices[indexSwap[1]]]);

					indexSwap[0]--;
					indexSwap[1]--;

					activeUvList.Add(rotatedTriangleUV[indexSwap[0]]);
					activeUvList.Add(rotatedTriangleUV[1]);
					activeUvList.Add(rotatedTriangleUV[indexSwap[1]]);

					// High quality textures
					Vector[5] midpoints = ?;
					midpoints[0] = (nearVertices[trianglesIndices[1]] + nearVertices[trianglesIndices[2]]) / 2;
					midpoints[1] = (nearVertices[trianglesIndices[2]] + nearVertices[trianglesIndices[3]]) / 2;
					midpoints[2] = (nearVertices[trianglesIndices[3]] + nearVertices[trianglesIndices[1]]) / 2;

					Renderer.Color[5] midcolors = ?;
					midcolors[0] = Renderer.Color.Lerp(nearColors[colorIndices[1]], nearColors[colorIndices[2]], 0.5f);
					midcolors[1] = Renderer.Color.Lerp(nearColors[colorIndices[2]], nearColors[colorIndices[3]], 0.5f);
					midcolors[2] = Renderer.Color.Lerp(nearColors[colorIndices[3]], nearColors[colorIndices[1]], 0.5f);

					Vector[4][3] subQuadVertices = .(
						(nearVertices[trianglesIndices[3]], midpoints[1], midpoints[2]),
						(midpoints[1], nearVertices[trianglesIndices[2]], midpoints[0]),
						(midpoints[2], midpoints[0], nearVertices[trianglesIndices[1]]),
						(midpoints[2], midpoints[1], midpoints[0])
					);

					Renderer.Color[4][3] subQuadColors = .(
						(nearColors[colorIndices[3]], midcolors[1], midcolors[2]),
						(midcolors[1], nearColors[colorIndices[2]], midcolors[0]),
						(midcolors[2], midcolors[0], nearColors[colorIndices[1]]),
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
					for (let ti < 3) {
						activeVertexSubList.Add(subQuadVertices[ti][indexSwap[1]]);
						activeVertexSubList.Add(subQuadVertices[ti][1]);
						activeVertexSubList.Add(subQuadVertices[ti][indexSwap[0]]);

						activeColorSubList.Add(subQuadColors[ti][indexSwap[1]]);
						activeColorSubList.Add(subQuadColors[ti][1]);
						activeColorSubList.Add(subQuadColors[ti][indexSwap[0]]);

						quad = quadSet + 1 + subQuadIndexRotation[ti];
						partialUV = quad.GetVramPartialUV();
						let quadRotation = quad.GetQuadRotation();

						triangleUV[0] = .(partialUV.left, partialUV.rightY);
						triangleUV[1] = .(partialUV.right, partialUV.rightY);
						triangleUV[2] = .(partialUV.right, partialUV.leftY);
						triangleUV[3] = .(partialUV.left, partialUV.leftY);

						rotatedTriangleUV = .(
							triangleUV[(3 - (textureRotation + quadRotation)) & 3],
							triangleUV[(2 - (textureRotation + quadRotation)) & 3],
							triangleUV[(0 - (textureRotation + quadRotation)) & 3]
						);
						
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[1]]);
						activeUvSubList.Add(rotatedTriangleUV[1]);
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[0]]);
					}

					// Center triangle
					activeVertexSubList.Add(subQuadVertices[3][indexSwap[1]]);
					activeVertexSubList.Add(subQuadVertices[3][1]);
					activeVertexSubList.Add(subQuadVertices[3][indexSwap[0]]);

					activeColorSubList.Add(subQuadColors[3][indexSwap[1]]);
					activeColorSubList.Add(subQuadColors[3][1]);
					activeColorSubList.Add(subQuadColors[3][indexSwap[0]]);

					quad = quadSet + 1 + subQuadIndexRotation[0];
					partialUV = quad.GetVramPartialUV();
					let quadRotation = quad.GetQuadRotation();

					triangleUV[0] = .(partialUV.left, partialUV.rightY);
					triangleUV[1] = .(partialUV.right, partialUV.rightY);
					triangleUV[2] = .(partialUV.right, partialUV.leftY);
					triangleUV[3] = .(partialUV.left, partialUV.leftY);

					rotatedTriangleUV = .(
						triangleUV[(0 - (textureRotation + quadRotation)) & 3],
						triangleUV[(2 - (textureRotation + quadRotation)) & 3],
						triangleUV[(1 - (textureRotation + quadRotation)) & 3]
					);

					activeUvSubList.Add(rotatedTriangleUV[indexSwap[1]]);
					activeUvSubList.Add(rotatedTriangleUV[1]);
					activeUvSubList.Add(rotatedTriangleUV[indexSwap[0]]);

					activeNearFaceIndices.Add(i);
					activeNearTextureIndices.Add(textureIndex);
				} else {
					// Low quality textures
					int8[4] indexSwap = flipSide ? .(1,0,3,2) : .(0,1,2,3);

					activeNearMeshIndices.Add(trianglesIndices[indexSwap[0]]);
					activeNearMeshIndices.Add(trianglesIndices[2]);
					activeNearMeshIndices.Add(trianglesIndices[indexSwap[1]]);
					
					activeNearMeshIndices.Add(trianglesIndices[indexSwap[2]]);
					activeNearMeshIndices.Add(trianglesIndices[0]);
					activeNearMeshIndices.Add(trianglesIndices[indexSwap[3]]);

					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[0]]]);
					activeVertexList.Add(nearVertices[trianglesIndices[2]]);
					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[1]]]);
					
					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[2]]]);
					activeVertexList.Add(nearVertices[trianglesIndices[0]]);
					activeVertexList.Add(nearVertices[trianglesIndices[indexSwap[3]]]);

					activeColorList.Add(nearColors[colorIndices[indexSwap[0]]]);
					activeColorList.Add(nearColors[colorIndices[2]]);
					activeColorList.Add(nearColors[colorIndices[indexSwap[1]]]);
					
					activeColorList.Add(nearColors[colorIndices[indexSwap[2]]]);
					activeColorList.Add(nearColors[colorIndices[0]]);
					activeColorList.Add(nearColors[colorIndices[indexSwap[3]]]);
					
					activeUvList.Add(triangleUV[indexSwap[0]]);
					activeUvList.Add(triangleUV[2]);
					activeUvList.Add(triangleUV[indexSwap[1]]);
					
					activeUvList.Add(triangleUV[indexSwap[2]]);
					activeUvList.Add(triangleUV[0]);
					activeUvList.Add(triangleUV[indexSwap[3]]);
					
					// High quality textures
					Vector[5] midpoints = ?;
					midpoints[0] = (nearVertices[trianglesIndices[0]] + nearVertices[trianglesIndices[3]]) / 2;
					midpoints[1] = (nearVertices[trianglesIndices[1]] + nearVertices[trianglesIndices[2]]) / 2;
					midpoints[2] = (nearVertices[trianglesIndices[2]] + nearVertices[trianglesIndices[3]]) / 2;
					midpoints[3] = (nearVertices[trianglesIndices[0]] + nearVertices[trianglesIndices[1]]) / 2;
					midpoints[4] = (midpoints[0] + midpoints[1]) / 2;

					Renderer.Color[5] midcolors = ?;
					midcolors[0] = Renderer.Color.Lerp(nearColors[colorIndices[0]], nearColors[colorIndices[3]], 0.5f);
					midcolors[1] = Renderer.Color.Lerp(nearColors[colorIndices[1]], nearColors[colorIndices[2]], 0.5f);
					midcolors[2] = Renderer.Color.Lerp(nearColors[colorIndices[2]], nearColors[colorIndices[3]], 0.5f);
					midcolors[3] = Renderer.Color.Lerp(nearColors[colorIndices[0]], nearColors[colorIndices[1]], 0.5f);
					midcolors[4] = Renderer.Color.Lerp(midcolors[0], midcolors[1], 0.5f);

					Vector[4][4] subQuadVertices = .(
						.(midpoints[0], midpoints[4], midpoints[2], nearVertices[trianglesIndices[3]]),
						.(midpoints[4], midpoints[1], nearVertices[trianglesIndices[2]], midpoints[2]),
						.(nearVertices[trianglesIndices[0]], midpoints[3], midpoints[4], midpoints[0]),
						.(midpoints[3], nearVertices[trianglesIndices[1]], midpoints[1], midpoints[4]),
					);

					Renderer.Color[4][4] subQuadColors = .(
						.(midcolors[0], midcolors[4], midcolors[2], nearColors[colorIndices[3]]),
						.(midcolors[4], midcolors[1], nearColors[colorIndices[2]], midcolors[2]),
						.(nearColors[colorIndices[0]], midcolors[3], midcolors[4], midcolors[0]),
						.(midcolors[3], nearColors[colorIndices[1]], midcolors[1], midcolors[4]),
					);

					for (let qi < 4) {
						activeVertexSubList.Add(subQuadVertices[qi][indexSwap[0]]);
						activeVertexSubList.Add(subQuadVertices[qi][2]);
						activeVertexSubList.Add(subQuadVertices[qi][indexSwap[1]]);
						
						activeVertexSubList.Add(subQuadVertices[qi][indexSwap[2]]);
						activeVertexSubList.Add(subQuadVertices[qi][0]);
						activeVertexSubList.Add(subQuadVertices[qi][indexSwap[3]]);

						activeColorSubList.Add(subQuadColors[qi][indexSwap[0]]);
						activeColorSubList.Add(subQuadColors[qi][2]);
						activeColorSubList.Add(subQuadColors[qi][indexSwap[1]]);

						activeColorSubList.Add(subQuadColors[qi][indexSwap[2]]);
						activeColorSubList.Add(subQuadColors[qi][0]);
						activeColorSubList.Add(subQuadColors[qi][indexSwap[3]]);

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
							if (Emulator.installment == .SpyroTheDragon) {
								Swap!(rotatedTriangleUV[0], rotatedTriangleUV[1]);
								Swap!(rotatedTriangleUV[2], rotatedTriangleUV[3]);
							} else {
								Swap!(rotatedTriangleUV[0], rotatedTriangleUV[2]);
							}
						}
						
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[0]]);
						activeUvSubList.Add(rotatedTriangleUV[2]);
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[1]]);
	
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[2]]);
						activeUvSubList.Add(rotatedTriangleUV[0]);
						activeUvSubList.Add(rotatedTriangleUV[indexSwap[3]]);
					}

					activeNearFaceIndices.Add(i);
					activeNearFaceIndices.Add(i);
					activeNearTextureIndices.Add(textureIndex);
					activeNearTextureIndices.Add(textureIndex);
				}
			}

			Vector[] v = new .[vertexList.Count];
			Vector[] n = new .[vertexList.Count];
			Renderer.Color4[] c = new .[vertexList.Count];
			float[][2] u = new .[vertexList.Count];

			for (let i < vertexList.Count) {
				v[i] = vertexList[i];
				n[i] = .(0,0,1);
				c[i] = colorList[i];
				u[i] = uvList[i];
			}

			nearMesh = new .(v, u, n, c);

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
			
			nearMeshSubdivided = new .(v, u, n, c);

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

			nearMeshTransparent = new .(v, u, n, c);

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

			nearMeshTransparentSubdivided = new .(v, u, n, c);
		}
	
		// Derived from Spyro: Ripto's Rage
		// Far [80028c2c]
		// Near [80024664]
		public static VectorInt UnpackVertex(uint32 packedVertex) {
			VectorInt vertex = ?;
	
			vertex.x = (.)(packedVertex >> 21);
			vertex.y = (.)(packedVertex >> 10 & 0x7ff);
			vertex.z = (.)((packedVertex & 0x3ff) << 1);
	
			return vertex;
		}

		public NearFace GetNearFace(int faceIndex) {
			NearFace face = ?;
			Emulator.Address<NearFace> faceAddress = (.)address + 0x1c +
				((int)metadata.farVertexCount + (int)metadata.farColorCount + (int)metadata.farFaceCount * 2 + // Pass over all far data
				(int)metadata.nearVertexCount + (int)metadata.nearColorCount * 2 + // Pass over previous near data
				faceIndex * 4) * 4;// Index the face
			Emulator.ReadFromRAM(faceAddress, &face, sizeof(NearFace));
			return face;
		}
		
		public void DrawFar() {
			Matrix scale = .Scale(16, 16, Emulator.installment == .SpyroTheDragon ? 8 : 16);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			farMesh.Draw();
		}
		
		public void DrawNear() {
			Matrix scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMesh.Draw();
		}

		public void DrawNearTransparent() {
			Matrix scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshTransparent.Draw();
		}

		public void DrawNearSubdivided() {
			Matrix scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshSubdivided.Draw();
		}

		public void DrawNearTransparentSubdivided() {
			Matrix scale = .Scale(16, 16, verticalScale);
			Renderer.SetModel(.((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), scale);
			nearMeshTransparentSubdivided.Draw();
		}
	}
}
