using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class Terrain {
		public TerrainCollision collision ~ delete _;
		public TerrainRegion[] visualMeshes;
		public RegionAnimation[] animations;
		public static TextureLOD[] texturesLODs;
		public static TextureLOD1[] texturesLODs1;
		public static Texture terrainTexture;
		public TextureScroller[] textureScrollers;

		public enum RenderMode {
			Collision,
			Near,
			Far
		}
		public RenderMode renderMode = .Collision;
		public bool wireframe;
		public int drawnRegion = -1;

		public this() {
			Emulator.Address address = ?;
			Emulator.collisionDataPointers[(int)Emulator.rom].Read(&address);
			Emulator.Address deformAddress = ?;
			Emulator.collisionDeformDataPointers[(int)Emulator.rom].Read(&deformAddress);
			collision = new .(address, deformAddress);

			Reload();
			ReloadAnimations();
		}

		public ~this() {
			DeleteContainerAndItems!(visualMeshes);

			if (animations != null) {
				for (var item in animations) {
					item.Dispose();
				}
			}
			delete animations;
			delete terrainTexture;
			delete texturesLODs;
			delete texturesLODs1;
			delete textureScrollers;
		}

		public void Reload() {
			delete terrainTexture;
			delete textureScrollers;

			uint32[] textureBuffer = new .[(1024 * 4) * 512](0,); // VRAM but four times wider

			// Get max amount of possible textures
			if (Emulator.installment == .SpyroTheDragon) {
				delete texturesLODs1;
				Emulator.Address<TextureLOD1> textureDataAddress = ?;
				Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
				texturesLODs1 = new .[128];
				textureDataAddress.ReadArray(&texturesLODs1[0], 128);
			} else {
				delete texturesLODs;
				Emulator.Address<TextureLOD> textureDataAddress = ?;
				Emulator.textureDataPointers[(int)Emulator.rom].Read(&textureDataAddress);
				texturesLODs = new .[128];
				textureDataAddress.ReadArray(&texturesLODs[0], 128);
			}

			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> sceneDataRegionArrayAddress = ?;
			let sceneDataRegionArrayPointer = Emulator.sceneRegionPointers[(int)Emulator.rom];
			sceneDataRegionArrayPointer.Read(&sceneDataRegionArrayAddress);
			uint32 sceneRegionCount = ?;
			Emulator.ReadFromRAM(sceneDataRegionArrayPointer + 4, &sceneRegionCount, 4);

			// Remove any existing parsed data
			DeleteContainerAndItems!(visualMeshes);

			// Parse all terrain regions
			let usedTextureIndices = new List<int>(); // Also get all used texture indices while we are at it

			visualMeshes = new .[sceneRegionCount];

			Emulator.Address[] sceneDataRegionAddresses = new .[sceneRegionCount];
			sceneDataRegionArrayAddress.ReadArray(&sceneDataRegionAddresses[0], sceneRegionCount);
			for (let regionIndex < sceneRegionCount) {
				visualMeshes[regionIndex] = new .(sceneDataRegionAddresses[regionIndex]);

				for (let textureIndex in visualMeshes[regionIndex].usedTextureIndices) {
					let usedIndex = usedTextureIndices.FindIndex(scope (x) => x == textureIndex);
					if (usedIndex == -1) {
						usedTextureIndices.Add(textureIndex);
					}
				}
			}
			delete sceneDataRegionAddresses;

			// Convert any used VRAM textures for previewing
			for (let usedTextureIndex in usedTextureIndices) {
				TextureQuad* quad = ?;
				int quadCount = ?;
				if (Emulator.installment == .SpyroTheDragon) {
					quad = &Terrain.texturesLODs1[usedTextureIndex].D1;
					quadCount = 5;//21;
				} else {
					quad = &Terrain.texturesLODs[usedTextureIndex].nearQuad;
					quadCount = 6;
				}
				
				for (let i < quadCount) {
					let mode = quad.texturePage & 0x80 > 0;
					let pixelWidth = mode ? 2 : 1;
					let pageCoords = quad.GetPageCoordinates();
					let vramPageCoords = (pageCoords.x * 64) + ((pageCoords.y * 256) * 1024);
					let vramCoords = vramPageCoords * 4 + ((int)quad.left * pixelWidth + (int)quad.leftSkew * 1024 * 4);

					let quadTexture = quad.GetTextureData();
					let width = mode ? 64 : 32;
					for (let x < width) {
						for (let y < 32) {
							textureBuffer[(vramCoords + x + y * 1024 * 4)] = quadTexture[x / pixelWidth + y * 32];
						}
					}
					delete quadTexture;
					quad++;
				}
			}
			delete usedTextureIndices;

			terrainTexture = new .(1024 * 4, 512, OpenGL.GL.GL_SRGB_ALPHA, OpenGL.GL.GL_RGBA, &textureBuffer[0]);
			terrainTexture.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

			Texture.Unbind();
			delete textureBuffer;

			// Scrolling textures
			let textureScrollerPointer = Emulator.textureScrollerPointers[(int)Emulator.rom];
			uint32 textureScrollerCount = ?;
			Emulator.ReadFromRAM(textureScrollerPointer - 4, &textureScrollerCount, 4);
			textureScrollers = new .[textureScrollerCount];
			if (textureScrollerCount > 0) {
				Emulator.Address<Emulator.Address> textureScrollerArrayAddress = ?;
				textureScrollerPointer.Read(&textureScrollerArrayAddress);
	
				Emulator.Address[] textureScrollerAddresses = new .[textureScrollerCount];
				textureScrollerArrayAddress.ReadArray(&textureScrollerAddresses[0], textureScrollerCount);
				for (let i < textureScrollerCount) {
					textureScrollers[i] = .(textureScrollerAddresses[i]);
				}
				delete textureScrollerAddresses;
			}

			// Delete animations as the new loaded mesh may be incompatible
			if (animations != null) {
				for (let item in animations) {
					item.Dispose();
				}
				DeleteAndNullify!(animations);
			}

			/*Emulator.Address waterRegionArrayPointer = ?;
			Emulator.waterRegionArrayPointers[(int)Emulator.rom].Read(&waterRegionArrayPointer);
			uint32 waterRegionOffset = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer, &waterRegionOffset, 4);
			uint32 waterRegionCount = ?;
			Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset, &waterRegionCount, 4);
			(uint8 regionIndex, uint8, uint8, uint8)[] waterData = new .[waterRegionCount];
			if (waterRegionCount > 0) {
				Emulator.ReadFromRAM(waterRegionArrayPointer + waterRegionOffset + 4, &waterData[0], waterRegionCount * 4);
				// Must be for the wavy animation
			}
			delete waterData;*/
		}

		public void Update() {
			if (renderMode == .Collision) {
				collision.Update();
			} else {
				if (animations != null) {
					for (let animation in animations) {
						animation.Update();
					}
				}
			}

			if (renderMode == .Near) {
				float[4][2] triangleUV = ?;

				for (let textureScroller in textureScrollers) {
					textureScroller.Update();
					let textureIndex = textureScroller.textureIndex;

					TextureQuad nearQuad = ?;
					if (Emulator.installment == .SpyroTheDragon) {
						nearQuad = Terrain.texturesLODs1[textureIndex].D1;
					} else {
						nearQuad = Terrain.texturesLODs[textureIndex].nearQuad;
					}
					let partialUV = nearQuad.GetVramPartialUV();
					const let quadSize = TextureQuad.quadSize;

					triangleUV[0] = .(partialUV.right, partialUV.rightY - quadSize);
					triangleUV[1] = .(partialUV.left, partialUV.leftY);
					triangleUV[2] = .(partialUV.left, partialUV.leftY + quadSize);
					triangleUV[3] = .(partialUV.right, partialUV.rightY);

					var opaqueMeshModified = false;
					var transparentMeshModified = false;
					for (let terrainRegion in visualMeshes) {
						// Opaque Update
						for (var triangleIndex = 0; triangleIndex < terrainRegion.nearTextureIndices.Count; triangleIndex++) {
							let vertexIndex = triangleIndex * 3;
							if (terrainRegion.nearTextureIndices[triangleIndex] == textureIndex) {
								opaqueMeshModified = true;

								TerrainRegion.NearFace regionFace = terrainRegion.nearFaces[terrainRegion.nearFaceIndices[triangleIndex]];
								let textureRotation = regionFace.renderInfo.rotation;

								if (regionFace.isTriangle) {
									float[3][2] rotatedTriangleUV = .(
										triangleUV[(0 - textureRotation) & 3],
										triangleUV[(1 - textureRotation) & 3],
										triangleUV[(2 - textureRotation) & 3]
										);
	
									if (regionFace.flipped) {
										terrainRegion.nearMesh.uvs[0 + vertexIndex] = rotatedTriangleUV[2];
										terrainRegion.nearMesh.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
										terrainRegion.nearMesh.uvs[2 + vertexIndex] = rotatedTriangleUV[1];
									} else {
										terrainRegion.nearMesh.uvs[0 + vertexIndex] = rotatedTriangleUV[1];
										terrainRegion.nearMesh.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
										terrainRegion.nearMesh.uvs[2 + vertexIndex] = rotatedTriangleUV[2];
									}
								} else {
									if (regionFace.flipped) {
										Swap!(triangleUV[0], triangleUV[1]);
										Swap!(triangleUV[2], triangleUV[3]);
									}

									terrainRegion.nearMesh.uvs[0 + vertexIndex] = triangleUV[0];
									terrainRegion.nearMesh.uvs[1 + vertexIndex] = triangleUV[3];
									terrainRegion.nearMesh.uvs[2 + vertexIndex] = triangleUV[1];

									terrainRegion.nearMesh.uvs[3 + vertexIndex] = triangleUV[1];
									terrainRegion.nearMesh.uvs[4 + vertexIndex] = triangleUV[3];
									terrainRegion.nearMesh.uvs[5 + vertexIndex] = triangleUV[2];

									triangleIndex++;
								}
							}
						}

						// Transparent Update
						for (var triangleIndex = 0; triangleIndex < terrainRegion.nearFaceTransparentIndices.Count; triangleIndex++) {
							transparentMeshModified = true;

							let vertexIndex = triangleIndex * 3;
							if (terrainRegion.nearTextureTransparentIndices[triangleIndex] == textureIndex) {
								TerrainRegion.NearFace regionFace = terrainRegion.nearFaces[terrainRegion.nearFaceTransparentIndices[triangleIndex]];
								let textureRotation = regionFace.renderInfo.rotation;

								if (regionFace.isTriangle) {
									float[3][2] rotatedTriangleUV = .(
										triangleUV[(0 - textureRotation) & 3],
										triangleUV[(1 - textureRotation) & 3],
										triangleUV[(2 - textureRotation) & 3]
										);

									if (regionFace.flipped) {
										terrainRegion.nearMeshTransparent.uvs[0 + vertexIndex] = rotatedTriangleUV[2];
										terrainRegion.nearMeshTransparent.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
										terrainRegion.nearMeshTransparent.uvs[2 + vertexIndex] = rotatedTriangleUV[1];
									} else {
										terrainRegion.nearMeshTransparent.uvs[0 + vertexIndex] = rotatedTriangleUV[1];
										terrainRegion.nearMeshTransparent.uvs[1 + vertexIndex] = rotatedTriangleUV[0];
										terrainRegion.nearMeshTransparent.uvs[2 + vertexIndex] = rotatedTriangleUV[2];
									}
								} else {
									if (regionFace.flipped) {
										Swap!(triangleUV[0], triangleUV[1]);
										Swap!(triangleUV[2], triangleUV[3]);
									}

									terrainRegion.nearMeshTransparent.uvs[0 + vertexIndex] = triangleUV[0];
									terrainRegion.nearMeshTransparent.uvs[1 + vertexIndex] = triangleUV[3];
									terrainRegion.nearMeshTransparent.uvs[2 + vertexIndex] = triangleUV[1];

									terrainRegion.nearMeshTransparent.uvs[3 + vertexIndex] = triangleUV[1];
									terrainRegion.nearMeshTransparent.uvs[4 + vertexIndex] = triangleUV[3];
									terrainRegion.nearMeshTransparent.uvs[5 + vertexIndex] = triangleUV[2];

									triangleIndex++;
								}
							}
						}

						if (opaqueMeshModified) {
							terrainRegion.nearMesh.SetDirty();
						}
						if (transparentMeshModified) {
							terrainRegion.nearMeshTransparent.SetDirty();
						}
					}
				}
			}

			
			for (let terrainRegion in visualMeshes) {
				terrainRegion.nearMesh.Update();
				terrainRegion.nearMeshTransparent.Update();
			}
		}

		public void Draw() {
			Renderer.SetTint(.(255,255,255));
			Renderer.BeginSolid();

			if (wireframe) {
				Renderer.BeginWireframe();
			}

			switch (renderMode) {
				case .Far : {
					if (drawnRegion > -1) {
						visualMeshes[drawnRegion].DrawFar();
					} else {
						for (let visualMesh in visualMeshes) {
							visualMesh.DrawFar();
						}
					}
				}
				case .Near : {
					Renderer.BeginRetroShading();

					if (drawnRegion > -1) {
						visualMeshes[drawnRegion].DrawNear();
					} else {
						terrainTexture.Bind();

						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNear();
						}
						
						GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
						GL.glDepthMask(GL.GL_FALSE);  

						for (let visualMesh in visualMeshes) {
							visualMesh.DrawNearTransparent();
						}

						GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
						GL.glDepthMask(GL.GL_TRUE);  

						Renderer.whiteTexture.Bind();

					}

					Renderer.BeginDefaultShading();
				}
				case .Collision : {
					collision.Draw(wireframe);
				}
			}
				
			// Restore polygon mode to default
			Renderer.BeginSolid();
		}

		void ReloadAnimations() {
			uint32 count = ?;
			if (Emulator.installment == .SpyroTheDragon) {
				count = 0; // Ignore animation for now...
			} else {
				Emulator.ReadFromRAM(Emulator.sceneRegionDeformPointers[(int)Emulator.rom] - 4, &count, 4);
			}

			delete animations;
			animations = new .[count];

			let animationPointers = scope Emulator.Address[count];
			Emulator.ReadFromRAM(Emulator.terrainAnimationPointerArrayAddress, animationPointers.CArray(), 4 * count);

			for (let animationIndex < count) {
				let animation = &animations[animationIndex];

				*animation = .(animationPointers[animationIndex]);
				animation.Reload(visualMeshes);
			}
		}
	}
}