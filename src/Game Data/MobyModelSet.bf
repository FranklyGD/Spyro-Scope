using OpenGL;
using System;
using System.Collections;
using System.IO;

namespace SpyroScope {
	class MobyModelSet {
		bool animated;

		public Mesh[] texturedModels ~ DeleteContainerAndItems!(_);
		public Mesh[] solidModels ~ DeleteContainerAndItems!(_);
		public Mesh[] translucentModels ~ DeleteContainerAndItems!(_);
		public Mesh[] shinyModels ~ DeleteContainerAndItems!(_);

		[Ordered]
		struct ModelMetadata {
			public uint8 colorCount;
			public uint8 vertexCount;
			uint16 b;
			uint32 c;
			public uint16 triangleDataOffset, colorDataOffset;
		}

		[Ordered]
		struct AnimatedModelsMetadata {
			uint32[15] _;
			public Emulator.Address modelDataAddress;
		}

		// Derived from Spyro: Ripto's Rage [80062674]
		// TODO: Perhaps turn into proper vectors or just generate it on spot since it has clear pattern
		/// Contains a 3D matrix (5^3) of value that are used to shift a vertex or
		/// give a new starting point for a set of vertices relative to it.
		/// Each index contains a vector that is 6 off from each other centered around 0
		const uint32[125] shiftLookup = .(
			0xfe9fd3fa,0xff5fd3fa,0x001fd3fa,0x00dfd3fa,0x019fd3fa,0xfe9febfa,0xff5febfa,0x001febfa,
			0x00dfebfa,0x019febfa,0xfe8003fa,0xff4003fa,0x000003fa,0x00c003fa,0x018003fa,0xfe801bfa,
			0xff401bfa,0x00001bfa,0x00c01bfa,0x01801bfa,0xfe8033fa,0xff4033fa,0x000033fa,0x00c033fa,
			0x018033fa,0xfe9fd3fd,0xff5fd3fd,0x001fd3fd,0x00dfd3fd,0x019fd3fd,0xfe9febfd,0xff5febfd,
			0x001febfd,0x00dfebfd,0x019febfd,0xfe8003fd,0xff4003fd,0x000003fd,0x00c003fd,0x018003fd,
			0xfe801bfd,0xff401bfd,0x00001bfd,0x00c01bfd,0x01801bfd,0xfe8033fd,0xff4033fd,0x000033fd,
			0x00c033fd,0x018033fd,0xfe9fd000,0xff5fd000,0x001fd000,0x00dfd000,0x019fd000,0xfe9fe800,
			0xff5fe800,0x001fe800,0x00dfe800,0x019fe800,0xfe800000,0xff400000,0x00000000,0x00c00000,
			0x01800000,0xfe801800,0xff401800,0x00001800,0x00c01800,0x01801800,0xfe803000,0xff403000,
			0x00003000,0x00c03000,0x01803000,0xfe9fd003,0xff5fd003,0x001fd003,0x00dfd003,0x019fd003,
			0xfe9fe803,0xff5fe803,0x001fe803,0x00dfe803,0x019fe803,0xfe800003,0xff400003,0x00000003,
			0x00c00003,0x01800003,0xfe801803,0xff401803,0x00001803,0x00c01803,0x01801803,0xfe803003,
			0xff403003,0x00003003,0x00c03003,0x01803003,0xfe9fd006,0xff5fd006,0x001fd006,0x00dfd006,
			0x019fd006,0xfe9fe806,0xff5fe806,0x001fe806,0x00dfe806,0x019fe806,0xfe800006,0xff400006,
			0x00000006,0x00c00006,0x01800006,0xfe801806,0xff401806,0x00001806,0x00c01806,0x01801806,
			0xfe803006,0xff403006,0x00003006,0x00c03006,0x01803006);

		public this(Emulator.Address modelSetAddress) {
			if ((int32)modelSetAddress > 0) {
				GenerateModelFromStatic(modelSetAddress);
				animated = false;
			} else {
				GenerateModelFromAnimated(modelSetAddress);
				animated = true;
			}
		}

		void GenerateModelFromStatic(Emulator.Address modelSetAddress) {
			List<Vector3> activeVertices;
			List<Renderer.Color> activeColors;

			uint32 modelCount = ?;
			Emulator.active.ReadFromRAM(modelSetAddress, &modelCount, 4);
			texturedModels = new .[modelCount];
			solidModels = new .[modelCount];
			shinyModels = new .[modelCount];
			translucentModels = new .[modelCount];

			Emulator.Address[] modelAddresses = scope .[modelCount];
			Emulator.active.ReadFromRAM(modelSetAddress + 4 * 5, &modelAddresses[0], 4 * modelCount);

			for	(let modelIndex < modelCount) {
				Emulator.Address modelDataAddress = modelAddresses[modelIndex];

				ModelMetadata modelMetadata = ?;
				Emulator.active.ReadFromRAM(modelDataAddress, &modelMetadata, sizeof(ModelMetadata));
	
				List<Vector3> solidVertices = scope .();
				List<Renderer.Color> solidColors = scope .();
				List<Vector3> shinyVertices = scope .();
				List<Renderer.Color> shinyColors = scope .();
				List<Vector3> texturedVertices = scope .();
				List<Vector2> textureUVs = scope .();
				List<Renderer.Color> textureColors = scope .();
				
				if (modelMetadata.vertexCount > 0) {
					uint32[] packedVertices = scope .[modelMetadata.vertexCount];
					Emulator.active.ReadFromRAM(modelDataAddress + 0x10, &packedVertices[0], 4 * modelMetadata.vertexCount);

					Renderer.Color4[] colors = scope .[modelMetadata.colorCount];
					Emulator.active.ReadFromRAM(modelDataAddress + modelMetadata.colorDataOffset, &colors[0], 4 * modelMetadata.colorCount);
					
					uint16 offsets = ?;
					Emulator.active.ReadFromRAM(modelDataAddress + modelMetadata.triangleDataOffset, &offsets, 2);

					uint32[4] triangleIndices = ?;
					Vector3[4] triangleVertices = ?;
					uint32[4] colorIndices = ?;
	
					// Reading the model triangle information is DMA-like:
					// Per triangle information packet varies in size
					Emulator.Address scanningAddress = modelDataAddress + modelMetadata.triangleDataOffset + 4;
					Emulator.Address scanningEndAddress = scanningAddress + offsets;
					while (scanningAddress < scanningEndAddress) {
						uint32 packedTriangleIndex = ?;
						Emulator.active.ReadFromRAM(scanningAddress, &packedTriangleIndex, 4);
						uint32 extraData = ?;
						Emulator.active.ReadFromRAM(scanningAddress + 4, &extraData, 4);

						let hasTextureData = extraData & 0x80000000 > 0;

						let materialMode = extraData & 0b110;

						if (hasTextureData) {
							activeVertices = texturedVertices;
							activeColors = textureColors;
						} else {
							switch (materialMode) {
								case 0:
									activeVertices = solidVertices;
									activeColors = solidColors;
								
								default:
									activeVertices = shinyVertices;
									activeColors = shinyColors;
							}
						}

						// Derived from Spyro: Ripto's Rage [80047788]
						triangleIndices[0] = packedTriangleIndex >> 7 & 0x7f; //((packedTriangleIndex >> 5) & 0x1fc) >> 2;
						triangleIndices[1] = packedTriangleIndex >> 14 & 0x7f; //((packedTriangleIndex >> 12) & 0x1fc) >> 2;
						triangleIndices[2] = packedTriangleIndex >> 21 & 0x7f; //((packedTriangleIndex >> 19) & 0x1fc) >> 2;
						triangleIndices[3] = packedTriangleIndex & 0x7f; //packedTriangleIndex >> 2;
	
						triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
						triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
						triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);

						// Derived from Spyro: Ripto's Rage [80047a98]
						colorIndices[0] = extraData >> 10 & 0x7f; //((packedColorIndex >> 8) & 0x1fc) >> 2;
						colorIndices[1] = extraData >> 17 & 0x7f; //((packedColorIndex >> 15) & 0x1fc) >> 2;
						colorIndices[2] = extraData >> 24 & 0x7f; //((packedColorIndex >> 22) & 0x1fc) >> 2;
	
						if (triangleIndices[0] == triangleIndices[3]) {
							activeVertices.Add(triangleVertices[2]);
							activeVertices.Add(triangleVertices[1]);
							activeVertices.Add(triangleVertices[0]);

							if (materialMode == 0) {
								activeColors.Add(colors[colorIndices[2]]);
								activeColors.Add(colors[colorIndices[1]]);
								activeColors.Add(colors[colorIndices[0]]);
							} else {
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
							}
						} else {
							triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3]]);
							
							activeVertices.Add(triangleVertices[2]);
							activeVertices.Add(triangleVertices[0]);
							activeVertices.Add(triangleVertices[1]);
							
							activeVertices.Add(triangleVertices[1]);
							activeVertices.Add(triangleVertices[0]);
							activeVertices.Add(triangleVertices[3]);

							colorIndices[3] = extraData >> 3 & 0x7f; //((packedColorIndex >> 1) & 0x1fc) >> 2;
							
							if (materialMode == 0) {
								activeColors.Add(colors[colorIndices[2]]);
								activeColors.Add(colors[colorIndices[0]]);
								activeColors.Add(colors[colorIndices[1]]);
								
								activeColors.Add(colors[colorIndices[1]]);
								activeColors.Add(colors[colorIndices[0]]);
								activeColors.Add(colors[colorIndices[3]]);
							} else {
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
								
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
								activeColors.Add(.(255,255,255));
							}
						}

						if (hasTextureData) {
							ExtendedTextureQuad textureQuad = ?;
							Emulator.active.ReadFromRAM(scanningAddress + 8, &textureQuad, sizeof(ExtendedTextureQuad));

							textureQuad.Decode();
							
							//if (materialMode == 0) {
								if (triangleIndices[0] == triangleIndices[3]) {
									textureUVs.Add(textureQuad.GetVramUV0());
									textureUVs.Add(textureQuad.GetVramUV1());
									textureUVs.Add(textureQuad.GetVramUV2());
								} else {
									textureUVs.Add(textureQuad.GetVramUV0());
									textureUVs.Add(textureQuad.GetVramUV2());
									textureUVs.Add(textureQuad.GetVramUV1());
	
									textureUVs.Add(textureQuad.GetVramUV1());
									textureUVs.Add(textureQuad.GetVramUV2());
									textureUVs.Add(textureQuad.GetVramUV3());
								}
							//}

							scanningAddress += 4 * 5;
						} else {
							
							scanningAddress += 4 * 2;
						}
					}
				}

				Vector3[] v = new .[texturedVertices.Count];
				Vector3[] n = new .[texturedVertices.Count];
				Renderer.Color4[] c = new .[texturedVertices.Count];
				Vector2[] u = new .[texturedVertices.Count];

				for (let i < texturedVertices.Count) {
					v[i] = texturedVertices[i];
					c[i] = textureColors[i];
					u[i] = .(textureUVs[i].x, textureUVs[i].y);
				}

				for (var i = 0; i < texturedVertices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = .(0,0,1);
				}

				texturedModels[modelIndex] = new .(v, u, n, c);

				v = new .[solidVertices.Count];
				n = new .[solidVertices.Count];
				c = new .[solidVertices.Count];

				for (let i < solidVertices.Count) {
					v[i] = solidVertices[i];
					c[i] = solidColors[i];
				}

				for (var i = 0; i < solidVertices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = .(0,0,1);
				}

				solidModels[modelIndex] = new .(v, n, c);

				v = new .[shinyVertices.Count];
				n = new .[shinyVertices.Count];
				c = new .[shinyVertices.Count];

				for (let i < shinyVertices.Count) {
					v[i] = shinyVertices[i];
					c[i] = shinyColors[i];
				}

				for (var i = 0; i < shinyVertices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = Vector3.Cross(v[i+2] - v[i+0], v[i+1] - v[i+0]);
				}

				shinyModels[modelIndex] = new .(v, n, c);

				
				v = new .[0];
				n = new .[0];
				c = new .[0];

				translucentModels[modelIndex] = new .(v, n, c);
			}
		}

		// Derived from Spyro: Ripto's Rage [80044dcc]
		void GenerateModelFromAnimated(Emulator.Address modelSetAddress) {
			List<Vector3> activeVertices;
			List<Vector2> activeUVs;
			List<Renderer.Color> activeColors;
			
			List<Vector3> solidVertices = scope .();
			List<Renderer.Color> solidColors = scope .();

			List<Vector3> texturedVertices = scope .();
			List<Vector2> textureUVs = scope .();
			List<Renderer.Color> textureColors = scope .();
			
			List<Vector3> translucentVertices = scope .();
			List<Vector2> translucentUVs = scope .();
			List<Renderer.Color> translucentColors = scope .();

			Emulator.Address modelMetadataAddress = ?;
			Emulator.active.ReadFromRAM(modelSetAddress + 4 * 15, &modelMetadataAddress, 4);

			uint8 vertexShiftScale = ?;
			Emulator.active.ReadFromRAM(modelMetadataAddress + 2, &vertexShiftScale, 1);
			float scale = 1 << vertexShiftScale;

			uint8 vertexCount = ?;
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4, &vertexCount, 1);

			Emulator.Address vertexDataAddress = ?;
			Emulator.Address faceDataAddress = ?;
			Emulator.Address colorDataAddress = ?;
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 3, &vertexDataAddress, 4);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 4, &faceDataAddress, 4);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 5, &colorDataAddress, 4);
			
			Vector3[] vertices = scope .[vertexCount];
			uint32[] packedVertices = scope .[vertexCount];
			Emulator.active.ReadFromRAM(vertexDataAddress, &packedVertices[0], 4 * vertexCount);
			
			Emulator.Address dataAddress = ?;
			uint16 dataStart = ?;
			uint8 dataSize = ?;
			uint8 startingFlags = ?;
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 8, &dataAddress, 4);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 9, &dataStart, 2);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 9 + 2, &dataSize, 1);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 9 + 3, &startingFlags, 1);

			// Derived from Spyro: Ripto's Rage [800418c8]
			for (let i < vertexCount) {
				vertices[i] = UnpackVertexShift(packedVertices[i]);
			}

			bool applyNext = startingFlags & 2 > 0, appliedCurrent = false;

			int li = 0;
			Vector3 pos = .Zero, delta = .Zero;
			Emulator.Address dataScanningAddress = dataAddress + dataStart * 2;
			Emulator.Address lookupAddress = dataScanningAddress + (dataSize + ((uint32)(startingFlags & 1) << 8)) * 2;
			for (let i < vertexCount) {
				delta = vertices[i];

				appliedCurrent = applyNext;
				if (applyNext) {
					uint16[2] data = ?;
					Emulator.active.ReadFromRAM(dataScanningAddress, &data[0], 2);

					if (data[0] & 2 > 0) { // Starting vertex position
						Emulator.active.ReadFromRAM(dataScanningAddress + 2, &data[1], 2);
						pos = UnpackAnimatedVertex(*(uint32*)&data[0]);
						delta = .Zero;
	
						dataScanningAddress += 4;
					} else { // Relative vertex
						Vector3 shift;
						shift.x = ((int16)data[0] >> 10) << 1;
						shift.y = ((int16)(data[0] << 5) >> 10) << 1;
						shift.z = ((int16)(data[0] << 10) >> 11) << 2;

						pos += shift;
	
						dataScanningAddress += 2;
					}
					
					applyNext = data[0] & 1 > 0;
				}

				if (!(appliedCurrent || applyNext)) {
					uint8 lookupIndex = ?;
					Emulator.active.ReadFromRAM(lookupAddress + li, &lookupIndex, 1);

					uint32 packedShift;
					if (lookupIndex >> 1 < 125) {
						packedShift = shiftLookup[lookupIndex >> 1];
					} else {
						packedShift = 0;
					}

					if (lookupIndex & 1 > 0) {
						applyNext = true;
					}

					delta = UnpackVertexShift(packedShift + packedVertices[i]);

					li++;
				}

				pos += delta;
				vertices[i] = pos * scale;
			}

			uint16 offsets = ?;
			Emulator.active.ReadFromRAM(faceDataAddress, &offsets, 2);

			uint8[4] triangleIndices = ?;
			Vector3[4] triangleVertices = ?;
			uint32[4] colorIndices = ?;

			// Reading the model triangle information is DMA-like:
			// Per triangle information packet varies in size
			Emulator.Address scanningAddress = faceDataAddress + 4;
			Emulator.Address scanningEndAddress = scanningAddress + offsets;
			while (scanningAddress < scanningEndAddress) {
				Emulator.active.ReadFromRAM(scanningAddress, &triangleIndices, 4);
				uint32 extraData = ?;
				Emulator.active.ReadFromRAM(scanningAddress + 4, &extraData, 4);

				let hasTextureData = extraData & 0x80000000 > 0;
				
				activeUVs = textureUVs;
				if (hasTextureData) {
					activeVertices = texturedVertices;
					activeColors = textureColors;
				} else {
					activeVertices = solidVertices;
					activeColors = solidColors;
				}

				uint32 vd = ?;
				triangleVertices[0] = vertices[triangleIndices[1]];
				triangleVertices[1] = vertices[triangleIndices[2]];
				triangleVertices[2] = vertices[triangleIndices[3]];

				// Derived from Spyro: Ripto's Rage [80047a98]
				colorIndices[0] = extraData >> 10 & 0x7f; //((packedColorIndex >> 8) & 0x1fc) >> 2;
				colorIndices[1] = extraData >> 17 & 0x7f; //((packedColorIndex >> 15) & 0x1fc) >> 2;
				colorIndices[2] = extraData >> 24 & 0x7f; //((packedColorIndex >> 22) & 0x1fc) >> 2;

				if (hasTextureData) {
					ExtendedTextureQuad textureQuad = ?;
					Emulator.active.ReadFromRAM(scanningAddress + 8, &textureQuad, sizeof(ExtendedTextureQuad));

					textureQuad.Decode();

					if (textureQuad.texturePage & 0x20 > 0) {
						// The following face translucent
						activeVertices = translucentVertices;
						activeColors = translucentColors;
						activeUVs = translucentUVs;
					}

					if (triangleIndices[0] == triangleIndices[1]) {
						activeUVs.Add(textureQuad.GetVramUV0());
						activeUVs.Add(textureQuad.GetVramUV1());
						activeUVs.Add(textureQuad.GetVramUV2());
					} else {
						activeUVs.Add(textureQuad.GetVramUV0());
						activeUVs.Add(textureQuad.GetVramUV2());
						activeUVs.Add(textureQuad.GetVramUV1());

						activeUVs.Add(textureQuad.GetVramUV1());
						activeUVs.Add(textureQuad.GetVramUV2());
						activeUVs.Add(textureQuad.GetVramUV3());
					}

					scanningAddress += 4 * 5;
				} else {
					scanningAddress += 4 * 2;
				}

				if (triangleIndices[0] == triangleIndices[1]) {
					activeVertices.Add(triangleVertices[2]);
					activeVertices.Add(triangleVertices[1]);
					activeVertices.Add(triangleVertices[0]);

					Renderer.Color cd = ?;
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[2] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[2]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[1] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[1]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[0] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[0]]);
				} else {
					Emulator.active.ReadFromRAM(vertexDataAddress + (uint32)triangleIndices[0] * 4, &vd, 4);
					triangleVertices[3] = vertices[triangleIndices[0]];
					
					activeVertices.Add(triangleVertices[2]);
					activeVertices.Add(triangleVertices[0]);
					activeVertices.Add(triangleVertices[1]);
					
					activeVertices.Add(triangleVertices[1]);
					activeVertices.Add(triangleVertices[0]);
					activeVertices.Add(triangleVertices[3]);

					colorIndices[3] = extraData >> 3 & 0x7f; //((packedColorIndex >> 1) & 0x1fc) >> 2;
					
					Renderer.Color cd = ?;
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[2] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[2]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[0] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[0]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[1] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[1]]);

					
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[1] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[1]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[0] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[0]]);
					Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[3] * 4, &cd, 3);
					activeColors.Add(cd);//activeColors.Add(colors[colorIndices[3]]);
				}
			}

			Vector3[] v = new .[texturedVertices.Count];
			Vector3[] n = new .[texturedVertices.Count];
			Renderer.Color4[] c = new .[texturedVertices.Count];
			Vector2[] u = new .[texturedVertices.Count];

			for (let i < texturedVertices.Count) {
				v[i] = texturedVertices[i];
				c[i] = textureColors[i];
				u[i] = .(textureUVs[i].x, textureUVs[i].y);
			}

			for (var i = 0; i < texturedVertices.Count; i += 3) {
				n[i] = n[i+1] = n[i+2] = .(0,0,1);
			}
			
			texturedModels = new .[1];
			texturedModels[0] = new .(v, u, n, c);

			v = new .[solidVertices.Count];
			n = new .[solidVertices.Count];
			c = new .[solidVertices.Count];

			for (let i < solidVertices.Count) {
				v[i] = solidVertices[i];
				c[i] = solidColors[i];
			}

			for (var i = 0; i < solidVertices.Count; i += 3) {
				n[i] = n[i+1] = n[i+2] = .(0,0,1);
			}
			
			solidModels = new .[1];
			solidModels[0] = new .(v, n, c);

			v = new .[translucentVertices.Count];
			n = new .[translucentVertices.Count];
			c = new .[translucentVertices.Count];
			u = new .[translucentVertices.Count];

			for (let i < translucentVertices.Count) {
				v[i] = translucentVertices[i];
				c[i] = translucentColors[i];
				u[i] = .(translucentUVs[i].x, translucentUVs[i].y);
			}

			for (var i = 0; i < translucentVertices.Count; i += 3) {
				n[i] = n[i+1] = n[i+2] = .(0,0,1);
			}

			translucentModels = new .[1];
			translucentModels[0] = new .(v, u, n, c);

			v = new .[0];
			n = new .[0];
			c = new .[0];

			shinyModels = new .[1];
			shinyModels[0] = new .(v, n, c);
		}

		// Derived from Spyro: Ripto's Rage [8004757c]
		Vector3 UnpackVertex(uint32 packedVertex) {
			Vector3 vertex = ?;

			vertex.x = (int32)packedVertex >> 0x15 << 1;
			vertex.y = -(int32)(packedVertex << 10) >> 0x15 << 1;
			vertex.z = -((int32)(packedVertex << 20) >> 20) << 1;

			return vertex;
		}

		// Derived from Spyro: Ripto's Rage [80044794]
		// In the game's code, it was originally read as two shorts (two 16-bit integers)
		// Below is the reduced form of operations since the shorts share the same word (32-bit integer)
		Vector3 UnpackAnimatedVertex(uint32 packedVertex) {
			Vector3 vertex = ?;
			
			vertex.x = (int32)packedVertex >> 0x15;
			vertex.y = -(int32)(packedVertex << 0xa) >> 0x15;
			vertex.z = -(int32)((packedVertex & 0xffc) << 0x14) >> 0x14;

			return vertex;
		}

		// Derived from Spyro: Ripto's Rage [800419b0]
		Vector3 UnpackVertexShift(uint32 packedVertexShift) {
			Vector3 shift = ?;

			shift.x = (int32)packedVertexShift >> 0x15;
			shift.y = (int32)(packedVertexShift << 0xb) >> 0x15;
			shift.z = (int32)(packedVertexShift << 0x16) >> 0x15;

			return shift;
		}

		public void QueueInstance(int modelID, Renderer.Color4 color) {
			var modelID;

			if (animated) {
				modelID = 0;
			}
			
			texturedModels[modelID].QueueInstance();
			solidModels[modelID].QueueInstance();
			
			let tint = Renderer.tint;
			Renderer.tint /= 2;
			translucentModels[modelID].QueueInstance();

			Renderer.SetTint(color);
			Renderer.tint *= tint;
			shinyModels[modelID].QueueInstance();
			Renderer.tint = tint;
		}

		public void DrawInstances() {
			Renderer.BeginRetroShading();
			VRAM.decoded?.Bind();

			for (let i < texturedModels.Count) {
				texturedModels[i].DrawInstances();
			}

			Renderer.halfWhiteTexture.Bind();

			for (let i < solidModels.Count) {
				solidModels[i].DrawInstances();
			}
			
			Renderer.SetSpecular(1);

			for (let i < shinyModels.Count) {
				shinyModels[i].DrawInstances();
			}
			
			Renderer.SetSpecular(0);
			Renderer.BeginDefaultShading();
			Renderer.whiteTexture.Bind();
		}

		public void DrawInstancesTranslucent() {
			Renderer.BeginRetroShading();

			VRAM.decoded?.Bind();

			GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
			GL.glDepthMask(GL.GL_FALSE);

			for (let i < translucentModels.Count) {
				translucentModels[i].DrawInstances();
			}

			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
			GL.glDepthMask(GL.GL_TRUE);

			Renderer.BeginDefaultShading();
			Renderer.whiteTexture.Bind();
		}

		public void Export(String file, int modelIndex, float scale) {
			let netScale = scale / 1000;
			FileStream stream = new .();
			stream.Create(file);
			
			let texturedModel = texturedModels[modelIndex];
			let solidModel = solidModels[modelIndex];
			let translucentModel = translucentModels[modelIndex];
			let shinyModel = shinyModels[modelIndex];

			stream.Write("ply\nformat ascii 1.0\n");
			stream.Write(scope $"element vertex {texturedModel.vertices.Count + solidModel.vertices.Count + translucentModel.vertices.Count + shinyModel.vertices.Count}\n");
			stream.Write("property float x\nproperty float y\nproperty float z\nproperty uchar red\nproperty uchar green\nproperty uchar blue\nproperty float s\nproperty float t\n");
			stream.Write(scope $"element face {(texturedModel.indices.Count + solidModel.indices.Count + translucentModel.indices.Count + shinyModel.indices.Count) / 3}\n");
			stream.Write("property list uint8 uint32 vertex_index\n");
			stream.Write("end_header\n");

			for (let i < texturedModel.vertices.Count) {
				let v = texturedModel.vertices[i] * netScale;
				let c = texturedModel.colors[i];
				let u = texturedModel.uvs[i];
				stream.Write(scope $"{v.x} {v.y} {v.z} {c.r} {c.g} {c.b} {u.x} {1 - u.y}\n");
			}

			for (let i < solidModel.vertices.Count) {
				let v = solidModel.vertices[i] * netScale;
				let c = solidModel.colors[i];
				let u = solidModel.uvs[i];
				stream.Write(scope $"{v.x} {v.y} {v.z} {c.r} {c.g} {c.b} {u.x} {1 - u.y}\n");
			}

			for (let i < translucentModel.vertices.Count) {
				let v = translucentModel.vertices[i] * netScale;
				let c = translucentModel.colors[i];
				let u = translucentModel.uvs[i];
				stream.Write(scope $"{v.x} {v.y} {v.z} {c.r} {c.g} {c.b} {u.x} {1 - u.y}\n");
			}

			for (let i < shinyModel.vertices.Count) {
				let v = shinyModel.vertices[i] * netScale;
				let c = shinyModel.colors[i];
				let u = shinyModel.uvs[i];
				stream.Write(scope $"{v.x} {v.y} {v.z} {c.r} {c.g} {c.b} {u.x} {1 - u.y}\n");
			}

			for (var i = 0; i < texturedModel.indices.Count; i += 3) {
				let idx = &texturedModel.indices[i];
				stream.Write(scope $"3 {idx[0]} {idx[1]} {idx[2]}\n");
			}
			
			int indexOffset = texturedModel.vertices.Count;
			for (var i = 0; i < solidModel.indices.Count; i += 3) {
				let idx = &solidModel.indices[i];
				stream.Write(scope $"3 {idx[0] + indexOffset} {idx[1] + indexOffset} {idx[2] + indexOffset}\n");
			}

			indexOffset += solidModel.vertices.Count;
			for (var i = 0; i < translucentModel.indices.Count; i += 3) {
				let idx = &translucentModel.indices[i];
				stream.Write(scope $"3 {idx[0] + indexOffset} {idx[1] + indexOffset} {idx[2] + indexOffset}\n");
			}
			
			indexOffset += translucentModel.vertices.Count;
			for (var i = 0; i < shinyModel.indices.Count; i += 3) {
				let idx = &shinyModel.indices[i];
				stream.Write(scope $"3 {idx[0] + indexOffset} {idx[1] + indexOffset} {idx[2] + indexOffset}\n");
			}

			delete stream;
		}
	}
}
