using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class ViewerState : WindowState {
		// View
		enum ViewMode {
			Game,
			Free,
			Map
		}

		ViewMode viewMode = .Game;
		bool cameraHijacked;
		float cameraSpeed = 64;
		Vector cameraMotion;
		Vector viewEulerRotation;
		bool mapMode;

		// Options
		bool drawObjectOrigins = true;
		public static bool hideInactive = false;
		bool displayIcons = false;
		bool displayAllData = false;
		bool showManipulator = false;

		// Scene
		public static Terrain terrain ~ delete _;
		bool drawLimits;

		// Objects
		public static List<(Emulator.Address<Moby>, Moby)> objectList = new .(128) ~ delete _;
		Dictionary<uint16, MobyModelSet> modelSets = new .();

		// UI
		public static Vector cursor3DPosition;

		List<(String message, DateTime time)> messageFeed = new .();
		List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		Button togglePauseButton, stepButton, cycleTerrainOverlayButton, teleportButton;

		Texture normalButtonTexture = new .("images/ui/button_normal.png") ~ delete _; 
		Texture pressedButtonTexture = new .("images/ui/button_pressed.png") ~ delete _;

		Texture playTexture = new .("images/ui/play.png") ~ delete _; 
		Texture pauseTexture = new .("images/ui/pause.png") ~ delete _; 
		Texture stepTexture = new .("images/ui/step.png") ~ delete _;
		Texture toggledTexture = new .("images/ui/toggle_enabled.png") ~ delete _;

		Texture gemIconTexture = new .("images/ui/icon_gem.png") ~ delete _;
		Texture gemHolderIconTexture = new .("images/ui/icon_gem_holder.png") ~ delete _;
		Texture basketIconTexture = new .("images/ui/icon_basket.png") ~ delete _;
		Texture vaseIconTexture = new .("images/ui/icon_vase.png") ~ delete _;
		Texture bottleIconTexture = new .("images/ui/icon_bottle.png") ~ delete _;

		GUIElement cornerMenu;
		bool cornerMenuVisible;
		float cornerMenuInterp;
		
		GUIElement sideInspector;
		bool sideInspectorVisible;
		float sideInspectorInterp;

		(Toggle button, String label)[8] toggleList = .(
			(null, "Wirefra(m)e"),
			(null, "Object (O)rigin Axis"),
			(null, "Hide (I)nactive Objects"),
			(null, "(H)eight Limits"),
			(null, "Free (C)amera"),
			(null, "Display Icons"),
			(null, "All Visual Moby Data"),
			(null, "(E)nable Manipulator")
		);

		Toggle pinInspectorButton;

		public this() {
			ViewerSelection.Init();
			GUIElement.SetActiveGUI(guiElements);

			togglePauseButton = new .();

			togglePauseButton.anchor = .(0.5f, 0.5f, 0, 0);
			togglePauseButton.offset = .(-16, 16, -16, 16);
			togglePauseButton.offset.Shift(-16, 32);
			togglePauseButton.normalTexture = normalButtonTexture;
			togglePauseButton.pressedTexture = pressedButtonTexture;
			togglePauseButton.OnActuated.Add(new => TogglePause);

			stepButton = new .();

			stepButton.anchor = .(0.5f, 0.5f, 0, 0);
			stepButton.offset = .(-16, 16, -16, 16);
			stepButton.offset.Shift(16, 32);
			stepButton.normalTexture = normalButtonTexture;
			stepButton.pressedTexture = pressedButtonTexture;
			stepButton.iconTexture = stepTexture;
			stepButton.OnActuated.Add(new => Step);

			cornerMenu = new GUIElement();
			cornerMenu.offset = .(0,260,0,200);
			GUIElement.PushParent(cornerMenu);

			Button viewButton1 = new .();
			Button viewButton2 = new .();
			Button viewButton3 = new .();

			viewButton1.offset = .(16,72,16,32);
			viewButton2.offset = .(72,128,16,32);
			viewButton3.offset = .(128,184,16,32);
			viewButton1.normalTexture = viewButton2.normalTexture = viewButton3.normalTexture = normalButtonTexture;
			viewButton1.pressedTexture = viewButton2.pressedTexture = viewButton3.pressedTexture = pressedButtonTexture;

			viewButton1.text = "Game";
			viewButton2.text = "Free";
			viewButton3.text = "Map";

			viewButton1.enabled = false;

			viewButton1.OnActuated.Add(new () => {
				viewButton1.enabled = false;
				viewButton2.enabled = viewButton3.enabled = true;
				ToggleView(.Game);
			});
			viewButton2.OnActuated.Add(new () => {
				viewButton2.enabled = false;
				viewButton1.enabled = viewButton3.enabled = true;
				ToggleView(.Free);
			});
			viewButton3.OnActuated.Add(new () => {
				viewButton3.enabled = false;
				viewButton2.enabled = viewButton1.enabled = true;
				ToggleView(.Map);
			});

			viewButton1 = new .();
			viewButton2 = new .();
			viewButton3 = new .();

			viewButton1.offset = .(16,72,36,52);
			viewButton2.offset = .(72,128,36,52);
			viewButton3.offset = .(128,184,36,52);
			viewButton1.normalTexture = viewButton2.normalTexture = viewButton3.normalTexture = normalButtonTexture;
			viewButton1.pressedTexture = viewButton2.pressedTexture = viewButton3.pressedTexture = pressedButtonTexture;

			viewButton1.text = "Collision";
			viewButton2.text = "Far";
			viewButton3.text = "Near";

			viewButton1.enabled = false;

			viewButton1.OnActuated.Add(new () => {
				viewButton1.enabled = false;
				viewButton2.enabled = viewButton3.enabled = cycleTerrainOverlayButton.enabled = true;
				terrain.renderMode = .Collision;
				ViewerSelection.currentTriangleIndex = -1;
				ViewerSelection.currentRegionIndex = -1;
			});
			viewButton2.OnActuated.Add(new () => {
				viewButton2.enabled = cycleTerrainOverlayButton.enabled = false;
				viewButton1.enabled = viewButton3.enabled = true;
				terrain.renderMode = .Far;
				ViewerSelection.currentTriangleIndex = -1;
			});
			viewButton3.OnActuated.Add(new () => {
				viewButton3.enabled = cycleTerrainOverlayButton.enabled = false;
				viewButton2.enabled = viewButton1.enabled = true;
				terrain.renderMode = .Near;
				ViewerSelection.currentTriangleIndex = -1;
			});

			for (let i < toggleList.Count) {
				Toggle button = new .();

				button.offset = .(16, 32, 16 + (i + 2) * WindowApp.font.height, 32 + (i + 2) * WindowApp.font.height);
				button.normalTexture = normalButtonTexture;
				button.pressedTexture = pressedButtonTexture;
				button.toggleIconTexture = toggledTexture;

				toggleList[i].button = button;
			}

			toggleList[1].button.Pressed();

			toggleList[0].button.OnActuated.Add(new () => {ToggleWireframe(toggleList[0].button.value);});
			toggleList[1].button.OnActuated.Add(new () => {ToggleOrigins(toggleList[1].button.value);});
			toggleList[2].button.OnActuated.Add(new () => {ToggleInactive(toggleList[2].button.value);});
			toggleList[3].button.OnActuated.Add(new () => {ToggleLimits(toggleList[3].button.value);});
			toggleList[4].button.OnActuated.Add(new () => {ToggleFreeCamera(toggleList[4].button.value);});
			toggleList[5].button.OnActuated.Add(new () => {displayIcons = toggleList[5].button.value;});
			toggleList[6].button.OnActuated.Add(new () => {displayAllData = toggleList[6].button.value;});
			toggleList[7].button.OnActuated.Add(new () => {showManipulator = toggleList[7].button.value;});

			cycleTerrainOverlayButton = new .();

			cycleTerrainOverlayButton.offset = .(16, 180, 16 + (toggleList.Count + 2) * WindowApp.font.height, 32 + (toggleList.Count + 2) * WindowApp.font.height);
			cycleTerrainOverlayButton.normalTexture = normalButtonTexture;
			cycleTerrainOverlayButton.pressedTexture = pressedButtonTexture;
			cycleTerrainOverlayButton.text = "Terrain Over(l)ay";
			cycleTerrainOverlayButton.OnActuated.Add(new => CycleTerrainOverlay);

			teleportButton = new .();

			teleportButton.offset = .(16, 180, 16 + (toggleList.Count + 3) * WindowApp.font.height, 32 + (toggleList.Count + 3) * WindowApp.font.height);
			teleportButton.normalTexture = normalButtonTexture;
			teleportButton.pressedTexture = pressedButtonTexture;
			teleportButton.text = "(T)eleport";
			teleportButton.OnActuated.Add(new => Teleport);
			teleportButton.enabled = false;

			GUIElement.PopParent();
			
			sideInspector = new GUIElement();
			sideInspector.anchor = .(1,1,0,1);
			sideInspector.offset = .(-300,0,0,0);
			GUIElement.PushParent(sideInspector);

			pinInspectorButton = new .();

			pinInspectorButton.offset = .(0, 16, 0, 16);
			pinInspectorButton.offset.Shift(2,2);
			pinInspectorButton.normalTexture = normalButtonTexture;
			pinInspectorButton.pressedTexture = pressedButtonTexture;
			pinInspectorButton.toggleIconTexture = toggledTexture;

			Button copyMobyAddress = new .();

			copyMobyAddress.offset = .(0,64,0,16);
			copyMobyAddress.offset.Shift(150,2);
			copyMobyAddress.normalTexture = normalButtonTexture;
			copyMobyAddress.pressedTexture = pressedButtonTexture;
			copyMobyAddress.text = "Copy";
			copyMobyAddress.OnActuated.Add(new () => { SDL.SetClipboardText(scope String() .. AppendF("{}", objectList[ViewerSelection.currentObjIndex].0)); });

			Button copyMobyDataAddress = new .();

			copyMobyDataAddress.offset = .(0,64,0,16);
			copyMobyDataAddress.offset.Shift(195,251);
			copyMobyDataAddress.normalTexture = normalButtonTexture;
			copyMobyDataAddress.pressedTexture = pressedButtonTexture;
			copyMobyDataAddress.text = "Copy";
			copyMobyDataAddress.OnActuated.Add(new () => { SDL.SetClipboardText(scope String() .. AppendF("{}", (objectList[ViewerSelection.currentObjIndex].1).dataPointer)); });

			GUIElement.PopParent();

			for (let element in guiElements) {
				Button button = element as Button;
				if (button != null) {
					button.[Friend]color = button.normalColor;
					button.[Friend]texture = button.normalTexture;
				}
			}
		}

		public ~this() {
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			delete modelSets;
			for (let feedItem in messageFeed) {
				if (feedItem.message.IsDynAlloc) {
					delete feedItem.message;
				}
			}
			delete messageFeed;
		}

		public override void Enter() {
			Emulator.OnSceneChanged = new => OnSceneChanged;
			Emulator.OnSceneChanging = new => OnSceneChanging;
			
			togglePauseButton.iconTexture = Emulator.PausedMode ? playTexture : pauseTexture;
			toggleList[4].button.value = teleportButton.enabled = Emulator.CameraMode;
			if (Emulator.CameraMode) {
				toggleList[4].button.iconTexture = toggleList[4].button.toggleIconTexture;
			}
		}

		public override void Exit() {
			delete Emulator.OnSceneChanged;
			delete Emulator.OnSceneChanging;
		}

		public override void Update() {
			Emulator.CheckEmulatorStatus();
			Emulator.FindGame();

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				windowApp.GoToState<SetupState>();
				return;
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantData();
			
			UpdateView();

			cornerMenuInterp = Math.MoveTo(cornerMenuInterp, cornerMenuVisible ? 1 : 0, 0.1f);
			cornerMenu.offset = .(-200 * (1 - cornerMenuInterp),0,0,240);

			sideInspectorInterp = Math.MoveTo(sideInspectorInterp, sideInspectorVisible ? 1 : 0, 0.1f);
			sideInspector.offset = .(-300 * sideInspectorInterp,0,0,0);
			
			for (let element in guiElements) {
				element.Update();
			}

			if (Emulator.loadingStatus == .Loading || Emulator.gameState > 0) {
				return;
			}

			terrain?.Update();

			if (showManipulator) {
				if (ViewerSelection.currentObjIndex > -1) {
					Moby* moby = &(objectList[ViewerSelection.currentObjIndex].1);
					Translator.Update(moby.position, moby.basis);
				} else if (terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
					Translator.Update(terrain.collision.mesh.vertices[ViewerSelection.currentTriangleIndex * 3], .Identity);
				} else {
					Vector spyroPosition = Emulator.spyroPosition;
					Translator.Update(spyroPosition, Emulator.spyroBasis.ToMatrixCorrected());
				}
			}
		}

		public override void DrawView() {
			terrain?.Draw();

			if (viewMode != .Game) {
				DrawGameCameraFrustrum();
			}
			
			Emulator.Address<Moby> objPointer = ?;
			Emulator.objectArrayPointers[(int)Emulator.rom].Read(&objPointer);
			
			objectList.Clear();
			if (Emulator.loadingStatus == .Idle) {
				while (true) {
					Moby object = ?;
					objPointer.Read(&object);

					if (object.dataPointer.IsNull) {
						break;
					}
	
					if (!hideInactive || object.IsActive) {
						if ((!showManipulator || ViewerSelection.currentObjIndex != objectList.Count) && drawObjectOrigins) {
							object.DrawOriginAxis();
						}
		
						DrawMoby(object);
		
						objectList.Add((objPointer, object));
					}
					
					objPointer += sizeof(Moby);
				}
	
				if (displayAllData) {
					for (let (address, object) in objectList) {
						object.DrawData();
					}
				} else {
					if (ViewerSelection.currentObjIndex != -1) {
						if (ViewerSelection.currentObjIndex < objectList.Count) {
							let (address, object) = objectList[ViewerSelection.currentObjIndex];
							object.DrawData();
						} else {
							ViewerSelection.currentObjIndex = -1;
						}
					}
				}

				if (ViewerSelection.currentRegionIndex > 0) {
					let region = terrain.visualMeshes[ViewerSelection.currentRegionIndex];
					DrawUtilities.Axis(.((int)region.metadata.centerX * 16, (int)region.metadata.centerY * 16, (int)region.metadata.centerZ * 16), .Scale(1000));
				}
			}
			if (ViewerSelection.hoveredObjIndex >= objectList.Count || ViewerSelection.currentObjIndex >= objectList.Count) {
				Selection.Reset();
				ViewerSelection.hoveredObjects.Clear();
			}

			DrawSpyroInformation();

			// Draw all queued instances
			PrimitiveShape.DrawInstances();

			for (let modelSet in modelSets.Values) {
				for (let model in modelSet.models) {
					model.DrawInstances();
				}
			}

			// Draw world's origin
			Renderer.DrawLine(.Zero, .(10000,0,0), .(255,255,255), .(255,0,0));
			Renderer.DrawLine(.Zero, .(0,10000,0), .(255,255,255), .(0,255,0));
			Renderer.DrawLine(.Zero, .(0,0,10000), .(255,255,255), .(0,0,255));

			if (drawLimits) {
				uint32 currentWorldId = ?;
				Emulator.currentWorldIdAddress[(int)Emulator.rom].Read(&currentWorldId);

				uint32 deathHeight;
				if (Emulator.installment == .YearOfTheDragon) {
					uint32 currentSubWorldId = ?;
					Emulator.currentSubWorldIdAddress[(int)Emulator.rom - 7].Read(&currentSubWorldId);

					deathHeight = Emulator.deathPlaneHeights[currentWorldId * 4 + currentSubWorldId];
				} else {
					deathHeight = Emulator.deathPlaneHeights[currentWorldId];
				}

				if (Camera.position.z > deathHeight) {
					DrawUtilities.Grid(.(0,0,deathHeight), .Identity, .(255,64,32));
				}
				
				let flightHeight = Emulator.maxFreeflightHeights[currentWorldId];
				if (Camera.position.z < flightHeight) {
					DrawUtilities.Grid(.(0,0,flightHeight), .Identity, .(32,64,255));
				}
			}

			Renderer.SetModel(.Zero, .Identity);
			Renderer.SetTint(.(255,255,255));
			Renderer.Draw();

			Renderer.ClearDepth();

			if (showManipulator) {
			    Translator.Draw();
			}

			PrimitiveShape.DrawInstances();

			Renderer.SetModel(.Zero, .Identity);
			Renderer.SetTint(.(255,255,255));
			Renderer.Draw();
		}

		public override void DrawGUI() {
			if (displayIcons) {
				for	(let (address, object) in objectList) {
					if (hideInactive && !object.IsActive) {
						continue;
					}
	
					var offsettedPosition = object.position;
					if (object.objectTypeID != 1) {
						offsettedPosition.z += 0x100;
					}
	
					var screenPosition = Camera.SceneToScreen(offsettedPosition);
					if (screenPosition.z > 10000) { // Must be in front of view
						DrawMobyIcon(object, screenPosition, 1);
					}
				}
			}

			if (objectList.Count > 0 && ViewerSelection.currentObjIndex > -1) {
				let (address, currentObject) = objectList[ViewerSelection.currentObjIndex];
				// Begin overlays
				var screenPosition = Camera.SceneToScreen(currentObject.position);
				if (drawObjectOrigins && screenPosition.z > 0) { // Must be in front of view
					let screenSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
					screenPosition.z = 0;
					DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), .(16,16,16));

					if (!sideInspectorVisible) {
						Emulator.Address objectArrayPointer = ?;
						Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);

						screenPosition.y += screenSize;
						screenPosition.x = Math.Floor(screenPosition.x);
						screenPosition.y = Math.Floor(screenPosition.y);
						DrawUtilities.Rect(screenPosition.y, screenPosition.y + WindowApp.bitmapFont.characterHeight * 2, screenPosition.x, screenPosition.x + WindowApp.bitmapFont.characterWidth * 10,
							.(0,0,0,192));

						screenPosition.y += 2;
						WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]", address),
							screenPosition, .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("TYPE: {:X4}", currentObject.objectTypeID),
							screenPosition + .(0,WindowApp.bitmapFont.characterHeight,0), .(255,255,255));
					}
				}
			}

			if (ViewerSelection.hoveredObjects.Count > 0 && ViewerSelection.hoveredObjIndex > -1) {
				let (address, hoveredObject) = objectList[ViewerSelection.hoveredObjIndex];
				// Begin overlays
				var screenPosition = Camera.SceneToScreen(hoveredObject.position);
				if (screenPosition.z > 0) { // Must be in front of view
					let screenSize = Camera.SceneSizeToScreenSize(150, screenPosition.z);
					screenPosition.z = 0;
					DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), .(128,64,16));
				}
			}

			if (terrain != null) {
				if (terrain.renderMode == .Collision) {
					if (terrain.collision.overlay == .Flags) {
						DrawFlagsOverlay();
					} else if (terrain.collision.overlay == .Deform) {
						if (ViewerSelection.hoveredAnimGroupIndex != -1) {
							let hoveredAnimGroup = terrain.collision.animationGroups[ViewerSelection.hoveredAnimGroupIndex];
							// Begin overlays
							var screenPosition = Camera.SceneToScreen(hoveredAnimGroup.center);
							if (screenPosition.z > 0) { // Must be in front of view
								let screenSize = Camera.SceneSizeToScreenSize(hoveredAnimGroup.radius - 50, screenPosition.z);
								screenPosition.z = 0;
								DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), .(128,64,16));
							}
						}
	
						if (ViewerSelection.currentAnimGroupIndex != -1) {
							let animationGroup = terrain.collision.animationGroups[ViewerSelection.currentAnimGroupIndex];
							var screenPosition = Camera.SceneToScreen(animationGroup.center);
							if (screenPosition.z > 0) { // Must be in front of view
								let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
								screenPosition.z = 0;
								DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), .(16,16,0));
							}
	
							let leftPaddingBG = 4;
							let bottomPaddingBG = 4;
	
							// Background
							let backgroundHeight = 18 * 6;
							DrawUtilities.Rect((.)WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 14 + 8,
								.(0,0,0,192));
	
							// Content
							let currentKeyframe = animationGroup.CurrentKeyframe;
							WindowApp.bitmapFont.Print(scope String() .. AppendF("Group Index {}", ViewerSelection.currentAnimGroupIndex), .(8, (.)WindowApp.height - (18 * 5 + 8 + 15), 0), .(255,255,255));
							WindowApp.bitmapFont.Print(scope String() .. AppendF("Keyframe {}", (uint)currentKeyframe), .(8, (.)WindowApp.height - (18 * 4 + 8 + 15), 0), .(255,255,255));
							let keyframeData = animationGroup.GetKeyframeData(currentKeyframe);
							WindowApp.bitmapFont.Print(scope String() .. AppendF("Flag {}", (uint)keyframeData.flag), .(8, (.)WindowApp.height - (18 * 3 + 8 + 15), 0), .(255,255,255));
							WindowApp.bitmapFont.Print(scope String() .. AppendF("Interp. {}", (uint)keyframeData.interpolation), .(8, (.)WindowApp.height - (18 * 2 + 8 + 15), 0), .(255,255,255));
							WindowApp.bitmapFont.Print(scope String() .. AppendF("From State {}", (uint)keyframeData.fromState), .(8, (.)WindowApp.height - (18 * 1 + 8 + 15), 0), .(255,255,255));
							WindowApp.bitmapFont.Print(scope String() .. AppendF("To State {}", (uint)keyframeData.toState), .(8, (.)WindowApp.height - (18 * 0 + 8 + 15), 0), .(255,255,255));
						} else if (terrain.collision.animationGroups != null) {
							for (let animationGroup in terrain.collision.animationGroups) {
								var screenPosition = Camera.SceneToScreen(animationGroup.center);
								if (screenPosition.z > 0) { // Must be in front of view
									let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
									screenPosition.z = 0;
									DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), .(16,16,0));
								}
							}
						}
					}
				} else if (terrain.renderMode == .Near && ViewerSelection.currentRegionIndex > -1 && ViewerSelection.currentTriangleIndex > -1) {
					let visualMesh = terrain.visualMeshes[ViewerSelection.currentRegionIndex];
					let metadata = visualMesh.metadata;
					
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Region: {}", ViewerSelection.currentRegionIndex), .(0, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 11, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Center: <{},{},{}>", (int)metadata.centerX * 16, (int)metadata.centerY * 16, (int)metadata.centerZ * 16), .(0, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 10, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Offset: <{},{},{}>", (int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), .(0, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 9, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Scaled Vertically: {}", metadata.verticallyScaledDown), .(0, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 8, 0), .(255,255,255));
	
					int faceIndex = ?;
					if (ViewerSelection.currentRegionTransparent) {
						faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
					} else {
						faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
					}
	
					let face = &visualMesh.nearFaces[faceIndex];
					
					let quadCount = Emulator.installment == .SpyroTheDragon ? 21 : 6;
					TextureQuad* textureInfo = &Terrain.textureInfos[face.renderInfo.textureIndex * quadCount];
					if (Emulator.installment != .SpyroTheDragon) {
						textureInfo++;
					}
					
					const let quadSize = TextureQuad.quadSize;
					
					DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height, 256, 490, .(0,0,0,128));
	
					var partialUV = textureInfo[0].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height, 0,128, partialUV.leftY, partialUV.leftY + quadSize, partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
	
					partialUV = textureInfo[1].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height - 64, 128,128 + 64, partialUV.leftY, partialUV.leftY + quadSize, partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
	
					partialUV = textureInfo[2].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height - 64, 128 + 64,128 + 128, partialUV.leftY, partialUV.leftY + quadSize, partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
	
					partialUV = textureInfo[3].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - 64, WindowApp.height, 128,128 + 64, partialUV.leftY, partialUV.leftY + quadSize, partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
	
					partialUV = textureInfo[4].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - 64, WindowApp.height, 128 + 64, 256, partialUV.leftY, partialUV.leftY + quadSize, partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
					
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Face Index: {}", faceIndex), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 6, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Tex Index: {}", face.renderInfo.textureIndex), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 5, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Rotation: {}", face.renderInfo.rotation), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 4, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Mirror: {}", face.flipped), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 3, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Depth Offset: {}", face.renderInfo.depthOffset), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight * 2, 0), .(255,255,255));
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Double Sided: {}", face.renderInfo.doubleSided), .(260, WindowApp.height - (.)WindowApp.bitmapFont.characterHeight, 0), .(255,255,255));
	
				} else if (terrain.drawnRegion > -1) {
					// Background
					DrawUtilities.Rect((.)WindowApp.height - (26), WindowApp.height - 4, 4, 4 + 12 * 8 + 36,
						.(0,0,0,192));
	
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Region {}", terrain.drawnRegion), .(8, (.)WindowApp.height - (8 + 15), 0), .(255,255,255));
				}
			}

			if (!Translator.hovered) {
				// Print list of objects currently under the cursor
				if (ViewerSelection.hoveredObjects.Count > 0) {
					DrawUtilities.Rect(WindowApp.mousePosition.y + 16, WindowApp.mousePosition.y + 16 + WindowApp.bitmapFont.characterHeight * ViewerSelection.hoveredObjects.Count, WindowApp.mousePosition.x + 16, WindowApp.mousePosition.x + 16 + WindowApp.bitmapFont.characterWidth * 16, .(0,0,0,192));
				}
				for	(let i < ViewerSelection.hoveredObjects.Count) {
					let hoveredObject = ViewerSelection.hoveredObjects[i];
					Renderer.Color textColor = .(255,255,255);
					if (hoveredObject.index == ViewerSelection.currentObjIndex) {
						textColor = .(0,0,0);
						DrawUtilities.Rect(WindowApp.mousePosition.y + 16 + i * WindowApp.bitmapFont.characterHeight, WindowApp.mousePosition.y + 16 + (i + 1) * WindowApp.bitmapFont.characterHeight, WindowApp.mousePosition.x + 16, WindowApp.mousePosition.x + 16 + WindowApp.bitmapFont.characterWidth * 16, .(255,255,255,192));
					}
					DrawMobyIcon(objectList[hoveredObject.index].1, .(WindowApp.mousePosition.x + 28 + WindowApp.bitmapFont.characterWidth * 16, WindowApp.mousePosition.y + 16 + WindowApp.bitmapFont.characterHeight * (0.5f + i), 0), 0.75f);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]: {:X4}", objectList[hoveredObject.index].0, (objectList[hoveredObject.index].1).objectTypeID), .( WindowApp.mousePosition.x + 16,  WindowApp.mousePosition.y + 18 + i * WindowApp.bitmapFont.characterHeight,0), textColor);
				}
			}

			// Begin window relative position UI
			if (!cornerMenuVisible) {
				DrawMessageFeed();
			}
			DrawUtilities.Rect(0,260,0,200 * cornerMenuInterp, .(0,0,0,192));
			DrawUtilities.Rect(0,WindowApp.height,WindowApp.width - 300 * sideInspectorInterp,WindowApp.width, .(0,0,0,192));

			// Corner Menu
			for (let element in guiElements) {
				if (element.GetVisibility()) {
					let parentRect = element.parent != null ? element.parent.drawn : GUIElement.Rect(0, WindowApp.width, 0, WindowApp.height);
					element.Draw(parentRect);
				}
			}

			for (let toggle in toggleList) {
				if (toggle.button.visible) {
					WindowApp.fontSmall.Print(toggle.label, .(toggle.button.drawn.right + 8, toggle.button.drawn.top + 1, 0), .(255,255,255));
				}
			}

			// Side Inspector
			if (ViewerSelection.currentObjIndex > -1) {
				let (address, object) = objectList[ViewerSelection.currentObjIndex];
				WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]", address), .(sideInspector.drawn.left + 22, 3, 0), .(255,255,255));
				int line = 0;
				WindowApp.bitmapFont.Print(scope String() .. AppendF("State {} ({})", object.updateState, object.IsActive ? "Active" : "Inactive"), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				line++;
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Pos {}", object.position), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Rot {},{},{}", object.eulerRotation.x,object.eulerRotation.y,object.eulerRotation.z),
					.(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Model {}:{}", object.objectTypeID, object.modelID), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("LOD Distance {} ({})", object.lodDistance, object.lodDistance * 1000), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Color {},{},{},{}", object.color.r, object.color.g, object.color.b, object.color.a), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				line++;
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Type {}", object.objectTypeID), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Sub-Type? {}", object.objectSubTypeID), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Variant? {}", object.variantID), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Data [{}]", object.dataPointer), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
				line++;
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Gem-Value {}", (int8)object.heldGemValue), .(sideInspector.drawn.left + 8, 32 + 20 * line++, 0), .(255,255,255));
			}

			if (Emulator.loadingStatus == .Loading) {
				// Darken everything
				DrawUtilities.Rect(0,WindowApp.height,0,WindowApp.width, .(0,0,0,192));

				let loadingMessage = "Loading...";
				var halfWidth = Math.Round(WindowApp.font.CalculateWidth(loadingMessage) / 2);
				var baseline = WindowApp.height / 2 - WindowApp.font.height;
				let middleWindow = WindowApp.width / 2;
				WindowApp.font.Print(loadingMessage, .(middleWindow - halfWidth, baseline, 0), .(255,255,255));

				var line = 0;
				for (let i < 8) {
					if (!Emulator.changedPointers[i]) {
						halfWidth = WindowApp.fontSmall.CalculateWidth(Emulator.pointerLabels[i]) / 2;
						baseline = WindowApp.height / 2 + (.)(WindowApp.fontSmall.height * line);
						WindowApp.fontSmall.Print(Emulator.pointerLabels[i], .(Math.Round(middleWindow - halfWidth), baseline, 0), .(255,255,255));
						line++;
					}
				}
			}
		}

		public override bool OnEvent(SDL2.SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (GUIElement.hoveredElement != null) {
						GUIElement.pressedElement = .hoveredElement;
						GUIElement.pressedElement.Pressed();
					} else {
						if (event.button.button == 3) {
							SDL.SetRelativeMouseMode(viewMode != .Map);
							cameraHijacked = true;
							if (viewMode == .Game && !Emulator.CameraMode) {
								toggleList[4].button.Pressed();
							}
						}
						if (event.button.button == 1) {
							if (showManipulator) {
								Translator.MousePress(WindowApp.mousePosition);
								if (Translator.hovered) {
									Translator.OnDragBegin.Dispose();
									Translator.OnDragged.Dispose();
									Translator.OnDragEnd.Dispose();
	
									if (ViewerSelection.currentObjIndex > -1) {
										Translator.OnDragged.Add(new (position) => {
											var (address, moby) = objectList[ViewerSelection.currentObjIndex];
											moby.position = position.ToVectorInt();
											address.Write(&moby);
										});
									} else if (terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
										Translator.OnDragged.Add(new (position) => {
											var triangle = terrain.collision.triangles[ViewerSelection.currentTriangleIndex].Unpack(false);
											triangle[0] = position.ToVectorInt();
											terrain.collision.SetNearVertex((.)ViewerSelection.currentTriangleIndex, triangle, true);
										});
									} else {
										Translator.OnDragBegin.Add(new => Emulator.KillSpyroUpdate);
										Translator.OnDragged.Add(new (position) => {
											Emulator.spyroPosition = position.ToVectorInt();
											Emulator.spyroPositionAddresses[(int)Emulator.rom].Write(&Emulator.spyroPosition);
										});
										Translator.OnDragEnd.Add(new => Emulator.RestoreSpyroUpdate);
									}
								}
							}

							if (!(showManipulator && Translator.hovered)) {
								Selection.Select();
							}
						}
					}
				}
				case .MouseMotion : {
					if (cameraHijacked) {
						switch (viewMode) {
							case .Free: {
								viewEulerRotation.z -= (.)event.motion.xrel * 0.001f;
								viewEulerRotation.x += (.)event.motion.yrel * 0.001f;
								viewEulerRotation.x = Math.Clamp(viewEulerRotation.x, -0.5f, 0.5f);
							}
							case .Game: {
								int16[3] cameraEulerRotation = ?;	
								Emulator.cameraEulerRotationAddress[(int)Emulator.rom].Read(&cameraEulerRotation);
		
								cameraEulerRotation[2] -= (.)event.motion.xrel * 2;
								cameraEulerRotation[1] += (.)event.motion.yrel * 2;
								cameraEulerRotation[1] = Math.Clamp(cameraEulerRotation[1], -0x400, 0x400);
		
								// Force camera view basis in game
								Emulator.cameraBasisInv = MatrixInt.Euler(0, (float)cameraEulerRotation[1] / 0x800 * Math.PI_f, (float)cameraEulerRotation[2] / 0x800 * Math.PI_f);
		
								Emulator.cameraMatrixAddress[(int)Emulator.rom].Write(&Emulator.cameraBasisInv);
								Emulator.cameraEulerRotationAddress[(int)Emulator.rom].Write(&cameraEulerRotation);
							}
							case .Map: {
								var translationX = -Camera.size * event.motion.xrel / WindowApp.height;
								var translationY = Camera.size * event.motion.yrel / WindowApp.height;

								Camera.position.x += translationX;
								Camera.position.y += translationY;
							}
						}
					} else {
						if (Emulator.loadingStatus == .Idle) {
							cornerMenuVisible = !Translator.dragged && (cornerMenuVisible && WindowApp.mousePosition.x < 200 || WindowApp.mousePosition.x < 10) && WindowApp.mousePosition.y < 260;
							sideInspectorVisible = !Translator.dragged && ViewerSelection.currentObjIndex > -1 && (pinInspectorButton.value || (sideInspectorVisible && WindowApp.mousePosition.x > WindowApp.width - 300 || WindowApp.mousePosition.x > WindowApp.width - 10));
						} else {
							cornerMenuVisible = sideInspectorVisible = false;
						}

						let lastHoveredElement = GUIElement.hoveredElement;
						GUIElement.hoveredElement = null;
						for (let element in guiElements) {
							element.MouseUpdate(WindowApp.mousePosition);
						}
						if (lastHoveredElement != GUIElement.hoveredElement) {
							lastHoveredElement?.MouseExit();
							GUIElement.hoveredElement?.MouseEnter();
						}

						if (showManipulator && Translator.MouseMove(WindowApp.mousePosition)) {
							Selection.Clear();
						} else if (Emulator.loadingStatus != .Loading && Emulator.gameState == 0) {
							Selection.Test();
						}
					}
				}
				case .MouseButtonUp : {
					if (GUIElement.pressedElement != null) { // Focus was on GUI
						GUIElement.pressedElement.Unpressed();
						GUIElement.pressedElement = null;
					} else {
						if (event.button.button == 3) {	
							SDL.SetRelativeMouseMode(false);
							cameraHijacked = false;
							cameraMotion = .(0,0,0);
						}
					}

					Translator.MouseRelease();
				}
				case .MouseWheel : {
					if (viewMode == .Map) {
						Camera.size -= Camera.size / 8 * (.)event.wheel.y;

						WindowApp.viewerProjection = Camera.projection;
					} else {
						cameraSpeed += (.)event.wheel.y;
						if (cameraSpeed < 8) {
							cameraSpeed = 8;
						}
					}
				}
				case .KeyDown : {
					if (event.key.isRepeat == 0) {
						switch (event.key.keysym.scancode) {
							case .P : {
								TogglePause();
							}
							case .LCtrl : {
								cameraSpeed *= 8;
								cameraMotion *= 8;
							}
							case .M : {
								toggleList[0].button.Pressed();
							}
							case .O : {
								toggleList[1].button.Pressed();
							}
							case .L : {
								CycleTerrainOverlay();
							}
							case .K : {
								uint32 health = 0;
								Emulator.healthAddresses[(int)Emulator.rom].Write(&health);
							}
							case .T : {
								if (Emulator.CameraMode) {
									Teleport();
								}
							}
							case .C : {
								toggleList[4].button.Pressed();
							}
							case .H : {
								toggleList[3].button.Pressed();
							}
							case .I : {
								toggleList[2].button.Pressed();

								/*// Does not currently work as intended
								if (Emulator.InputMode) {
									Emulator.RestoreInputRelay();
									PushMessageToFeed("Emulator Input");
								} else {
									Emulator.KillInputRelay();
									PushMessageToFeed("Manual Input");
								}*/
							}
							case .E : {
								if (!Translator.dragged) {
									toggleList[7].button.Pressed();
								}
							}
							case .KpPlus : {
								terrain.drawnRegion++;
							}
							case .KpMinus : {
								terrain.drawnRegion--;
							}
							case .V : {
								windowApp.GoToState<VRAMViewerState>();
							}
							default : {}
						}
	
						switch (event.key.keysym.scancode) {
							case .W :
								cameraMotion.z -= cameraSpeed;
							case .S :
								cameraMotion.z += cameraSpeed;
							case .A :
								cameraMotion.x -= cameraSpeed;
							case .D :
								cameraMotion.x += cameraSpeed;
							case .Space :
								cameraMotion.y += cameraSpeed;
							case .LShift :
								cameraMotion.y -= cameraSpeed;
							default :
						}
					}
				}
				case .KeyUp : {
					if (event.key.keysym.scancode == .LCtrl) {
						cameraSpeed /= 8;
						cameraMotion /= 8;
					}

					switch (event.key.keysym.scancode) {
						case .W :
							cameraMotion.z = 0;
						case .S :
							cameraMotion.z = 0;
						case .A :
							cameraMotion.x = 0;
						case .D :
							cameraMotion.x = 0;
						case .Space :
							cameraMotion.y = 0;
						case .LShift :
							cameraMotion.y = 0;
						default :
					}
				}
				case .JoyDeviceAdded : {
					Console.WriteLine("Controller Connected");
				}
				case .JoyButtonDown : {
					Console.WriteLine("jButton {}", event.jbutton.button);
				}
				case .ControllerDeviceadded : {
					Console.WriteLine("Controller Connected");
				}
				case .ControllerButtondown : {
					Console.WriteLine("cButton {}", event.jbutton.button);
				}
				default : return false;
			}

			return true;
		}

		void DrawMoby(Moby object) {
			if (Emulator.installment == .SpyroTheDragon) {
				return; // Ignore drawing models for Spyro 1 for now
			}

			if (object.HasModel) {
				if (modelSets.ContainsKey(object.objectTypeID)) {
					let basis = Matrix.Euler(
						-(float)object.eulerRotation.x / 0x80 * Math.PI_f,
						(float)object.eulerRotation.y / 0x80 * Math.PI_f,
						-(float)object.eulerRotation.z / 0x80 * Math.PI_f
					);

					Renderer.SetModel(object.position, basis * 2);
					Renderer.SetTint(object.IsActive ? .(255,255,255) : .(32,32,32));
					modelSets[object.objectTypeID].models[object.modelID].QueueInstance();
				} else {
					Emulator.Address modelSetAddress = ?;
					Emulator.ReadFromRAM(Emulator.modelPointers[(int)Emulator.rom] + 4 * object.objectTypeID, &modelSetAddress, 4);

					if (modelSetAddress != 0 && (int32)modelSetAddress > 0) {
						modelSets.Add(object.objectTypeID, new .(modelSetAddress));
					}
				}
			}
		}

		void DrawMobyIcon(Moby object, Vector screenPosition, float scale) {
			switch (object.objectTypeID) {
				case 0xca:
				case 0xcb:
				default:
					switch (object.heldGemValue) {
						case 1: case 2: case 5: case 10: case 25: // Allow any of these values to pass
						default: return; // If the data does not contain a valid gem value, skip drawing an icon
					}
		
					Texture containerIcon = object.objectTypeID == 1 ? null : gemHolderIconTexture;
					Renderer.Color iconTint = .(128,128,128);
					switch (object.objectTypeID) {
						case 0xc8:
							iconTint = .(222,128,90);
							containerIcon = basketIconTexture;
						case 0xc9:
							iconTint = .(90,128,222);
							containerIcon = vaseIconTexture;
						case 0xd1:
							iconTint = .(64,222,0);
							containerIcon = bottleIconTexture;
					}
		
					if (containerIcon != null) {
						let halfWidth = vaseIconTexture.width / 2 * scale;
						let halfHeight = vaseIconTexture.height / 2 * scale;
						DrawUtilities.Rect(screenPosition.y - halfHeight, screenPosition.y + halfHeight, screenPosition.x - halfWidth, screenPosition.x + halfWidth, 0,1,0,1, containerIcon, iconTint);
					}
		
					var halfWidth = (float)gemIconTexture.width / 2 * scale;
					var halfHeight = (float)gemIconTexture.height / 2 * scale;
		
					if (containerIcon != null) {
						halfWidth *= 0.75f;
						halfHeight *= 0.75f;
					}
		
					Renderer.Color color = .(255,255,255);
					switch (object.heldGemValue) {
						case 1: color = .(255,0,0);
						case 2: color = .(0,255,0);
						case 5: color = .(90,64,255);
						case 10: color = .(255,180,0);
						case 25: color = .(255,90,255);
					}
		
					DrawUtilities.Rect(screenPosition.y - halfHeight, screenPosition.y + halfHeight, screenPosition.x - halfWidth, screenPosition.x + halfWidth, 0,1,0,1, gemIconTexture, color);
			}
		}

		void UpdateView() {
			if (viewMode == .Game) {
				Camera.position = Emulator.cameraPosition;
				viewEulerRotation.x = (float)Emulator.cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)Emulator.cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)Emulator.cameraEulerRotation[2] / 0x800;
			}

			viewEulerRotation.z = Math.Repeat(viewEulerRotation.z + 1, 2) - 1;

			// Corrected view matrix for the scope
			Camera.basis = Matrix.Euler(
				(viewEulerRotation.x - 0.5f) * Math.PI_f,
				viewEulerRotation.y  * Math.PI_f,
				(0.5f - viewEulerRotation.z) * Math.PI_f
			);

			// Move camera
			if (viewMode == .Map) {
				Camera.position.x += Camera.size / 0x1000 * cameraMotion.x;
				Camera.position.y -= Camera.size / 0x1000 * cameraMotion.z;
			} else if (cameraHijacked) {
				let cameraMotionDirection = Camera.basis * cameraMotion;
				
				if (viewMode == .Free) {
					Camera.position += cameraMotionDirection;
				} else {
					let cameraNewPosition = Emulator.cameraPosition.ToVector() + cameraMotionDirection;
					Emulator.cameraPosition = cameraNewPosition.ToVectorInt();
					Emulator.SetCameraPosition(&Emulator.cameraPosition);
				}
			}
		}
		
		void OnSceneChanging() {
			Selection.Reset();
		}

		void OnSceneChanged() {
			VRAM.TakeSnapshot();

			Terrain.RenderMode lastMode = .Collision;
			TerrainCollision.Overlay lastOverlay = .None;
			if (terrain != null) {
				lastMode = terrain.renderMode;
				lastOverlay = terrain.collision.overlay;
				
				delete terrain;
			}

			terrain = new .();
			terrain.renderMode = lastMode;
			terrain.collision.SetOverlay(lastOverlay);
		}

		void PushMessageToFeed(String message) {
			messageFeed.Add((message, .Now + TimeSpan(0, 0, 2)));
		}

		void DrawGameCameraFrustrum() {
			let cameraBasis = Emulator.cameraBasisInv.ToMatrixCorrected().Transpose();
			let cameraBasisCorrected = Matrix(cameraBasis.y, cameraBasis.z, -cameraBasis.x);

			Renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			Renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			Renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let projectionMatrixInv = WindowApp.gameProjection.Inverse();
			let viewProjectionMatrixInv = cameraBasisCorrected * projectionMatrixInv;

			let farTopLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let farTopRight = (Vector)(viewProjectionMatrixInv * Vector4(1,1,1,1)) + Emulator.cameraPosition.ToVector();
			let farBottomLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,-1,1,1)) + Emulator.cameraPosition.ToVector();
			let farBottomRight = (Vector)(viewProjectionMatrixInv * Vector4(1,-1,1,1)) + Emulator.cameraPosition.ToVector();

			let nearTopLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearTopRight = (Vector)(viewProjectionMatrixInv * Vector4(1,1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearBottomLeft = (Vector)(viewProjectionMatrixInv * Vector4(-1,-1,-1,1)) + Emulator.cameraPosition.ToVector();
			let nearBottomRight = (Vector)(viewProjectionMatrixInv * Vector4(1,-1,-1,1)) + Emulator.cameraPosition.ToVector();

			Renderer.DrawLine(nearTopLeft, farTopLeft , .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearTopRight, farTopRight, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearBottomLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearBottomRight, farBottomRight, .(16,16,16), .(16,16,16));
			
			Renderer.DrawLine(nearTopLeft, nearTopRight, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearBottomLeft, nearBottomRight, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearTopLeft, nearBottomLeft, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(nearTopRight, nearBottomRight, .(16,16,16), .(16,16,16));

			Renderer.DrawLine(farTopLeft, farTopRight, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(farBottomLeft, farBottomRight, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(farTopLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			Renderer.DrawLine(farTopRight, farBottomRight, .(16,16,16), .(16,16,16));
		}

		void DrawSpyroInformation() {
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroIntendedVelocity / 10, 25, .(255,255,0));
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroPhysicsVelocity / 10, 50, .(255,128,0));

			let viewerSpyroBasis = Emulator.spyroBasis.ToMatrixCorrected();
			Renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			Renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			Renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let radius = 0x164;

			DrawUtilities.WireframeSphere(Emulator.spyroPosition, viewerSpyroBasis, radius, .(32,32,32));
		}

		void DrawMessageFeed() {
			let now = DateTime.Now;

			messageFeed.RemoveAll(scope (x) => {
				let pendingRemove = now > x.time;
				if (pendingRemove && x.message.IsDynAlloc) {
					delete x.message;
				}
				return now > x.time;
			});

			for (let i < messageFeed.Count) {
				let feedItem = messageFeed[i];
				let message = feedItem.message;
				let age = feedItem.time - now;
				let fade = Math.Min(age.TotalSeconds, 1);
				let offsetOrigin = Vector(0,(messageFeed.Count - i - 1) * WindowApp.font.height,0);
				DrawUtilities.Rect(offsetOrigin.y, offsetOrigin.y + WindowApp.font.height, offsetOrigin.x, offsetOrigin.x + WindowApp.font.CalculateWidth(message) + 4,
					.(0,0,0,(.)(192 * fade)));
				WindowApp.font.Print(message, offsetOrigin + .(2,0,0), .(255,255,255,(.)(255 * fade)));
			}
		}

		void DrawFlagsOverlay() {
			if (ViewerSelection.currentTriangleIndex > -1 && ViewerSelection.currentTriangleIndex < terrain.collision.specialTriangleCount) {
				let flagInfo = terrain.collision.flagIndices[ViewerSelection.currentTriangleIndex];
				let flagIndex = flagInfo & 0x3f;
				let flagData = terrain.collision.GetCollisionFlagData(flagIndex);
	
				if (flagData.type == 0 || flagData.type == 3 || flagData.type == 6 || flagData.type == 7) {
					var screenPosition = Camera.SceneToScreen(cursor3DPosition);
					screenPosition.x = Math.Floor(screenPosition.x);
					screenPosition.y = Math.Floor(screenPosition.y);
					screenPosition.z = 0;
					DrawUtilities.Rect(screenPosition.y, screenPosition.y + WindowApp.bitmapFont.characterHeight, screenPosition.x, screenPosition.x + WindowApp.bitmapFont.characterWidth * 10,
						.(0,0,0,192));
		
					screenPosition.y += 2;
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Param: {}", flagData.param),
						screenPosition, .(255,255,255));
				}
			}

			// Legend
			let leftPaddingBG = 4;
			let bottomPaddingBG = 4;

			// Background
			let backgroundHeight = 18 * terrain.collision.collisionTypes.Count + 2;
			DrawUtilities.Rect((.)WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 8 + 36,
				.(0,0,0,192));

			// Content
			for (let i < terrain.collision.collisionTypes.Count) {
				let flag = terrain.collision.collisionTypes[i];
				String label = scope String() .. AppendF("Unknown {}", flag);
				Renderer.Color color = .(255, 0, 255);
				if (flag < 11 /*Emulator.collisionTypes.Count*/) {
					(label, color) = Emulator.collisionTypes[flag];
				}

				let leftPadding = 8;
				let bottomPadding = 8 + 18 * i;
				DrawUtilities.Rect((.)WindowApp.height - (bottomPadding + 16), (.)WindowApp.height - bottomPadding, leftPadding, leftPadding + 16, color);

				WindowApp.bitmapFont.Print(label, .(leftPadding + 24, (.)WindowApp.height - (bottomPadding + 15), 0), .(255,255,255));
			}
		}

		void TogglePause() {
			if (Emulator.PausedMode) {
				Emulator.RestoreUpdate();
				PushMessageToFeed("Resumed Game Update");
				togglePauseButton.iconTexture = pauseTexture;
			} else {
				Emulator.KillUpdate();
				PushMessageToFeed("Paused Game Update");
				togglePauseButton.iconTexture = playTexture;
			}
		}

		void Step() {
			togglePauseButton.iconTexture = playTexture;
			Emulator.Step();
		}

		void ToggleWireframe(bool toggle) {
			terrain.wireframe = toggle;
			PushMessageToFeed("Toggled Wireframe");
		}

		void ToggleOrigins(bool toggle) {
			drawObjectOrigins = toggle;
			PushMessageToFeed("Toggled Object Origins");
		}

		void ToggleInactive(bool toggle) {
			hideInactive = toggle;
			PushMessageToFeed("Toggled Inactive Visibility");
		}

		void ToggleView(ViewMode mode) {
			if (viewMode == .Map && mode != .Map) {
				Camera.orthographic = false;
				Camera.near = 100;
				Camera.far = 500000;

				Camera.position = Emulator.cameraPosition;
				viewEulerRotation.x = (float)Emulator.cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)Emulator.cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)Emulator.cameraEulerRotation[2] / 0x800;

				WindowApp.viewerProjection = Camera.projection;
			} else if (viewMode != .Map && mode == .Map)  {
				let upperBound = terrain.collision.upperBound;
				let lowerBound = terrain.collision.lowerBound;

				Camera.orthographic = true;
				Camera.near = 0;
				Camera.far = upperBound.z * 1.1f;

				Camera.position.x = (upperBound.x + lowerBound.x) / 2;
				Camera.position.y = (upperBound.y + lowerBound.y) / 2;
				Camera.position.z = upperBound.z * 1.1f;

				let mapSize = upperBound - lowerBound;
				let aspect = (float)WindowApp.width / WindowApp.height;
				if (mapSize.x / mapSize.y > aspect) {
					Camera.size = mapSize.x / aspect;
				} else {
					Camera.size = mapSize.y;
				}

				viewEulerRotation = .(0.5f,0,0.5f);
				WindowApp.viewerProjection = Camera.projection;
			}

			viewMode = mode;

			switch (viewMode) {
				case .Free: PushMessageToFeed("Free View");
				case .Game: PushMessageToFeed("Game View");
				case .Map: PushMessageToFeed("Map View");
			}
		}

		void ToggleFreeCamera(bool toggle) {
			if (toggle) {
				Emulator.KillCameraUpdate();
				PushMessageToFeed("Free Camera");
				teleportButton.enabled = true;
			} else {
				Emulator.RestoreCameraUpdate();
				PushMessageToFeed("Game Camera");
				teleportButton.enabled = false;
			}
		}

		void ToggleLimits(bool toggle) {
			drawLimits = toggle;
			PushMessageToFeed("Toggled Height Limits");
		}

		void CycleTerrainOverlay() {
			if (terrain.collision.overlay == .Deform) {
				ViewerSelection.currentAnimGroupIndex = -1;
			}

			terrain.collision.CycleOverlay();

			String overlayType;
			switch (terrain.collision.overlay) {
				case .None: overlayType = "None";
				case .Flags: overlayType = "Flags";
				case .Deform: overlayType = "Deform";
				case .Water: overlayType = "Water";
				case .Sound: overlayType = "Sound";
				case .Platform: overlayType = "Platform";
			}
			PushMessageToFeed(new String() .. AppendF("Terrain Overlay [{}]", overlayType));
		}

		void Teleport() {
			Emulator.spyroPosition = Camera.position.ToVectorInt();
			Emulator.spyroPositionAddresses[(int)Emulator.rom].Write(&Emulator.spyroPosition);
			PushMessageToFeed("Teleported Spyro to Game Camera");
		}
	}
}
