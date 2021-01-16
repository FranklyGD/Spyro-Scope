using System;
using System.Collections;

namespace SpyroScope {
	class MobyModelSet {
		public Mesh[] texturedModels ~ DeleteContainerAndItems!(_);
		public Mesh[] solidModels ~ DeleteContainerAndItems!(_);

		[Ordered]
		struct ModelMetadata {
			uint8 a;
			public uint8 vertexCount;
			uint16 b;
			uint32 c;
			public uint16 triangleDataOffset;
		}

		public this(Emulator.Address modelSetAddress) {
			List<Vector3> activeVertices;

			uint32 modelCount = ?;
			Emulator.ReadFromRAM(modelSetAddress, &modelCount, 4);
			texturedModels = new .[modelCount];
			solidModels = new .[modelCount];

			Emulator.Address[] modelAddresses = scope .[modelCount];
			Emulator.ReadFromRAM(modelSetAddress + 4 * 5, &modelAddresses[0], 4 * modelCount);

			for	(let modelIndex < modelCount) {
				Emulator.Address modelDataAddress = modelAddresses[modelIndex];

				ModelMetadata modelMetadata = ?;
				Emulator.ReadFromRAM(modelDataAddress, &modelMetadata, sizeof(ModelMetadata));
	
				uint32 triangleDataSize = ?;
				Emulator.ReadFromRAM(modelDataAddress + modelMetadata.triangleDataOffset, &triangleDataSize, 4);
				
				List<Vector3> solidVertices = scope .();
				List<Vector3> texturedVertices = scope .();
				List<Vector2> textureUVs = scope .();

				activeVertices = solidVertices;
				
				uint32[] packedVertices = scope .[modelMetadata.vertexCount];
				if (modelMetadata.vertexCount > 0) {
					Emulator.ReadFromRAM(modelDataAddress + 0x10, &packedVertices[0], 4 * modelMetadata.vertexCount);
				
					uint32[4] triangleIndices = ?;
					Vector3[4] triangleVertices = ?;
	
					// Reading the model triangle information is DMA-like:
					// Per triangle information packet varies in size
					Emulator.Address scanningAddress = modelDataAddress + modelMetadata.triangleDataOffset + 4;
					Emulator.Address scanningEndAddress = scanningAddress + triangleDataSize;
					while (scanningAddress < scanningEndAddress) {
						uint32 packedTriangleIndex = ?;
						Emulator.ReadFromRAM(scanningAddress, &packedTriangleIndex, 4);
						uint32 extraData = ?;
						Emulator.ReadFromRAM(scanningAddress + 4, &extraData, 4);

						let hasTextureData = extraData & 0x80000000 > 0;

						let materialMode = extraData & 0b11;
						switch (materialMode) {
							case 2, 3: activeVertices = solidVertices;
							default: activeVertices = hasTextureData ? texturedVertices : solidVertices;
						}

						// Derived from Spyro: Ripto's Rage [80047788]
						triangleIndices[0] = packedTriangleIndex >> 7 & 0x7f; //((packedTriangleIndex >> 5) & 0x1fc) >> 2;
						triangleIndices[1] = packedTriangleIndex >> 14 & 0x7f; //((packedTriangleIndex >> 12) & 0x1fc) >> 2;
						triangleIndices[2] = packedTriangleIndex >> 21 & 0x7f; //((packedTriangleIndex >> 19) & 0x1fc) >> 2;
						triangleIndices[3] = packedTriangleIndex & 0x7f;
	
						triangleVertices[0] = UnpackVertex(packedVertices[triangleIndices[0]]);
						triangleVertices[1] = UnpackVertex(packedVertices[triangleIndices[1]]);
						triangleVertices[2] = UnpackVertex(packedVertices[triangleIndices[2]]);
	
						if (triangleIndices[0] == triangleIndices[3]) {
							activeVertices.Add(triangleVertices[2]);
							activeVertices.Add(triangleVertices[1]);
							activeVertices.Add(triangleVertices[0]);
						} else {
							triangleVertices[3] = UnpackVertex(packedVertices[triangleIndices[3]]);
							
							activeVertices.Add(triangleVertices[2]);
							activeVertices.Add(triangleVertices[0]);
							activeVertices.Add(triangleVertices[1]);
							
							activeVertices.Add(triangleVertices[1]);
							activeVertices.Add(triangleVertices[0]);
							activeVertices.Add(triangleVertices[3]);
						}


						if (hasTextureData) {
							ExtendedTextureQuad textureQuad = ?;
							Emulator.ReadFromRAM(scanningAddress + 8, &textureQuad, sizeof(ExtendedTextureQuad));

							textureQuad.Decode();

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

							scanningAddress += 4 * 5;
						} else {
							
							scanningAddress += 4 * 2;
						}
					}
				}

				Vector3[] v = new .[texturedVertices.Count];
				Vector3[] n = new .[texturedVertices.Count];
				Renderer.Color4[] c = new .[texturedVertices.Count];
				float[][2] u = new .[texturedVertices.Count];

				for (let i < texturedVertices.Count) {
					v[i] = texturedVertices[i];
					c[i] = .(255,255,255);
					u[i] = .(textureUVs[i].x, textureUVs[i].y);
				}

				for (var i = 0; i < texturedVertices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = Vector3.Cross(v[i+2] - v[i+0], v[i+1] - v[i+0]);
				}

				texturedModels[modelIndex] = new .(v, u, n, c);

				v = new .[solidVertices.Count];
				n = new .[solidVertices.Count];
				c = new .[solidVertices.Count];

				for (let i < solidVertices.Count) {
					v[i] = solidVertices[i];
					c[i] = .(255,255,255);
				}

				for (var i = 0; i < solidVertices.Count; i += 3) {
					n[i] = n[i+1] = n[i+2] = Vector3.Cross(v[i+2] - v[i+0], v[i+1] - v[i+0]);
				}

				solidModels[modelIndex] = new .(v, n, c);
			}
		}

		// Derived from Spyro: Ripto's Rage [8004757c]
		// Vertices need to be scaled by two before the model is drawn
		Vector3 UnpackVertex(uint32 packedVertex) {
			Vector3 vertex = ?;

			vertex.x = (int32)packedVertex >> 0x15;
			vertex.y = -(int32)(packedVertex << 10) >> 0x15;
			vertex.z = -((int32)(packedVertex << 20) >> 20);

			return vertex;
		}

		public void QueueInstance(int modelID) {
			texturedModels[modelID].QueueInstance();
			solidModels[modelID].QueueInstance();
		}

		public void DrawInstances() {
			VRAM.decoded.Bind();
			for (let i < texturedModels.Count) {
				texturedModels[i].DrawInstances();
			}
			
			Renderer.whiteTexture.Bind();
			for (let i < solidModels.Count) {
				solidModels[i].DrawInstances();
			}
		}
	}
}
