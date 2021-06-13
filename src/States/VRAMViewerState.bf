using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.IO;

namespace SpyroScope {
	class VRAMViewerState : WindowState {
		int blinkerTime = 0;
		bool spritesDecoded;

		enum TextureType {
			Terrain,
			Object,
			Sprite
		}

		enum CLUTType {
			Normal,
			Gradient
		}

		struct CLUTReference {
			public int location;
			public int width;
			public CLUTType type;
			public TextureType category;
			public List<int> references;
		}

		List<CLUTReference> cluts = new .();

		enum RenderMode {
			Raw,
			Decoded
		}
		RenderMode renderMode;

		enum ClickMode {
			Normal,
			Export,
			Alter
		}
		ClickMode clickMode;

		float scale = 1, scaleMagnitude = 0;
		bool expand;
		Vector2 vramOrigin;
		(float width, float height) vramSize;

		Vector2 viewPosition, testPosition;
		int hoveredTexturePage = -1, hoveredCLUTIndex = -1, hoveredTextureIDIndex = -1;
		int selectedTexturePage = -1, selectedCLUTIndex = -1, selectedTextureIDIndex = -1;
		bool panning;
		
		// Timestamps
		DateTime lastUpdatedSceneChange;

		public this() {
			VRAM.OnSnapshotTaken.Add(new => OnNewSnapshot);
		}

		public ~this() {
			for (let clutReference in cluts) {
				delete clutReference.references;
			}

			delete cluts;
		}

		public override void Enter() {
			Renderer.clearColor = .(0,0,0);
			ResetView();
		}

		public override void Exit() {

		}

		public override void Update() {
			Emulator.active.FetchImportantData();

			if (Emulator.active.lastSceneChange > lastUpdatedSceneChange) {
				OnSceneChanged();
			}

			Terrain.UpdateTextureInfo(false);
			blinkerTime = (blinkerTime + 1) % 50;

			if (VRAM.upToDate) {
				Decode();
			}
		}

		public override void DrawGUI() {
			let pixelWidth = expand ? 4 : 1;
			vramSize.width = (expand ? 512 : 1024) * pixelWidth;
			vramSize.height = 512;

			let right = vramOrigin.x + vramSize.width * scale;
			let bottom = vramOrigin.y + vramSize.height * scale;

			if (VRAM.upToDate) {
				DrawUtilities.Rect(vramOrigin.y, bottom, vramOrigin.x, right, 0, 1, expand ? 0.5f : 0, 1, VRAM.raw, .(255,255,255));
				DrawUtilities.Rect(vramOrigin.y, bottom, vramOrigin.x, right, 0, 1, expand ? 0.5f : 0, 1, VRAM.decoded, .(255,255,255));
			}

			for (let textureIndex in Terrain.usedTextureIndices) {
				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;

				for (let quadIndex < quadCount) {
					let i = textureIndex * quadCount + quadIndex;
					let quad = Terrain.textures[i];
					let partialUVs = quad.GetVramPartialUV();

					Rect quadRect;
					quadRect.start = UVToScreen(partialUVs.left, partialUVs.leftY);
					quadRect.end = UVToScreen(partialUVs.right, partialUVs.rightY);

					let modifiedQuadIndex = quadIndex + (Emulator.active.installment == .SpyroTheDragon ? 1 : 0);
					switch (modifiedQuadIndex) {
						case 0:
							quadRect.left += 4;
							quadRect.top += 4;
							quadRect.right -= 4;
							quadRect.bottom -= 4;

							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.right, quadRect.top, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(quadRect.left, quadRect.bottom, 0), .(quadRect.right, quadRect.bottom, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.left, quadRect.bottom, 0), .(255,64,64), .(255,64,64));
							Renderer.DrawLine(.(quadRect.right, quadRect.top, 0), .(quadRect.right, quadRect.bottom, 0), .(255,64,64), .(255,64,64));
						case 1:
							quadRect.left += 2;
							quadRect.top += 2;
							quadRect.right -= 2;
							quadRect.bottom -= 2;

							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.right, quadRect.top, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(quadRect.left, quadRect.bottom, 0), .(quadRect.right, quadRect.bottom, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.left, quadRect.bottom, 0), .(64,255,64), .(64,255,64));
							Renderer.DrawLine(.(quadRect.right, quadRect.top, 0), .(quadRect.right, quadRect.bottom, 0), .(64,255,64), .(64,255,64));
						case 2:
							quadRect.left += 4;
							quadRect.top += 4;

							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.right, quadRect.top, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.left, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
						case 3:
							quadRect.top += 4;
							quadRect.right -= 4;

							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.right, quadRect.top, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(quadRect.right, quadRect.top, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
						case 4:
							quadRect.left += 4;
							quadRect.bottom -= 4;

							Renderer.DrawLine(.(quadRect.left, quadRect.bottom, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.left, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
						case 5:
							quadRect.right -= 4;
							quadRect.bottom -= 4;

							Renderer.DrawLine(.(quadRect.left, quadRect.bottom, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
							Renderer.DrawLine(.(quadRect.right, quadRect.top, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,255), .(64,64,255));
					}
				}
			}

			for (let decodedTextureID < VRAM.decodedTextures.Count) {
				let decodedSprite = VRAM.decodedTextures[decodedTextureID];

				Rect quadRect;
				quadRect.start = PixelToScreen((float)decodedSprite.x / (16 / decodedSprite.bitmode), decodedSprite.y);
				quadRect.end = PixelToScreen((float)(decodedSprite.x + decodedSprite.width) / (16 / decodedSprite.bitmode), decodedSprite.y + decodedSprite.height);

				Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.right, quadRect.top, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(quadRect.left, quadRect.bottom, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(quadRect.left, quadRect.top, 0), .(quadRect.left, quadRect.bottom, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(quadRect.right, quadRect.top, 0), .(quadRect.right, quadRect.bottom, 0), .(64,64,64), .(64,64,64));

				if (blinkerTime < 30 && selectedCLUTIndex > -1 && cluts[selectedCLUTIndex].references.Contains(decodedTextureID)) {
					DrawUtilities.Rect(quadRect, .(255,0,0,64));
				}
			}

			for (let CLUTIndex < cluts.Count) {
				let clutReference = cluts[CLUTIndex];
				(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);

				let clutStart = PixelToScreen(clutPosition.x, (clutPosition.x >> 10) + clutPosition.y);
				let clutEnd = PixelToScreen(clutPosition.x + clutReference.width, (clutPosition.x >> 10) + clutPosition.y + (clutReference.type == .Gradient ? 16 : 1));

				Renderer.DrawLine(.(clutStart.x, clutStart.y, 0), .(clutEnd.x, clutStart.y, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(clutStart.x, clutEnd.y, 0), .(clutEnd.x, clutEnd.y, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(clutStart.x, clutStart.y, 0), .(clutStart.x, clutEnd.y, 0), .(64,64,64), .(64,64,64));
				Renderer.DrawLine(.(clutEnd.x, clutStart.y, 0), .(clutEnd.x, clutEnd.y, 0), .(64,64,64), .(64,64,64));
			}

			// CLUTs can be small and packed very tightly in VRAM so the lines drawn could over draw the highlight,
			// instead do it in another loop draw pass
			for (let CLUTIndex < cluts.Count) {
				let clutReference = cluts[CLUTIndex];
				(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);

				Rect clutRect;
				clutRect.start = PixelToScreen(clutPosition.x, (clutPosition.x >> 10) + clutPosition.y);
				clutRect.end = PixelToScreen(clutPosition.x + clutReference.width, (clutPosition.x >> 10) + clutPosition.y + (clutReference.type == .Gradient ? 16 : 1));

				if (blinkerTime < 30 && selectedTextureIDIndex > -1 && clutReference.references.Contains(selectedTextureIDIndex)) {

					DrawUtilities.Rect(clutRect, .(255,0,0,64));

					clutRect.left -= 2;
					clutRect.top -= 2;
					clutRect.right += 2;
					clutRect.bottom += 2;

					Renderer.DrawLine(.(clutRect.left, clutRect.top, 0), .(clutRect.right, clutRect.top, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(clutRect.left, clutRect.bottom, 0), .(clutRect.right, clutRect.bottom, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(clutRect.left, clutRect.top, 0), .(clutRect.left, clutRect.bottom, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(clutRect.right, clutRect.top, 0), .(clutRect.right, clutRect.bottom, 0), .(255,255,255), .(255,255,255));
				}
			}

			if (hoveredTextureIDIndex > -1) {
				let decodedTexture = VRAM.decodedTextures[hoveredTextureIDIndex];

				let partialUVs = decodedTexture.GetVramPartialUV();
				let quadStart = UVToScreen(partialUVs.left, partialUVs.top);

				let clutPosition = decodedTexture.GetCLUTCoordinates();
				let clutStart = PixelToScreen(clutPosition.x, (clutPosition.x >> 10) + clutPosition.y);

				Renderer.DrawLine(.(quadStart.x, quadStart.y, 0), .(clutStart.x, clutStart.y, 0), .(64,64,64), .(64,64,64));
			}

			if (hoveredCLUTIndex > -1) {
				let clutReference = cluts[hoveredCLUTIndex];

				(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);
				let clutStart = PixelToScreen(clutPosition.x, (clutPosition.x >> 10) + clutPosition.y);

				for (let textureID in clutReference.references) {
					let sprite = VRAM.decodedTextures[textureID];

					let partialUVs = sprite.GetVramPartialUV();
					let quadStart = UVToScreen(partialUVs.left, partialUVs.top);

					Renderer.DrawLine(.(quadStart.x, quadStart.y, 0), .(clutStart.x, clutStart.y, 0), .(64,64,64), .(64,64,64));
				}
			}


			if (blinkerTime < 30) {
				if (selectedTextureIDIndex > -1) {
					let sprite = VRAM.decodedTextures[selectedTextureIDIndex];
					let partialUVs = sprite.GetVramPartialUV();

					Rect quadRect;
					quadRect.start = UVToScreen(partialUVs.left, partialUVs.top);
					quadRect.end = UVToScreen(partialUVs.right, partialUVs.bottom);

					DrawUtilities.Rect(quadRect, .(255,255,255,64));
				}

				if (selectedCLUTIndex > -1) {
					let clutReference = cluts[selectedCLUTIndex];
					(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);

					Rect rect;
					rect.start = PixelToScreen(clutPosition.x, (clutPosition.x >> 10) + clutPosition.y);
					rect.end = PixelToScreen(clutPosition.x + clutReference.width, (clutPosition.x >> 10) + clutPosition.y + (clutReference.type == .Gradient ? 16 : 1));

					DrawUtilities.Rect(rect, .(255,255,255,64));

					rect.left -= 2;
					rect.top -= 2;
					rect.right += 2;
					rect.bottom += 2;

					Renderer.DrawLine(.(rect.left, rect.top, 0), .(rect.right, rect.top, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(rect.left, rect.bottom, 0), .(rect.right, rect.bottom, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(rect.left, rect.top, 0), .(rect.left, rect.bottom, 0), .(255,255,255), .(255,255,255));
					Renderer.DrawLine(.(rect.right, rect.top, 0), .(rect.right, rect.bottom, 0), .(255,255,255), .(255,255,255));
				}
			}

			if (clickMode != .Normal) {
				String text = clickMode == .Export ? "Export" : "Alter";

				Rect bgRect;
				bgRect.start = WindowApp.mousePosition + .(16,16);
				bgRect.end = bgRect.start + .(WindowApp.bitmapFont.characterWidth * text.Length, WindowApp.bitmapFont.height);
				DrawUtilities.Rect(bgRect, .(0,0,0,128));
				WindowApp.bitmapFont.Print(text, bgRect.start + .(0,3), .(255,255,255));
			}

			WindowApp.bitmapFont.Print(scope String() .. AppendF("<{},{}>", (int)testPosition.x, (int)testPosition.y), .Zero, .(255,255,255));
			WindowApp.bitmapFont.Print(scope String() .. AppendF("T-page {}", hoveredTexturePage), .(0, WindowApp.bitmapFont.height), .(255,255,255));

			if (!spritesDecoded) {
				DrawLoadingOverlay();
			}
		}

		void OnSceneChanged() {
			for (let clutReference in cluts) {
				delete clutReference.references;
			}
			cluts.Clear();

			if (Emulator.active.installment != .SpyroTheDragon) {
				SpyroFont.Init();
			}
			
			lastUpdatedSceneChange = .Now;
		}

		void OnNewSnapshot() {
			spritesDecoded = false;
			hoveredTextureIDIndex = -1;
		}

		public override bool OnEvent(SDL2.SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (event.button.button == 1) {
						switch (clickMode) {
							case .Normal: {
								blinkerTime = 0;
								selectedCLUTIndex = hoveredCLUTIndex;
								selectedTextureIDIndex = hoveredTextureIDIndex;
							}
							case .Export: Export();
							case .Alter: Alter();
						}
					}
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

						vramOrigin.x = WindowApp.width / 2 - viewPosition.x * scale;
						vramOrigin.y = WindowApp.height / 2 - viewPosition.y * scale;
					} else {
						testPosition.x = ((WindowApp.mousePosition.x - WindowApp.width / 2) / scale + viewPosition.x) / (expand ? 4 : 1) + (expand ? 512 : 0);
						testPosition.y = (WindowApp.mousePosition.y - WindowApp.height / 2) / scale + viewPosition.y;

						if (testPosition.x > 0 && testPosition.x < 1024 && testPosition.y > 0 && testPosition.y < 512) {
							hoveredTexturePage = (.)(testPosition.x / 64) + (.)(testPosition.y / 256) * 16;
						}

						hoveredTextureIDIndex = -1;
						for (let decodedTextureID < VRAM.decodedTextures.Count) {
							let decodedTexture = VRAM.decodedTextures[decodedTextureID];

							let subPixels = 16 / decodedTexture.bitmode;
							if (testPosition.x * subPixels > decodedTexture.x && testPosition.x * subPixels <= (int)(decodedTexture.x + decodedTexture.width) &&
								testPosition.y > decodedTexture.y && testPosition.y <= (int)(decodedTexture.y + decodedTexture.height)) {

								hoveredTextureIDIndex = decodedTextureID;
								break;
							}
						}

						hoveredCLUTIndex = -1;
						for (let clutIndex < cluts.Count) {
							let clutReference = cluts[clutIndex];
							(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);

							let left = clutPosition.x & 0x3ff;
							let right = left + clutReference.width;
							let top = (clutPosition.x >> 10) + clutPosition.y;
							let bottom = top + (clutReference.type == .Gradient ? 16 : 1);

							if (testPosition.x > left && testPosition.x <= right &&
								testPosition.y > top && testPosition.y <= bottom) {

								hoveredCLUTIndex = clutIndex;
								break;
							}
						}
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

					vramOrigin.x = WindowApp.width / 2 - viewPosition.x * scale;
					vramOrigin.y = WindowApp.height / 2 - viewPosition.y * scale;
				}
				case .KeyDown : {
					switch (event.key.keysym.scancode) {
						case .LCtrl: clickMode = .Export;
						case .LAlt: clickMode = .Alter;
						case .V: windowApp.GoToState<ViewerState>();
						case .Key0: ResetView();
						case .Key1: ToggleExpandedView();
						case .Key9: ExportVRAM();
						default: return false;
					}
				}
				case .KeyUp : {
					switch (event.key.keysym.scancode) {
						case .LCtrl, .LAlt: clickMode = .Normal;
						default: return false;
					}
				}
				default: return false;
			}
			return true;
		}

		void ResetView() {
			let pixelWidth = expand ? 4 : 1;
			let width = (expand ? 512 : 1024) * pixelWidth;
			Vector2 size = .(width, 512);

			viewPosition.x = size.x / 2;
			viewPosition.y = size.y / 2;

			vramOrigin.x = WindowApp.width / 2 - viewPosition.x * scale;
			vramOrigin.y = WindowApp.height / 2 - viewPosition.y * scale;
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

			vramOrigin.x = WindowApp.width / 2 - viewPosition.x * scale;
			vramOrigin.y = WindowApp.height / 2 - viewPosition.y * scale;
		}

		void ExportVRAM() {
			let dialog = new SaveFileDialog();
			dialog.FileName = "vram_decoded";
			dialog.SetFilter("Bitmap image (*.bmp)|*.bmp|Truevision TGA (*.tga)|*.tga|All files (*.*)|*.*");
			dialog.OverwritePrompt = true;
			dialog.CheckFileExists = true;
			dialog.AddExtension = true;
			dialog.DefaultExt = "bmp";

			switch (dialog.ShowDialog()) {
				case .Ok(let val):
					if (val == .OK) {
						VRAM.Export(dialog.FileNames[0]);
					}
				case .Err:
			}

			delete dialog;
		}

		[Inline]
		Vector2 PixelToScreen(float x, float y) {
			return UVToScreen(.(x / 1024, y / 512));
		}

		[Inline]
		Vector2 PixelToScreen(Vector2 pixelPos) {
			return PixelToScreen(pixelPos.x, pixelPos.y);
		}

		[Inline]
		Vector2 UVToScreen(float x, float y) {
			return .(vramOrigin.x + (x - (expand ? 0.5f : 0)) * vramSize.width * (expand ? 2 : 1) * scale, vramOrigin.y + y * vramSize.height * scale);
		}

		[Inline]
		Vector2 UVToScreen(Vector2 uvPos) {
			return UVToScreen(uvPos.x, uvPos.y);
		}

		void Export() {
			if (hoveredTextureIDIndex > -1) {
				let dialog = scope System.IO.SaveFileDialog();
				dialog.FileName = "texture";
				dialog.SetFilter("Bitmap image (*.bmp)|*.bmp|All files (*.*)|*.*");
				dialog.OverwritePrompt = true;
				dialog.CheckFileExists = true;
				dialog.AddExtension = true;
				dialog.DefaultExt = "bmp";

				if (dialog.ShowDialog() case .Ok(let val)) {
					if (val == .OK) {
						VRAM.Export(dialog.FileNames[0], hoveredTextureIDIndex);
					}
				}
			}
		}

		void Alter() {
			if (hoveredTextureIDIndex == -1 && hoveredCLUTIndex == -1) {
				return;
			}

			let dialog = scope OpenFileDialog();
			dialog.SetFilter("Bitmap image (*.bmp)|*.bmp|All files (*.*)|*.*");
			dialog.CheckFileExists = true;
			dialog.Multiselect = true;

			switch (dialog.ShowDialog()) {
				case .Ok(let val):
					if (val == .OK) {
						let file = dialog.FileNames[0];

						let surface = SDLImage.Load(file);
						if (surface != null) {
							if (hoveredTextureIDIndex > -1) {
								let spritesToReplace = Math.Min(dialog.FileNames.Count, VRAM.decodedTextures.Count - hoveredTextureIDIndex);
								for (let fileSpriteIndex < spritesToReplace) {
									let fileSprite = dialog.FileNames[fileSpriteIndex];
									let surfaceSprite = SDLImage.Load(fileSprite);

									AlterVRAM(surfaceSprite, hoveredTextureIDIndex);

									SDL.FreeSurface(surfaceSprite);
								}
							}

							if (hoveredCLUTIndex > -1) {
								let clutReference = cluts[hoveredCLUTIndex];
								(int x, int y) clutPosition = ((clutReference.location & 0x3f) << 4, clutReference.location >> 6);

								uint16[] clutTable = ?;
								switch (clutReference.type) {
									case .Normal:
										clutTable = GenerateCLUT!(surface);
										VRAM.Write(clutTable, clutPosition.x, clutPosition.y, surface.w, 1);

									case .Gradient:
										clutTable = GenerateCLUT!(surface, 16);
										VRAM.Write(clutTable, clutPosition.x, clutPosition.y, surface.w, 16);
								}

								for (let reference in cluts[hoveredCLUTIndex].references) {
									VRAM.Decode(reference);
								}
							}
						}

						SDL.FreeSurface(surface);
					}
				case .Err:
			}
		}

		void AlterVRAM(SDL.Surface* surface, int texturePage, int textureX, int textureY, int textureWidth, int textureHeight, int bitmode, int clut) {
			let width = Math.Min(surface.w, textureWidth);
			let height = Math.Min(surface.h, textureHeight);

			let (quadWidth, quadPixels) = GeneratePixelBuffer!(surface, width, height, bitmode, clut);

			VRAM.Write(quadPixels, ((texturePage & 0xf) * 64 + textureX / (16 / bitmode)), ((texturePage >> 4 & 0x1) * 256 + textureY), quadWidth, height);
			VRAM.Decode(texturePage, textureX, textureY, width, height, bitmode, clut);
		}

		void AlterVRAM(SDL.Surface* surface, int decodedTextureID) {
			let decodedTexture = VRAM.decodedTextures[decodedTextureID];

			let width = Math.Min(surface.w, decodedTexture.width);
			let height = Math.Min(surface.h, decodedTexture.height);

			let (quadWidth, quadPixels) = GeneratePixelBuffer!(surface, width, height, decodedTexture.bitmode, decodedTexture.clut);

			//VRAM.Write(quadPixels, decodedTextureID);
			
			let subPixels = 16 / decodedTexture.bitmode;
			VRAM.Write(quadPixels, decodedTexture.x / subPixels, decodedTexture.y, quadWidth, height);
			VRAM.Decode(decodedTextureID);
		}

		mixin GeneratePixelBuffer(SDL.Surface* surface, int width, int height, int bitmode, int clut) {
			let subPixels = 16 / bitmode;
			let clutPosition = clut << 4;
			let colorCount = 1 << bitmode;

			let quadWidth = (int)Math.Ceiling((float)width / subPixels);
			let quadPixels = scope:mixin uint16[quadWidth * height];
			
			for (let y < height) {
				for (let x < width) {
					let pixel = GetPixelFromSurface!(surface, x + y * width);

					uint16 i = 0;
					var closest = float.PositiveInfinity;

					for (let c < colorCount) {
						let clutSample = VRAM.snapshot[clutPosition + c];

						if ((GetAlphaValue!(pixel, surface.format.Amask) > 0.5f) == (clutSample >> 15 < 1)) {
							let dr = GetChannelValue!(pixel, surface.format.Rmask) - (float)(clutSample & 0x1f) / 31;
							let dg = GetChannelValue!(pixel, surface.format.Gmask) - (float)(clutSample >> 5 & 0x1f) / 31;
							let db = GetChannelValue!(pixel, surface.format.Bmask) - (float)(clutSample >> 10 & 0x1f) / 31;
							let distance = dr * dr + dg * dg + db * db;

							if (distance < closest) {
								i = (.)c;
								closest = distance;
							}
						}
					}

					let p = x % subPixels;
					quadPixels[x / subPixels + y * quadWidth] |= i << (p * bitmode);
				}
			}

			(quadWidth, quadPixels)
		}

		mixin GenerateCLUT(SDL.Surface* surface) {
			let clutTable = scope:mixin uint16[surface.w];

			for (let x < surface.w) {
				let pixel = GetPixelFromSurface!(surface, x);

				let r = (uint16)(GetChannelValue!(pixel, surface.format.Rmask) * 31);
				let g = (uint16)(GetChannelValue!(pixel, surface.format.Gmask) * 31);
				let b = (uint16)(GetChannelValue!(pixel, surface.format.Bmask) * 31);

				clutTable[x] = r | g << 5 | b << 10 | (GetAlphaValue!(pixel, surface.format.Amask) > 0.5f ? 0 : 0x8000);
			}

			clutTable
		}

		mixin GenerateCLUT(SDL.Surface* surface, int height, bool black = false) {
			let clutTable = scope:mixin uint16[surface.w * 16];
			let colorLevel = black ? 0 : 16;

			for (let x < surface.w) {
				let pixel = GetPixelFromSurface!(surface, x);

				for (let y < height) {
					uint16 outR, outG, outB = ?;
					float inR = GetChannelValue!(pixel, surface.format.Rmask);
					float inG = GetChannelValue!(pixel, surface.format.Rmask);
					float inB = GetChannelValue!(pixel, surface.format.Rmask);

					if (inR == 0 && inG == 0 && inB == 0) {
						// Extend the black colored pixels
						outR = outG = outB = 0;
					} else {
						// Fade to the desired color
						let fadeAmount = (float)y / height;

						outR = (uint16)Math.Lerp(GetChannelValue!(pixel, surface.format.Rmask) * 31, colorLevel, fadeAmount);
						outG = (uint16)Math.Lerp(GetChannelValue!(pixel, surface.format.Gmask) * 31, colorLevel, fadeAmount);
					 	outB = (uint16)Math.Lerp(GetChannelValue!(pixel, surface.format.Bmask) * 31, colorLevel, fadeAmount);
					}

					clutTable[x + y * surface.w] = outR | outG << 5 | outB << 10 | (GetAlphaValue!(pixel, surface.format.Amask) > 0.5f ? 0 : 0x8000);
				}
			}

			clutTable
		}

		mixin GetPixelFromSurface(SDL.Surface* surface, int pixelIndex) {
			*(uint32*)(&((uint8*)surface.pixels)[pixelIndex * surface.format.bytesPerPixel])
		}

		mixin GetChannelValue(uint32 pixel, uint32 mask) {
			mask > 0 ? (float)(pixel & mask) / mask : 0
		}

		mixin GetAlphaValue(uint32 pixel, uint32 alphaMask) {
			alphaMask > 0 ? (float)(pixel & alphaMask) / alphaMask : 1
		}

		void Decode() {
			if (!Terrain.decoded) {
				Terrain.Decode();
			}

			if (!spritesDecoded) {
				// Get CLUT references for the existing decoded textures since they contain only terrain ones first
				for (let textureID < VRAM.decodedTextures.Count) {
					let decodedSprite = VRAM.decodedTextures[textureID];
					CLUTType type = decodedSprite.bitmode == 4 ? .Gradient : .Normal;
					let referenceIndex = cluts.FindIndex(scope (x) => x.category == .Terrain && x.type == type && x.location == decodedSprite.clut);

					if (referenceIndex == -1) {
						CLUTReference clutReference = ?;
						clutReference.category = .Terrain;
						clutReference.type = type;
						clutReference.location = decodedSprite.clut;
						clutReference.width = 1 << decodedSprite.bitmode;
						clutReference.references = new .();

						clutReference.references.Add(textureID);
						cluts.Add(clutReference);
					} else {
						cluts[referenceIndex].references.Add(textureID);
					}
				}

				// Now proceed with the sprites
				List<int> spriteTextureIDs = scope .();

				switch (Emulator.active.installment) {
					case .RiptosRage:
						let textureSprites = new List<TextureSprite>();
	
						textureSprites.Add(new .(0, 0, 10)); // Numbers
						textureSprites.Add(new .(2, 10, 1)); // Forward Slash
	
						textureSprites.Add(new .(1, 11, 6)); // Gem
						textureSprites.Add(new .(1, 19, 3)); // Spirit
	
						textureSprites.Add(new .(2, 0x1d, 1)); // Colon
						textureSprites.Add(new .(2, 0x1e, 1)); // Period
	
						textureSprites.Add(new .(5, 0x16, 1)); // Power Bar Top
						textureSprites.Add(new .(6, 0x1a, 1)); // Power Icon BG
						textureSprites.Add(new .(7, 0x1b, 1)); // Power Icon FG
	
						textureSprites.Add(new .(5, 0x17, 1)); // Power Bar Mid
						textureSprites.Add(new .(5, 0x18, 1)); // Power Bar Bottom
						textureSprites.Add(new .(5, 0x19, 1)); // Power Bar Mid Lit
	
						textureSprites.Add(new .(11, 0x24, 4)); // Rounded Corners
	
						textureSprites.Add(new .(1, 0x1c, 1)); // Reticle Circle
	
						textureSprites.Add(new .(9, 0x1f, 1)); // Spyro Head
						textureSprites.Add(new .(10, 0x20, 4)); // Spyro Eyes
	
						textureSprites.Add(new .(4, 0x57, 1)); // Map
	
						textureSprites.Add(new .(1, 0x37, 8)); // Objective 1
						textureSprites.Add(new .(1, 0x3f, 8)); // Objective 2
						/*textureSprites.Add(new .(1, 0x47, 8)); // Objective 3
						textureSprites.Add(new .(1, 0x4f, 8)); // Objective 4*/
	
						for (let sprite in textureSprites) {
							for (let frameIndex < sprite.frames.Count) {
								spriteTextureIDs.Add(sprite.Decode(frameIndex));
							}
						}
	
						DeleteContainerAndItems!(textureSprites);

					case .YearOfTheDragon:
						var textureSprites = TextureQuad[45]();
						Emulator.Address<TextureQuad> spriteArrayPointer = ?;
						Emulator.spriteArrayPointer[(int)Emulator.active.rom - 7].Read(&spriteArrayPointer);
						spriteArrayPointer.ReadArray(&textureSprites[0], 45);
	
						for (let sprite in textureSprites) {
							spriteTextureIDs.Add(sprite.Decode());
						}

					default:
				}

				if (Emulator.active.installment != .SpyroTheDragon) {
					SpyroFont.Decode(spriteTextureIDs);
				}

				for (let textureID in spriteTextureIDs) {
					let decodedSprite = VRAM.decodedTextures[textureID];
					let referenceIndex = cluts.FindIndex(scope (x) => x.category == .Sprite && x.type == .Normal && x.location == decodedSprite.clut);
	
					if (referenceIndex == -1) {
						CLUTReference clutReference = ?;
						clutReference.category = .Sprite;
						clutReference.type = .Normal;
						clutReference.location = decodedSprite.clut;
						clutReference.width = 16;
						clutReference.references = new .();
	
						clutReference.references.Add(textureID);
						cluts.Add(clutReference);
					} else {
						cluts[referenceIndex].references.Add(textureID);
					}
				}

				spritesDecoded = true;
			}
		}

		void DrawLoadingOverlay() {
			// Darken everything
			DrawUtilities.Rect(0,WindowApp.height,0,WindowApp.width, .(0,0,0,192));

			let message = "Waiting for Unpause...";
			var halfWidth = Math.Round(WindowApp.font.CalculateWidth(message) / 2);
			var baseline = (WindowApp.height - WindowApp.font.height) / 2;
			let middleWindow = WindowApp.width / 2;
			WindowApp.font.Print(message, .(middleWindow - halfWidth, baseline), .(255,255,255));
		}
	}
}
