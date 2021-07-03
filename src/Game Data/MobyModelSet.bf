using System;
using System.Collections;

namespace SpyroScope {
	class MobyModelSet {
		bool animated;

		public Mesh[] texturedModels ~ DeleteContainerAndItems!(_);
		public Mesh[] solidModels ~ DeleteContainerAndItems!(_);
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
			}
		}

		// Derived from Spyro: Ripto's Rage [80044dcc]
		void GenerateModelFromAnimated(Emulator.Address modelSetAddress) {
			List<Vector3> activeVertices;
			List<Renderer.Color> activeColors;
			
			List<Vector3> solidVertices = scope .();
			List<Renderer.Color> solidColors = scope .();
			List<Vector3> texturedVertices = scope .();
			List<Vector2> textureUVs = scope .();
			List<Renderer.Color> textureColors = scope .();

			Emulator.Address modelMetadataAddress = ?;
			Emulator.active.ReadFromRAM(modelSetAddress + 4 * 15, &modelMetadataAddress, 4);

			Emulator.Address vertexDataAddress = ?;
			Emulator.Address faceDataAddress = ?;
			Emulator.Address colorDataAddress = ?;
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 3, &vertexDataAddress, 4);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 4, &faceDataAddress, 4);
			Emulator.active.ReadFromRAM(modelMetadataAddress + 4 * 5, &colorDataAddress, 4);

			/*uint32[] packedVertices = scope .[modelMetadata.vertexCount];
			Emulator.active.ReadFromRAM(modelDataAddress + 0x10, &packedVertices[0], 4 * modelMetadata.vertexCount);

			Renderer.Color4[] colors = scope .[modelMetadata.colorCount];
			Emulator.active.ReadFromRAM(modelDataAddress + modelMetadata.colorDataOffset, &colors[0], 4 * modelMetadata.colorCount);*/
			
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

				let materialMode = extraData & 0b110;

				if (hasTextureData) {
					activeVertices = texturedVertices;
					activeColors = textureColors;
				} else {
					activeVertices = solidVertices;
					activeColors = solidColors;
					/*switch (materialMode) {
						case 0:
							activeVertices = solidVertices;
							activeColors = solidColors;
						
						default:
							activeVertices = shinyVertices;
							activeColors = shinyColors;
					}*/
				}

				uint32 vd = ?;
				Emulator.active.ReadFromRAM(vertexDataAddress + (uint32)triangleIndices[1] * 4, &vd, 4);
				triangleVertices[0] = UnpackAnimatedVertex(vd);//packedVertices[triangleIndices[0]]);
				Emulator.active.ReadFromRAM(vertexDataAddress + (uint32)triangleIndices[2] * 4, &vd, 4);
				triangleVertices[1] = UnpackAnimatedVertex(vd);//packedVertices[triangleIndices[1]]);
				Emulator.active.ReadFromRAM(vertexDataAddress + (uint32)triangleIndices[3] * 4, &vd, 4);
				triangleVertices[2] = UnpackAnimatedVertex(vd);//packedVertices[triangleIndices[2]]);

				// Derived from Spyro: Ripto's Rage [80047a98]
				colorIndices[0] = extraData >> 10 & 0x7f; //((packedColorIndex >> 8) & 0x1fc) >> 2;
				colorIndices[1] = extraData >> 17 & 0x7f; //((packedColorIndex >> 15) & 0x1fc) >> 2;
				colorIndices[2] = extraData >> 24 & 0x7f; //((packedColorIndex >> 22) & 0x1fc) >> 2;

				if (triangleIndices[0] == triangleIndices[1]) {
					activeVertices.Add(triangleVertices[2]);
					activeVertices.Add(triangleVertices[1]);
					activeVertices.Add(triangleVertices[0]);

					if (materialMode == 0) {
						Renderer.Color cd = ?;
						Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[2] * 4, &cd, 3);
						activeColors.Add(cd);//activeColors.Add(colors[colorIndices[2]]);
						Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[1] * 4, &cd, 3);
						activeColors.Add(cd);//activeColors.Add(colors[colorIndices[1]]);
						Emulator.active.ReadFromRAM(colorDataAddress + (uint32)colorIndices[0] * 4, &cd, 3);
						activeColors.Add(cd);//activeColors.Add(colors[colorIndices[0]]);
					} else {
						activeColors.Add(.(255,255,255));
						activeColors.Add(.(255,255,255));
						activeColors.Add(.(255,255,255));
					}
				} else {
					Emulator.active.ReadFromRAM(vertexDataAddress + (uint32)triangleIndices[0] * 4, &vd, 4);
					triangleVertices[3] = UnpackAnimatedVertex(vd);//packedVertices[triangleIndices[3]]);
					
					activeVertices.Add(triangleVertices[2]);
					activeVertices.Add(triangleVertices[0]);
					activeVertices.Add(triangleVertices[1]);
					
					activeVertices.Add(triangleVertices[1]);
					activeVertices.Add(triangleVertices[0]);
					activeVertices.Add(triangleVertices[3]);

					colorIndices[3] = extraData >> 3 & 0x7f; //((packedColorIndex >> 1) & 0x1fc) >> 2;
					
					if (materialMode == 0) {
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
						if (triangleIndices[0] == triangleIndices[1]) {
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

			/*v = new .[shinyVertices.Count];
			n = new .[shinyVertices.Count];
			c = new .[shinyVertices.Count];

			for (let i < shinyVertices.Count) {
				v[i] = shinyVertices[i];
				c[i] = shinyColors[i];
			}

			for (var i = 0; i < shinyVertices.Count; i += 3) {
				n[i] = n[i+1] = n[i+2] = Vector3.Cross(v[i+2] - v[i+0], v[i+1] - v[i+0]);
			}
			
			shinyModels = new .[1];
			shinyModels[0] = new .(v, n, c);*/

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

		public void QueueInstance(int modelID, Renderer.Color4 color) {
			var modelID;

			if (animated) {
				modelID = 0;
			}

			texturedModels[modelID].QueueInstance();
			solidModels[modelID].QueueInstance();
			let tint = Renderer.tint;
			Renderer.SetTint(color);
			shinyModels[modelID].QueueInstance();
			Renderer.tint = tint;

			// Normally what to tint would be determined by a mode
			// but for now it will only color the shiny-like materials
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
	}
}
