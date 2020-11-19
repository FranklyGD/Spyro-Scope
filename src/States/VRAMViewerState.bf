using OpenGL;
using SDL2;
using System;

namespace SpyroScope {
	class VRAMViewerState : WindowState {
		enum RenderMode {
			Raw,
			Decoded
		}
		RenderMode renderMode;

		Texture raw ~ delete _;
		float scale = 1, scaleMagnitude = 0;
		bool expand;

		(float x, float y) viewPosition, testPosition;
		int hoveredTexturePage;
		bool panning;

		public override void Enter() {
			/*Emulator.OnSceneChanged = new => OnSceneChanged;
			Emulator.OnSceneChanging = new => OnSceneChanging;*/
			
			OnSceneChanged();
			ResetView();
		}

		public override void Exit() {
			/*delete Emulator.OnSceneChanged;
			delete Emulator.OnSceneChanging;*/


		}

		public override void Update() {
			Terrain.UpdateTextureInfo(false);
		}

		public override void DrawGUI() {
			let pixelWidth = expand ? 4 : 1;
			let width = (expand ? 512 : 1024) * pixelWidth;
			(float x, float y) size = (width, 512);

			(float x, float y) centering = ?;
			centering.x = WindowApp.width / 2;
			centering.y = WindowApp.height / 2;

			(float x, float y) workingVRAMOrigin = ?;
			(float x, float y) workingVRAMscale = ?;

			float top = centering.y - viewPosition.y * scale;
			float bottom = centering.y + (size.y - viewPosition.y) * scale;
			float left = centering.x - viewPosition.x * scale;
			float right = centering.x + (size.x - viewPosition.x) * scale;
			
			DrawUtilities.Rect(top, bottom, left, right, 0, 1, expand ? 0.5f : 0, 1, raw, .(255,255,255));
			DrawUtilities.Rect(top, bottom, left, right, 0, 1, expand ? 0.5f : 0, 1, Terrain.terrainTexture, .(255,255,255));

			WindowApp.bitmapFont.Print(scope String() .. AppendF("<{},{}>", testPosition.x, testPosition.y), .Zero, .(255,255,255));

			if (expand) {
				size.x *= 2;
			}

			for (let textureIndex < Terrain.highestUsedTextureIndex) {
				TextureQuad* quad = ?;
				int quadCount = ?;
				if (Emulator.installment == .SpyroTheDragon) {
					quad = &Terrain.texturesLODs1[textureIndex].D1;
					quadCount = 5;//21;
				} else {
					quad = &Terrain.texturesLODs[textureIndex].farQuad;
					quadCount = 6;
				}

				for (let i < quadCount) {
					let partialUVs = quad.GetVramPartialUV();

					float qtop = top + partialUVs.leftY * size.y * scale;
					float qbottom = top + partialUVs.rightY * size.y * scale;
					float qleft = left + (partialUVs.left - (expand ? 0.5f : 0)) * size.x * scale;
					float qright = left + (partialUVs.right - (expand ? 0.5f : 0)) * size.x * scale;

					Renderer.DrawLine(.(qleft, qtop, 0), .(qright, qtop, 0), .(64,64,64), .(64,64,64));
					Renderer.DrawLine(.(qleft, qbottom, 0), .(qright, qbottom, 0), .(64,64,64), .(64,64,64));
					Renderer.DrawLine(.(qleft, qtop, 0), .(qleft, qbottom, 0), .(64,64,64), .(64,64,64));
					Renderer.DrawLine(.(qright, qtop, 0), .(qright, qbottom, 0), .(64,64,64), .(64,64,64));

					switch (i) {
						case 0:
							Renderer.DrawLine(.(qleft + 4, qtop + 4, 0), .(qright - 4, qtop + 4, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(qleft + 4, qbottom - 4, 0), .(qright - 4, qbottom - 4, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(qleft + 4, qtop + 4, 0), .(qleft + 4, qbottom - 4, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(qright - 4, qtop + 4, 0), .(qright - 4, qbottom - 4, 0), .(255,64,64), .(255,64,64));
						case 1:
							Renderer.DrawLine(.(qleft + 2, qtop + 2, 0), .(qright - 2, qtop + 2, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(qleft + 2, qbottom - 2, 0), .(qright - 2, qbottom - 2, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(qleft + 2, qtop + 2, 0), .(qleft + 2, qbottom - 2, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(qright - 2, qtop + 2, 0), .(qright - 2, qbottom - 2, 0), .(64,255,64), .(64,255,64));
						case 2:
							Renderer.DrawLine(.(qleft + 4, qtop + 4, 0), .(qright, qtop + 4, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(qleft + 4, qtop + 4, 0), .(qleft + 4, qbottom, 0), .(64,64,255), .(64,64,255));
						case 3:
							Renderer.DrawLine(.(qleft, qtop + 4, 0), .(qright - 4, qtop + 4, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(qright - 4, qtop + 4, 0), .(qright - 4, qbottom, 0), .(64,64,255), .(64,64,255));
						case 4:
							Renderer.DrawLine(.(qleft + 4, qbottom - 4, 0), .(qright, qbottom - 4, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(qleft + 4, qtop, 0), .(qleft + 4, qbottom - 4, 0), .(64,64,255), .(64,64,255));
						case 5:
							Renderer.DrawLine(.(qleft, qbottom - 4, 0), .(qright - 4, qbottom - 4, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(qright - 4, qtop, 0), .(qright - 4, qbottom - 4, 0), .(64,64,255), .(64,64,255));
					}

					quad++;
				}
			}
		}

		public void OnSceneChanged() {
			delete raw;
			raw = new .(1024, 512, OpenGL.GL.GL_SRGB, OpenGL.GL.GL_RGBA, OpenGL.GL.GL_UNSIGNED_SHORT_1_5_5_5_REV, &Emulator.vramSnapshot[0]);
			raw.Bind();

			// Make the textures sample sharp
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_NEAREST);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_NEAREST);

			Texture.Unbind();
		}

		public override bool OnEvent(SDL2.SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (event.button.button == 3) {
						panning = true;
					}
				}
				case .MouseMotion : {
					if (panning) {
						var translationX = event.motion.xrel / scale;
						var translationY = event.motion.yrel / scale;

						viewPosition.x -= translationX;
						viewPosition.y -= translationY;
					} else {
						(float x, float y) centering = ?;
						centering.x = WindowApp.width / 2;
						centering.y = WindowApp.height / 2;

						testPosition.x = (WindowApp.mousePosition.x - centering.x + viewPosition.x) / (expand ? 4 : 1) + (expand ? 512 : 0);
						testPosition.y = WindowApp.mousePosition.y - centering.y + viewPosition.y;
					}
				}
				case .MouseButtonUp : {
					if (event.button.button == 3) {
						panning = false;
					}
				}
				case .MouseWheel : {
					scaleMagnitude = Math.Round((scaleMagnitude + 0.1f * (.)event.wheel.y) * 10) / 10;
				 	scale = Math.Pow(2, scaleMagnitude);

					viewPosition.x = Math.Round(viewPosition.x * scale) / scale;
					viewPosition.y = Math.Round(viewPosition.y * scale) / scale;
				}
				case .KeyDown : {
					switch (event.key.keysym.scancode) {
						case .V: windowApp.GoToState<ViewerState>();
						case .Key0: ResetView();
						case .Key1: ToggleExpandedView();
						default:
					}
				}
				default: return false;
			}
			return true;
		}

		void ResetView() {
			let pixelWidth = expand ? 4 : 1;
			let width = (expand ? 512 : 1024) * pixelWidth;
			(float x, float y) size = (width, 512);

			viewPosition.x = size.x / 2;
			viewPosition.y = size.y / 2;
		}

		void ToggleExpandedView() {
			expand = !expand;

			if (expand) {
				if (viewPosition.x > 512) {
					viewPosition.x = (viewPosition.x - 512) * 4;
				}
			} else {
				viewPosition.x = viewPosition.x / 4 + 512;
			}
		}
	}
}
