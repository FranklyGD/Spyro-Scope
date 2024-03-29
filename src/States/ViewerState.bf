using SDL2;
using System;
using System.Collections;
using System.IO;

namespace SpyroScope {
	class ViewerState : WindowState {
		// Timestamps
		DateTime lastUpdatedSceneChanging;
		DateTime lastUpdatedSceneChange;

		// View
		enum ViewMode {
			Game,
			Free,
			Lock,
			Map
		}

		enum RenderMode {
			Collision,
			Far,
			Near,
			NearSubdivided
		}

		ViewMode viewMode = .Game;

		/// Is in-game camera no being updated externally
		bool cameraHijacked;

		float cameraSpeed = 64;

		/// The overall motion direction
		Vector3 cameraMotionDirection;

		Vector3 viewEulerRotation;
		Vector3 lockOffset;

		// Options
		bool drawObjectModels = true;
		bool drawObjectExperimentalModels = false;
		bool drawObjectOrigins = true;
		public static bool showInactive = false;
		bool displayIcons = false;
		bool displayAllData = false;

		// Scene
		bool drawLimits;

		// Objects
		Dictionary<uint16, MobyModelSet> modelSets = new .();

		// UI
		public static Vector3 cursor3DPosition;

		List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		MessageFeed messageFeed;
		Button togglePauseButton, stepButton;

		Texture playTexture = new .("images/ui/play.png") ~ delete _; 
		Texture pauseTexture = new .("images/ui/pause.png") ~ delete _; 
		Texture stepTexture = new .("images/ui/step.png") ~ delete _;

		Texture toggledTexture = new .("images/ui/toggle_enabled.png") ~ delete _;

		Texture gemIconTexture = new .("images/ui/icon_gem.png") ~ delete _;
		Texture gemHolderIconTexture = new .("images/ui/icon_gem_holder.png") ~ delete _;
		Texture basketIconTexture = new .("images/ui/icon_basket.png") ~ delete _;
		Texture vaseIconTexture = new .("images/ui/icon_vase.png") ~ delete _;
		Texture bottleIconTexture = new .("images/ui/icon_bottle.png") ~ delete _;

		ViewerMenu viewerMenu;
		bool cornerMenuVisible;
		float cornerMenuInterp;

		Panel sideInspector;
		bool sideInspectorVisible;
		float sideInspectorInterp;

		Inspector inspector;

		Toggle pinInspectorButton;

		Timeline timeline;

		Toggle flipNormalToggle, doubleSidedToggle;

		// Other
		Vector3Int[3] grabbedTriangle;

		public this() {
			ViewerSelection.Init();
			GUIElement.SetActiveGUI(guiElements);

			togglePauseButton = new .();

			togglePauseButton.Anchor = .(0.5f, 0.5f, 0, 0);
			togglePauseButton.Offset = .(-16, 16, -16, 16);
			togglePauseButton.Offset.Shift(-16, 32);
			togglePauseButton.OnActuated.Add(new => TogglePause);

			stepButton = new .();

			stepButton.Anchor = .(0.5f, 0.5f, 0, 0);
			stepButton.Offset = .(-16, 16, -16, 16);
			stepButton.Offset.Shift(16, 32);
			stepButton.iconTexture = stepTexture;
			stepButton.OnActuated.Add(new => Step);
			
			viewerMenu = new .(this);

			messageFeed = new .();
			messageFeed.Anchor.start = .(1,0);
			messageFeed.Parent(viewerMenu);

			sideInspector = new .();
			sideInspector.Anchor = .(1,1,0,1);
			sideInspector.Offset = .(-300,0,0,0);
			sideInspector.texture = GUIElement.bgTexture;
			sideInspector.tint = .(0,0,0);

			pinInspectorButton = new .();
			pinInspectorButton.Offset = .(0, 16, 0, 16);
			pinInspectorButton.Offset.Shift(2,2);
			pinInspectorButton.Parent(sideInspector);

			timeline = new .();
			timeline.Anchor = .(0, 1, 1, 1);
			timeline.Offset = .(0, 0, -100, 0);
			timeline.visible = false;
		}

		public ~this() {
			Terrain.Dispose();

			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			delete modelSets;

			Recording.ClearRecord();
		}

		public override void Enter() {
			GUIElement.SetActiveGUI(guiElements);
			Selection.OnSelect.Add(new => OnSelect);

			togglePauseButton.iconTexture = Emulator.active.Paused ? playTexture : pauseTexture;
			stepButton.Enabled = Emulator.active.Paused;

			viewerMenu.freecamToggle.value = viewerMenu.teleportButton.Enabled = Emulator.active.CameraMode;
		}

		public override void Exit() {
			GUIElement.SetActiveGUI(null);
			Selection.OnSelect.Remove(scope => OnSelect, true);
		}

		public override void Update() {
			Emulator.active.CheckProcessStatus();
			Emulator.active.FindGame();

			// If there is no emulator or relevant game present, return to the setup screen
			if (Emulator.active == null || Emulator.active.rom == .None) {
				windowApp.GoToState<SetupState>();
				return;
			}

			Emulator.active.FetchImportantData();

			// Check if events occurred based on time
			if (Emulator.active.lastSceneChanging > lastUpdatedSceneChanging) {
				OnSceneChanging();
			}
			if (Emulator.active.lastSceneChange > lastUpdatedSceneChange) {
				OnSceneChanged();
			}

			if (!Terrain.decoded && VRAM.upToDate) {
				Terrain.Decode();
			}

			UpdateCameraMotion();
			UpdateView();

			var objPointer = Emulator.active.objectArrayAddress;

			// Read last known size amount of objects
			objPointer.ReadArray(Moby.allocated.Ptr, Moby.allocated.Count);

			objPointer += Moby.allocated.Count * sizeof(Moby);

			if (Emulator.active.loadingStatus == .Idle) {
				// Get remaining objects not saved in the allocated cache
				while (true) {
					Moby object = ?;
					objPointer.Read(&object);
	
					if (object.IsTerminator) {
						break;
					}

					Moby.allocated.Add(object);
					
					objPointer += sizeof(Moby);
				}
			}

			sideInspectorInterp = Math.MoveTo(sideInspectorInterp, sideInspectorVisible ? 1 : 0, 0.1f);
			sideInspector.Offset = .(.(-300 * sideInspectorInterp,0), .(300,0));

			if (Emulator.active.loadingStatus == .Loading) {
				return;
			}

			Terrain.Update();

			if (viewerMenu.manipulatorToggle.value && (Emulator.active.loadingStatus == .Idle && Emulator.active.gameState <= 1)) {
				UpdateManipulator();
			}
		}

		public override void DrawView() {
			if (Terrain.renderMode == .Collision) {
				Renderer.clearColor = .(0,0,0);
			} else {
				Emulator.backgroundClearColorAddress[(int)Emulator.active.rom].Read(&Renderer.clearColor);
				Renderer.clearColor.r = (.)(Math.Pow((float)Renderer.clearColor.r / 255, 2.2f) * 255);
				Renderer.clearColor.g = (.)(Math.Pow((float)Renderer.clearColor.g / 255, 2.2f) * 255);
				Renderer.clearColor.b = (.)(Math.Pow((float)Renderer.clearColor.b / 255, 2.2f) * 255);
				Renderer.clearColor.a = 255;
			}

			Terrain.Draw();

			if (viewMode != .Game) {
				DrawGameCameraFrustrum();
			}
			
			DrawObjects();

			if (ViewerSelection.currentRegionIndex > 0) {
				let region = Terrain.regions[ViewerSelection.currentRegionIndex];
				DrawUtilities.Axis(region.Center, .Scale(1000));
				DrawUtilities.WireframeSphere(region.Center, .Identity, region.Radius, .(0,0,0));
			}

			if (ViewerSelection.hoveredObjIndex >= Moby.allocated.Count || ViewerSelection.currentObjIndex >= Moby.allocated.Count) {
				Selection.Reset();
				ViewerSelection.hoveredObjects.Clear();
			}

			DrawSpyroInformation();

			for (let modelSet in modelSets.Values) {
				modelSet.DrawInstances();
			}

			// Draw world's origin
			Renderer.DrawLine(.Zero, .(10000,0,0), .(255,255,255), .(255,0,0));
			Renderer.DrawLine(.Zero, .(0,10000,0), .(255,255,255), .(0,255,0));
			Renderer.DrawLine(.Zero, .(0,0,10000), .(255,255,255), .(0,0,255));

			if (drawLimits) {
				DrawLimits();
			}

			DrawRecording();
			
			// Draw all queued instances
			PrimitiveShape.DrawInstances();

			// Draw other primitives queued
			Renderer.SetModel(.Zero, .Identity);
			Renderer.SetTint(.(255,255,255));
			Renderer.Draw();

			Renderer.ClearDepth();

			if (viewerMenu.manipulatorToggle.value) {
			    Translator.Draw();
			}

			PrimitiveShape.DrawInstances();

			Renderer.SetModel(.Zero, .Identity);
			Renderer.SetTint(.(255,255,255));
			Renderer.Draw();
		}

		public override void DrawGUI() {
			if (displayIcons) {
				for (let object in Moby.allocated) {
					if (object.IsTerminator) {
						break;
					}

					if (object.IsActive || showInactive) {
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
			}

			if (Moby.allocated.Count > 0 && ViewerSelection.currentObjIndex > -1) {
				let currentObject = Moby.allocated[ViewerSelection.currentObjIndex];
				// Begin overlays
				var screenPosition = Camera.SceneToScreen(currentObject.position);
				if (drawObjectOrigins && screenPosition.z > 0) { // Must be in front of view
					let screenSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
					screenPosition.z = 0;
					DrawUtilities.Circle(screenPosition, Matrix3.Scale(screenSize,screenSize,screenSize), .(16,16,16));

					if (!sideInspectorVisible) {
						screenPosition.y += screenSize;
						screenPosition.x = Math.Floor(screenPosition.x);
						screenPosition.y = Math.Floor(screenPosition.y);
						DrawUtilities.Rect(screenPosition.y, screenPosition.y + WindowApp.bitmapFont.height * 2, screenPosition.x, screenPosition.x + WindowApp.bitmapFont.characterWidth * 10,
							.(0,0,0,192));

						screenPosition.y += 2;
						WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]", Moby.GetAddress(ViewerSelection.currentObjIndex)),
							(Vector2)screenPosition, .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("TYPE: {:X4}", currentObject.objectTypeID),
							(Vector2)screenPosition + .(0,WindowApp.bitmapFont.height), .(255,255,255));
					}
				}
			}

			if (ViewerSelection.hoveredObjects.Count > 0 && ViewerSelection.hoveredObjIndex > -1) {
				let hoveredObject = Moby.allocated[ViewerSelection.hoveredObjIndex];
				// Begin overlays
				var screenPosition = Camera.SceneToScreen(hoveredObject.position);
				if (screenPosition.z > 0) { // Must be in front of view
					let screenSize = Camera.SceneSizeToScreenSize(150, screenPosition.z);
					screenPosition.z = 0;
					DrawUtilities.Circle(screenPosition, Matrix3.Scale(screenSize,screenSize,screenSize), .(128,64,16));
				}
			}

			if (Terrain.renderMode == .Collision && Terrain.collision != null) {
				if (Terrain.collision.overlay == .Flags) {
					DrawFlagsOverlay();
				} else if (Terrain.collision.overlay == .Deform) {
					if (ViewerSelection.hoveredAnimGroupIndex != -1) {
						let hoveredAnimGroup = Terrain.collision.animationGroups[ViewerSelection.hoveredAnimGroupIndex];
						// Begin overlays
						var screenPosition = Camera.SceneToScreen(hoveredAnimGroup.center);
						if (screenPosition.z > 0) { // Must be in front of view
							let screenSize = Camera.SceneSizeToScreenSize(hoveredAnimGroup.radius - 50, screenPosition.z);
							screenPosition.z = 0;
							DrawUtilities.Circle(screenPosition, Matrix3.Scale(screenSize,screenSize,screenSize), .(128,64,16));
						}
					}

					if (ViewerSelection.currentAnimGroupIndex != -1) {
						let animationGroup = Terrain.collision.animationGroups[ViewerSelection.currentAnimGroupIndex];
						var screenPosition = Camera.SceneToScreen(animationGroup.center);
						if (screenPosition.z > 0) { // Must be in front of view
							let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
							screenPosition.z = 0;
							DrawUtilities.Circle(screenPosition, Matrix3.Scale(screenSize,screenSize,screenSize), .(16,16,0));
						}

						let leftPaddingBG = 4;
						let bottomPaddingBG = 4;

						// Background
						let backgroundHeight = 18 * 6;
						DrawUtilities.Rect(WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 14 + 8,
							.(0,0,0,192));

						// Content
						let currentKeyframe = animationGroup.CurrentKeyframe;
						WindowApp.bitmapFont.Print(scope String() .. AppendF("Group Index {}", ViewerSelection.currentAnimGroupIndex), .(8, WindowApp.height - (18 * 5 + 8 + 15)), .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("Keyframe {}", (uint)currentKeyframe), .(8, WindowApp.height - (18 * 4 + 8 + 15)), .(255,255,255));
						let keyframeData = animationGroup.GetKeyframeData(currentKeyframe);
						WindowApp.bitmapFont.Print(scope String() .. AppendF("Flag {}", (uint)keyframeData.flag), .(8, WindowApp.height - (18 * 3 + 8 + 15)), .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("Interp. {}", (uint)keyframeData.interpolation), .(8, WindowApp.height - (18 * 2 + 8 + 15)), .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("From State {}", (uint)keyframeData.fromState), .(8, WindowApp.height - (18 * 1 + 8 + 15)), .(255,255,255));
						WindowApp.bitmapFont.Print(scope String() .. AppendF("To State {}", (uint)keyframeData.toState), .(8, WindowApp.height - (18 * 0 + 8 + 15)), .(255,255,255));
					} else if (Terrain.collision.animationGroups != null) {
						for (let animationGroup in Terrain.collision.animationGroups) {
							var screenPosition = Camera.SceneToScreen(animationGroup.center);
							if (screenPosition.z > 0) { // Must be in front of view
								let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
								screenPosition.z = 0;
								DrawUtilities.Circle(screenPosition, Matrix3.Scale(screenSize,screenSize,screenSize), .(16,16,0));
							}
						}
					}
				}
			}

			if (!Translator.hovered) {
				// Print list of objects currently under the cursor
				if (ViewerSelection.hoveredObjects.Count > 0) {
					DrawUtilities.Rect(WindowApp.mousePosition.y + 16, WindowApp.mousePosition.y + 16 + WindowApp.bitmapFont.height * ViewerSelection.hoveredObjects.Count, WindowApp.mousePosition.x + 16, WindowApp.mousePosition.x + 16 + WindowApp.bitmapFont.characterWidth * 16, .(0,0,0,192));
				}
				for	(let i < ViewerSelection.hoveredObjects.Count) {
					let hoveredObject = ViewerSelection.hoveredObjects[i];
					Renderer.Color textColor = .(255,255,255);
					if (hoveredObject.index == ViewerSelection.currentObjIndex) {
						textColor = .(0,0,0);
						DrawUtilities.Rect(WindowApp.mousePosition.y + 16 + i * WindowApp.bitmapFont.height, WindowApp.mousePosition.y + 16 + (i + 1) * WindowApp.bitmapFont.height, WindowApp.mousePosition.x + 16, WindowApp.mousePosition.x + 16 + WindowApp.bitmapFont.characterWidth * 16, .(255,255,255,192));
					}
					DrawMobyIcon(Moby.allocated[hoveredObject.index], .(WindowApp.mousePosition.x + 28 + WindowApp.bitmapFont.characterWidth * 16, WindowApp.mousePosition.y + 16 + WindowApp.bitmapFont.height * (0.5f + i), 0), 0.75f);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]: {:X4}", Moby.GetAddress(hoveredObject.index), Moby.allocated[hoveredObject.index].objectTypeID), .(WindowApp.mousePosition.x + 16,  WindowApp.mousePosition.y + 18 + i * WindowApp.bitmapFont.height), textColor);
				}
			}

			if (Terrain.renderMode == .NearLQ && !Terrain.decoded) {
				let message = "Waiting for Unpause...";
				var halfWidth = Math.Round(WindowApp.font.CalculateWidth(message) / 2);
				let middleWindow = WindowApp.width / 2;
				let xOrigin = middleWindow - halfWidth;
				DrawUtilities.Rect(64, 64 + WindowApp.font.height, xOrigin, xOrigin + WindowApp.font.CalculateWidth(message) + 4, .(0,0,0, 192));
				WindowApp.font.Print(message, .(middleWindow - halfWidth, 64), .(255,255,255));
			}

			// Begin window relative position UI
			for (let element in guiElements) {
				if (element.visible) {
					element.Draw();
				}
			}

			// Draw view axis at the top right empty area
			var axisBasis = Matrix3.Scale(20,-20,0.01f) * Camera.basis.Transpose();
			let hudAxisOrigin = Vector3(sideInspector.drawn.left - 30, 30, 0);
			Renderer.DrawLine(hudAxisOrigin, hudAxisOrigin + axisBasis.x, .(255,255,255), axisBasis.x.z > 0 ? .(255,0,0) : .(128,0,0));
			Renderer.DrawLine(hudAxisOrigin, hudAxisOrigin + axisBasis.y, .(255,255,255), axisBasis.y.z > 0 ? .(0,255,0) : .(0,128,0));
			Renderer.DrawLine(hudAxisOrigin, hudAxisOrigin + axisBasis.z, .(255,255,255), axisBasis.z.z > 0 ? .(0,0,255) : .(0,0,128));
			WindowApp.fontSmall.Print("X", .(sideInspector.drawn.left - 30 + axisBasis.x.x, 30 + axisBasis.x.y), axisBasis.x.z > 0 ? .(255,64,64) : .(128,64,64));
			WindowApp.fontSmall.Print("Y", .(sideInspector.drawn.left - 30 + axisBasis.y.x, 30 + axisBasis.y.y), axisBasis.y.z > 0 ? .(64,255,64) : .(64,128,64));
			WindowApp.fontSmall.Print("Z", .(sideInspector.drawn.left - 30 + axisBasis.z.x, 30 + axisBasis.z.y), axisBasis.z.z > 0 ? .(64,64,255) : .(64,64,128));

			if (Emulator.active.loadingStatus == .Loading) {
				DrawLoadingOverlay();
			}
		}

		public override bool OnEvent(SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (event.button.button == 3) {
						SDL.SetRelativeMouseMode(viewMode != .Map);
						cameraHijacked = true;
						if (viewMode == .Game && !Emulator.active.CameraMode) {
							viewerMenu.freecamToggle.Toggle();
						}
					}
					if (event.button.button == 1) {
						if (viewerMenu.manipulatorToggle.value) {
							Translator.MousePress(WindowApp.mousePosition);
							if (Translator.hovered) {
								Translator.OnDragBegin.Dispose();
								Translator.OnDragged.Dispose();
								Translator.OnDragEnd.Dispose();

								if (ViewerSelection.currentObjIndex > -1) {
									Translator.OnDragged.Add(new (position) => {
										var moby = Moby.allocated[ViewerSelection.currentObjIndex];
										moby.position = (.)position;
										Moby.GetAddress(ViewerSelection.currentObjIndex).Write(&moby);
									});
								} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
									Translator.OnDragBegin.Add(new () => grabbedTriangle = Terrain.collision.GetTriangle(ViewerSelection.currentTriangleIndex / 3));
									Translator.OnDragged.Add(new (position) => {
										// Use reference triangle to modify the packed collision triangle
										grabbedTriangle[ViewerSelection.currentTriangleIndex % 3] = (.)position;
										Terrain.collision.SetTriangle((.)ViewerSelection.currentTriangleIndex / 3, grabbedTriangle, true);
									});
									Translator.OnDragEnd.Add(new () => {
										// Get nearest vertex on newly arranged triangle
										let triangleIndex = ViewerSelection.currentTriangleIndex / 3;
										let vertexIndex = ViewerSelection.currentTriangleIndex % 3;
										let oldVertex = grabbedTriangle[vertexIndex];
										Vector3Int[3] newTriangle = Terrain.collision.GetTriangle(ViewerSelection.currentTriangleIndex / 3);
										
										int newVertexIndex = ?;
										var closestDistance = int.MaxValue;
										for (let i < 3) {
											let vertex = newTriangle[i];
											let distance = (vertex - oldVertex).LengthSq();
											if (distance < closestDistance) {
												closestDistance = distance;
												newVertexIndex = i;
											}
										}

										ViewerSelection.currentTriangleIndex = triangleIndex * 3 + newVertexIndex;
									});
								} else {
									Translator.OnDragBegin.Add(new => Emulator.active.KillSpyroUpdate);
									Translator.OnDragged.Add(new (position) => {
										Emulator.active.SpyroPosition = (.)position;
									});
									Translator.OnDragEnd.Add(new => Emulator.active.RestoreSpyroUpdate);
								}
							}
						}

						if (!(viewerMenu.manipulatorToggle.value && Translator.hovered)) {
							Selection.Select();
						}
					}
				}
				case .MouseMotion : {
					if (cameraHijacked) {
						switch (viewMode) {
							case .Free, .Lock: {
								viewEulerRotation.z -= (.)event.motion.xrel * 0.001f;
								viewEulerRotation.x += (.)event.motion.yrel * 0.001f;
								viewEulerRotation.x = Math.Clamp(viewEulerRotation.x, -0.5f, 0.5f);
							}
							case .Game: {
								int16[3] cameraEulerRotation = ?;	
								Emulator.cameraEulerRotationAddress[(int)Emulator.active.rom].Read(&cameraEulerRotation);
		
								cameraEulerRotation[2] -= (.)event.motion.xrel * 2;
								cameraEulerRotation[1] += (.)event.motion.yrel * 2;
								cameraEulerRotation[1] = Math.Clamp(cameraEulerRotation[1], -0x400, 0x400);
		
								// Force camera view basis in game
								Emulator.active.cameraBasisInv = MatrixInt.Euler(0, (float)cameraEulerRotation[1] / 0x800 * Math.PI_f, (float)cameraEulerRotation[2] / 0x800 * Math.PI_f);
		
								Emulator.cameraMatrixAddress[(int)Emulator.active.rom].Write(&Emulator.active.cameraBasisInv);
								Emulator.cameraEulerRotationAddress[(int)Emulator.active.rom].Write(&cameraEulerRotation);
							}
							case .Map: {
								var translationX = -Camera.size * event.motion.xrel / WindowApp.height;
								var translationY = Camera.size * event.motion.yrel / WindowApp.height;

								Camera.position.x += translationX;
								Camera.position.y += translationY;
							}
						}
					} else {
						if (inspector != null && Emulator.active.loadingStatus == .Idle || Emulator.active.loadingStatus == .CutsceneIdle) {
							sideInspectorVisible =
								GUIElement.selectedElement is GUIInteractable && sideInspector.IsParentOf(GUIElement.selectedElement) ||
								!Translator.dragged && inspector.[Friend]dataReference != null && (
									pinInspectorButton.value ||
									(sideInspectorVisible && WindowApp.mousePosition.x > WindowApp.width - 300 || WindowApp.mousePosition.x > WindowApp.width - 10)
								);
						} else {
							cornerMenuVisible = sideInspectorVisible = false;
						}

						if (viewerMenu.manipulatorToggle.value && Translator.MouseMove(WindowApp.mousePosition)) {
							Selection.Clear();
						} else if (Emulator.active.loadingStatus == .Idle && Emulator.active.gameState <= 1 || Emulator.active.loadingStatus == .CutsceneIdle) {
							Selection.Test();
						}
					}
				}
				case .MouseButtonUp : {
					if (event.button.button == 3) {	
						SDL.SetRelativeMouseMode(false);
						cameraHijacked = false;
					}

					Translator.MouseRelease();
				}
				case .MouseWheel : {
					if (viewMode == .Map) {
						Camera.size -= Camera.size / 8 * (.)event.wheel.y;

						WindowApp.viewerProjection = Camera.projection;
					} else {
						var newSpeed = cameraSpeed + event.wheel.y * 16;
						if (newSpeed < 8) {
							newSpeed = 8;
						}

						if (newSpeed != cameraSpeed) {
							messageFeed.PushMessage(new String() .. AppendF("Camera Speed ({}/f)", newSpeed));
						}

						cameraSpeed = newSpeed;
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
							}
							case .K : {
								uint32 health = 0;
								Emulator.healthAddresses[(int)Emulator.active.rom].Write(&health);
							}
							case .T : {
								if (viewerMenu.teleportButton.Enabled) {
									Teleport();
								}
							}
							case .C : {
								viewerMenu.freecamToggle.Toggle();
							}
							case .I : {
								/*// Does not currently work as intended
								if (Emulator.InputMode) {
									Emulator.RestoreInputRelay();
									messageFeed.PushMessage("Emulator Input");
								} else {
									Emulator.KillInputRelay();
									messageFeed.PushMessage("Manual Input");
								}*/
							}
							case .V : {
								windowApp.GoToState<VRAMViewerState>();
							}
							case .R : {
								RecordReplay();
							}
							case .F : {
								if (Recording.Playing) {
									Recording.StopReplay();
								} else {
									Recording.Replay();
								}
							}
							case .Key9: {
								ExportTerrain();
							}
							case .F1: {
								Selection.Clear();
								Terrain.collision.Clear();

								let position = Emulator.active.SpyroPosition + .(0,0,-500);
								Vector3Int[3] triangle;
								triangle[0] = position + .(-500,-500,0);
								triangle[1] = position + .(-500,500,0);
								triangle[2] = position + .(500,-500,0);

								Terrain.collision.AddTriangle(triangle);
								
								triangle[0] = position + .(-500,500,0);
								triangle[1] = position + .(500,500,0);
								triangle[2] = position + .(500,-500,0);

								Terrain.collision.AddTriangle(triangle);
							}
							case .F12 : {
								Reload();
							}
							default : {}
						}
					}
				}
				case .KeyUp : {
					if (event.key.keysym.scancode == .LCtrl) {
						cameraSpeed /= 8;
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
			if (Emulator.active.installment == .SpyroTheDragon) {
				return; // Ignore drawing models for Spyro 1 for now
			}

			if (object.HasModel) {
				if (modelSets.ContainsKey(object.objectTypeID)) {
					if (!drawObjectExperimentalModels) {
						Emulator.Address modelSetAddress = ?;
						Emulator.modelPointers[(int)Emulator.active.rom].GetAtIndex(&modelSetAddress, object.objectTypeID);
						if ((uint32)modelSetAddress & 0x80000000 > 0) {
							return;
						}
					}

					let basis = Matrix3.Euler(
						-(float)object.eulerRotation.x / 0x80 * Math.PI_f,
						(float)object.eulerRotation.y / 0x80 * Math.PI_f,
						-(float)object.eulerRotation.z / 0x80 * Math.PI_f
					);

					Renderer.SetModel(object.position, basis);
					Renderer.SetTint(object.IsActive ? .(255,255,255) : .(32,32,32));
					modelSets[object.objectTypeID].QueueInstance(object.modelID, Emulator.active.shinyColors[object.color.r % 10][1]);
				} else {
					Emulator.Address modelSetAddress = ?;
					Emulator.modelPointers[(int)Emulator.active.rom].GetAtIndex(&modelSetAddress, object.objectTypeID);

					if (!modelSetAddress.IsNull) {
						modelSets.Add(object.objectTypeID, new .(modelSetAddress));
					}
				}
			}
		}

		void DrawMobyIcon(Moby object, Vector3 screenPosition, float scale) {
			switch (object.objectTypeID) {
				case 0xca:
				case 0xcb:
				default:
					Texture containerIcon = null;
					Renderer.Color iconTint = .(128,128,128);

					if (Emulator.active.installment == .SpyroTheDragon) {
						if (object.[Friend]o == 0xff && (object.objectTypeID < 0x53 || object.objectTypeID > 0x57) || object.[Friend]o != 0xff && (object.[Friend]o < 0x53 || object.[Friend]o > 0x57)) {
							return;
						}
					} else {
						switch (object.heldGemValue) {
							case 1: case 2: case 5: case 10: case 25: // Allow any of these values to pass
							default: return; // If the data does not contain a valid gem value, skip drawing an icon
						}
					}

					if (Emulator.active.installment == .SpyroTheDragon) {
						if ((object.objectTypeID < 0x53 || object.objectTypeID > 0x57) && object.[Friend]o != 0xff) {
							containerIcon = gemHolderIconTexture;
						}
					} else {
						if (object.objectTypeID != 1) {
							containerIcon = gemHolderIconTexture;
						}

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
				
					if (Emulator.active.installment == .SpyroTheDragon) {
						var id = 0;
						if (object.objectTypeID >= 0x53 && object.objectTypeID <= 0x57) {
							id = object.objectTypeID;
						} else {
							id = object.[Friend]o;
						}

						switch (id) {
							case 0x53: color = .(255,0,0);
							case 0x54: color = .(0,255,0);
							case 0x55: color = .(0,0,255);
							case 0x56: color = .(255,180,0);
							case 0x57: color = .(255,90,255);
						}
					} else {
						switch (object.heldGemValue) {
							case 1: color = .(255,0,0);
							case 2: color = .(0,255,0);
							case 5: color = .(90,64,255);
							case 10: color = .(255,180,0);
							case 25: color = .(255,90,255);
						}
					}
		
					DrawUtilities.Rect(screenPosition.y - halfHeight, screenPosition.y + halfHeight, screenPosition.x - halfWidth, screenPosition.x + halfWidth, 0,1,0,1, gemIconTexture, color);
			}
		}

		void UpdateCameraMotion() {
			cameraMotionDirection = .Zero;

			bool* keystates = SDL.GetKeyboardState(null);
			if (keystates[(int)SDL.Scancode.W]) {
				cameraMotionDirection.z -= 1;
			}
			if (keystates[(int)SDL.Scancode.S]) {
				cameraMotionDirection.z += 1;
			}
			if (keystates[(int)SDL.Scancode.A]) {
				cameraMotionDirection.x -= 1;
			}
			if (keystates[(int)SDL.Scancode.D]) {
				cameraMotionDirection.x += 1;
			}
			if (keystates[(int)SDL.Scancode.Space]) {
				cameraMotionDirection.y += 1;
			}
			if (keystates[(int)SDL.Scancode.LShift]) {
				cameraMotionDirection.y -= 1;
			}
		}

		void UpdateView() {
			if (viewMode == .Game) {
				Camera.position = Emulator.active.CameraPosition;
				int16[3] cameraEulerRotation = Emulator.active.cameraEulerRotation;
				viewEulerRotation.x = (float)cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)cameraEulerRotation[2] / 0x800;
			}

			viewEulerRotation.z = Math.Repeat(viewEulerRotation.z + 1, 2) - 1;

			// Corrected view matrix for the scope
			Camera.basis = Matrix3.Euler(
				(viewEulerRotation.x - 0.5f) * Math.PI_f,
				viewEulerRotation.y  * Math.PI_f,
				(0.5f - viewEulerRotation.z) * Math.PI_f
			);

			// Move camera
			if (viewMode == .Map) {
				Camera.position.x += Camera.size / 100 * cameraMotionDirection.x;
				Camera.position.y -= Camera.size / 100 * cameraMotionDirection.z;
			} else {
				if (cameraHijacked) {
					let cameraMotion = Camera.basis * cameraMotionDirection * cameraSpeed;
				 
					if (viewMode == .Lock) {
						lockOffset += cameraMotion;
					} else {
						Camera.position += cameraMotion;
						if (viewMode != .Free) {
							Emulator.active.CameraPosition = (.)(Camera.position + cameraMotion);
						}
					}
				}

				if (viewMode == .Lock) {
					Camera.position = Emulator.active.SpyroPosition + lockOffset;
				}
			}
		}

		void UpdateManipulator() {
			Vector3 position = .Zero;
			Matrix3 basis = .Identity;

			if (ViewerSelection.currentObjIndex > -1) {
				let moby = Moby.allocated[ViewerSelection.currentObjIndex];

				position = moby.position;
				if (viewerMenu.objectSpaceToggle.value) {
					basis = moby.basis;
				}
			} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
				position = Terrain.collision.mesh.vertices[ViewerSelection.currentTriangleIndex];
			} else {
				position = Emulator.active.SpyroPosition;
				if (viewerMenu.objectSpaceToggle.value) {
					basis = Emulator.active.spyroBasis.ToMatrixCorrected();
				}
			}

			Translator.Update(position, basis);
		}
		
		void OnSceneChanging() {
			Selection.Reset();

			// Clear model data since the texture locations change in VRAM for every level
			// Also since the object models have stopped drawing beyond this point
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			modelSets.Clear();

			lastUpdatedSceneChanging = .Now;

			sideInspectorVisible = false;
		}

		void OnSceneChanged() {
			Terrain.Dispose();
			Terrain.Load();

			lastUpdatedSceneChange = .Now;
		}

		void OnSelect() {
			Emulator.Address address = .Null;
			void* reference = null;

			if (ViewerSelection.currentObjIndex > -1) {
				if (!(inspector is MobyInspector)) {
					if (inspector != null) {
						GUIElement.Remove(inspector);
					}
					inspector = new MobyInspector();
					inspector.Parent(sideInspector);
				}

				address = Moby.GetAddress(ViewerSelection.currentObjIndex);
				reference = &Moby.allocated[ViewerSelection.currentObjIndex];
			} else if (ViewerSelection.currentRegionIndex > -1) {
				if (!(inspector is NearFaceInspector)) {
					if (inspector != null) {
						GUIElement.Remove(inspector);
					}
					inspector = new NearFaceInspector();
					inspector.Parent(sideInspector);
				}
				
				let regionIndex = ViewerSelection.currentRegionIndex;
				if (regionIndex > -1) {
					let region = Terrain.regions[regionIndex];
					let currentTriangleIndex = ViewerSelection.currentTriangleIndex;

					int faceIndex = ?;

					if (ViewerSelection.currentRegionTransparent) {
					    faceIndex = region.nearFaceTransparentIndices[currentTriangleIndex];
					} else {
					    faceIndex = region.nearFaceIndices[currentTriangleIndex];
					}

					let nearLOD = region.NearLOD;

					address = (.)region.[Friend]address + 0x1c + ((int)nearLOD.start + (int)nearLOD.vertexCount + (int)nearLOD.colorCount * 2 + // Pass over previous near data
						faceIndex * 4) * 4; // Index the face
					reference = region.GetNearFace(faceIndex);
				}
			}

			inspector?.SetData(address, reference);
		}

		void DrawGameCameraFrustrum() {
			let cameraBasis = Emulator.active.cameraBasisInv.ToMatrixCorrected().Transpose();
			let cameraBasisCorrected = Matrix3(cameraBasis.y, cameraBasis.z, -cameraBasis.x);

			let cameraPosition = Emulator.active.CameraPosition;
			Renderer.DrawLine(cameraPosition, cameraPosition + cameraBasis * Vector3(500,0,0), .(255,0,0), .(255,0,0));
			Renderer.DrawLine(cameraPosition, cameraPosition + cameraBasis * Vector3(0,500,0), .(0,255,0), .(0,255,0));
			Renderer.DrawLine(cameraPosition, cameraPosition + cameraBasis * Vector3(0,0,500), .(0,0,255), .(0,0,255));

			let projectionMatrixInv = WindowApp.gameProjection.Inverse();
			let viewProjectionMatrixInv = cameraBasisCorrected * projectionMatrixInv;

			let farTopLeft = (Vector3)(viewProjectionMatrixInv * Vector4(-1,1,1,1)) + (Vector3)cameraPosition;
			let farTopRight = (Vector3)(viewProjectionMatrixInv * Vector4(1,1,1,1)) + cameraPosition;
			let farBottomLeft = (Vector3)(viewProjectionMatrixInv * Vector4(-1,-1,1,1)) + cameraPosition;
			let farBottomRight = (Vector3)(viewProjectionMatrixInv * Vector4(1,-1,1,1)) + cameraPosition;

			let nearTopLeft = (Vector3)(viewProjectionMatrixInv * Vector4(-1,1,-1,1)) + cameraPosition;
			let nearTopRight = (Vector3)(viewProjectionMatrixInv * Vector4(1,1,-1,1)) + cameraPosition;
			let nearBottomLeft = (Vector3)(viewProjectionMatrixInv * Vector4(-1,-1,-1,1)) + cameraPosition;
			let nearBottomRight = (Vector3)(viewProjectionMatrixInv * Vector4(1,-1,-1,1)) + cameraPosition;

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

		void DrawObjects() {
			for (let object in Moby.allocated) {
				if (object.IsTerminator) {
					break;
				}

				if (object.IsActive || showInactive) {
					if ((!viewerMenu.manipulatorToggle.value || ViewerSelection.currentObjIndex != Moby.allocated.Count) && drawObjectOrigins) {
						object.DrawOriginAxis();
					}

					if (drawObjectModels) {
						DrawMoby(object);
					}
				}
			}

			if (displayAllData) {
				for (let object in Moby.allocated) {
					if (object.IsTerminator) {
						break;
					}

					object.DrawData();
				}
			} else {
				if (ViewerSelection.currentObjIndex != -1) {
					if (ViewerSelection.currentObjIndex < Moby.allocated.Count) {
						let object = Moby.allocated[ViewerSelection.currentObjIndex];
						object.DrawData();
					} else {
						ViewerSelection.currentObjIndex = -1;
					}
				}
			}
		}

		void DrawSpyroInformation() {
			let position = (Vector3)Emulator.active.SpyroPosition;

			DrawUtilities.Arrow(position, (Vector3)Emulator.active.SpyroIntendedVelocity / 10, 25, .(255,255,0));
			DrawUtilities.Arrow(position, (Vector3)Emulator.active.SpyroPhysicsVelocity / 10, 50, .(255,128,0));

			let viewerSpyroBasis = Emulator.active.spyroBasis.ToMatrixCorrected();
			Renderer.DrawLine(position, position + viewerSpyroBasis * Vector3(500,0,0), .(255,0,0), .(255,0,0));
			Renderer.DrawLine(position, position + viewerSpyroBasis * Vector3(0,500,0), .(0,255,0), .(0,255,0));
			Renderer.DrawLine(position, position + viewerSpyroBasis * Vector3(0,0,500), .(0,0,255), .(0,0,255));

			uint32 radius = ?;
			if (Emulator.active.installment == .YearOfTheDragon) {
			    Emulator.collisionRadius[(int)Emulator.active.rom - 7].Read(&radius);
			} else {
			    radius = 0x164;
			}

			DrawUtilities.WireframeSphere(position, viewerSpyroBasis, radius, .(32,32,32));
		}

		void DrawFlagsOverlay() {
			if (ViewerSelection.currentTriangleIndex > -1 && ViewerSelection.currentTriangleIndex < Terrain.collision.SpecialTriangleCount) {
				let flagInfo = Terrain.collision.flagIndices[ViewerSelection.currentTriangleIndex];
				let flagIndex = flagInfo & 0x3f;
				let flagData = Terrain.collision.GetCollisionFlagData(flagIndex);
	
				if (flagData.type == 0 || flagData.type == 3 || flagData.type == 6 || flagData.type == 7) {
					var screenPosition = (Vector2)Camera.SceneToScreen(cursor3DPosition);
					screenPosition.x = Math.Floor(screenPosition.x);
					screenPosition.y = Math.Floor(screenPosition.y);
					DrawUtilities.Rect(screenPosition.y, screenPosition.y + WindowApp.bitmapFont.height, screenPosition.x, screenPosition.x + WindowApp.bitmapFont.characterWidth * 10,
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
			let backgroundHeight = 18 * Terrain.collision.collisionTypes.Count + 2;
			DrawUtilities.Rect(WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 8 + 36,
				.(0,0,0,192));

			// Content
			for (let i < Terrain.collision.collisionTypes.Count) {
				let flag = Terrain.collision.collisionTypes[i];
				String label = scope String() .. AppendF("Unknown {}", flag);
				Renderer.Color color = .(255, 0, 255);
				if (flag < 11 /*Emulator.collisionTypes.Count*/) {
					(label, color) = Emulator.collisionTypes[flag];
				}

				let leftPadding = 8;
				let bottomPadding = 8 + 18 * i;
				DrawUtilities.Rect(WindowApp.height - (bottomPadding + 16), WindowApp.height - bottomPadding, leftPadding, leftPadding + 16, color);

				WindowApp.bitmapFont.Print(label, .(leftPadding + 24, WindowApp.height - (bottomPadding + 15)), .(255,255,255));
			}
		}

		void DrawLimits() {
			uint32 currentWorldId = ?;
			Emulator.currentWorldIdAddress[(int)Emulator.active.rom].Read(&currentWorldId);

			uint32 deathHeight;
			if (Emulator.active.installment == .YearOfTheDragon) {
				uint32 currentSubWorldId = ?;
				Emulator.currentSubWorldIdAddress[(int)Emulator.active.rom - 7].Read(&currentSubWorldId);

				deathHeight = Emulator.active.deathPlaneHeights[currentWorldId * 4 + currentSubWorldId];
			} else {
				deathHeight = Emulator.active.deathPlaneHeights[currentWorldId];
			}

			if (Camera.position.z > deathHeight) {
				DrawUtilities.Grid(.(0,0,deathHeight), .Identity, .(255,64,32));
			}

			let flightHeight = Emulator.active.maxFreeflightHeights[currentWorldId];
			if (Camera.position.z < flightHeight) {
				DrawUtilities.Grid(.(0,0,flightHeight), .Identity, .(32,64,255));
			}
		}

		void DrawRecording() {
			// Draw recording path
			for	(let i < Recording.FrameCount - 1) {
				let frame = Recording.GetFrame(i);
				let nextFrame = Recording.GetFrame(i + 1);

				Renderer.DrawLine(frame.position, nextFrame.position, .(255,0,0), .(255,255,0));

				// Every second
				if (i % 30 == 0) {
					let direction = ((Vector3)nextFrame.position - frame.position).Normalized();
					let pdir = Vector3.Cross(direction, Camera.basis.z).Normalized();

					let size = Vector3.Dot(Camera.position - frame.position, Camera.basis.z) / 50;
					Renderer.DrawLine(frame.position, frame.position + (pdir - direction) * size, .(255,255,255), .(255,255,255));
					Renderer.DrawLine(frame.position, frame.position - (pdir + direction) * size, .(255,255,255), .(255,255,255));
				}

				// Every state change
				if (frame.state != nextFrame.state) {
					let direction = ((Vector3)nextFrame.position - frame.position).Normalized();
					let pdir = Vector3.Cross(direction, Camera.basis.z).Normalized();

					let size = Vector3.Dot(Camera.position - frame.position, Camera.basis.z) / 100;
					Renderer.DrawLine(nextFrame.position, nextFrame.position + pdir * size, .(255,255,255), .(255,255,255));
					Renderer.DrawLine(nextFrame.position, nextFrame.position - pdir * size, .(255,255,255), .(255,255,255));
				}
			}
		}

		void DrawLoadingOverlay() {
			// Darken everything
			DrawUtilities.Rect(0,WindowApp.height,0,WindowApp.width, .(0,0,0,192));

			let loadingMessage = "Loading...";
			var halfWidth = Math.Round(WindowApp.font.CalculateWidth(loadingMessage) / 2);
			var baseline = WindowApp.height / 2 - WindowApp.font.height;
			let middleWindow = WindowApp.width / 2;
			WindowApp.font.Print(loadingMessage, .(middleWindow - halfWidth, baseline), .(255,255,255));

			var line = 0;
			for (let i < 8) {
				if (!Emulator.active.changedPointers[i]) {
					halfWidth = WindowApp.fontSmall.CalculateWidth(Emulator.pointerLabels[i]) / 2;
					baseline = WindowApp.height / 2 + WindowApp.fontSmall.height * line;
					WindowApp.fontSmall.Print(Emulator.pointerLabels[i], .(Math.Round(middleWindow - halfWidth), baseline), .(255,255,255));
					line++;
				}
			}
		}

		void TogglePause() {
			Emulator.active.Paused = !Emulator.active.Paused;

			if (Emulator.active.Paused) {
				messageFeed.PushMessage("Paused Game Update");
				togglePauseButton.iconTexture = playTexture;
				stepButton.Enabled = true;
			} else {
				messageFeed.PushMessage("Resumed Game Update");
				togglePauseButton.iconTexture = pauseTexture;
				stepButton.Enabled = false;
			}
		}

		void Step() {
			togglePauseButton.iconTexture = playTexture;
			Emulator.active.Step();
		}

		public void ToggleWireframe(bool toggle) {
			Terrain.wireframe = toggle;
			messageFeed.PushMessage("Toggled Render Wireframe");
		}

		public void ToggleSolid(bool toggle) {
			Terrain.solid = toggle;
			messageFeed.PushMessage("Toggled Render Solid");
		}

		public void ToggleTextures(bool toggle) {
			Terrain.textured = toggle;
			messageFeed.PushMessage("Toggled Terrain Textures");
		}

		public void ToggleColors(bool toggle) {
			Terrain.Colored = toggle;
			messageFeed.PushMessage("Toggled Terrain Vertex Colors");
		}

		public void ToggleFadeColors(bool toggle) {
			Terrain.UsingFade = toggle;
			messageFeed.PushMessage("Toggled Terrain Fade Colors");
		}

		public void ToggleOrigins(bool toggle) {
			drawObjectOrigins = toggle;
			messageFeed.PushMessage("Toggled Object Origins");
		}

		public void ToggleModels(bool toggle) {
			drawObjectModels = toggle;
			messageFeed.PushMessage("Toggled Object Models");
		}

		public void ToggleModelsExperimental(bool toggle) {
			drawObjectExperimentalModels = toggle;
			messageFeed.PushMessage("Toggled Object Models Experimental");
		}

		public void ToggleInactive(bool toggle) {
			showInactive = toggle;
			messageFeed.PushMessage("Toggled Inactive Visibility");
		}
		
		public void ToggleIcons(bool toggle) {
			displayIcons = toggle;
			messageFeed.PushMessage("Toggled Object Icons");
		}
		
		public void ToggleMobyData(bool toggle) {
			displayAllData = toggle;
			messageFeed.PushMessage("Toggled Moby Data");
		}

		public void ChangeView(ViewMode mode) {
			if (viewMode == .Map && mode != .Map) {
				Camera.orthographic = false;
				Camera.near = 100;
				Camera.far = 500000;

				Camera.position = Emulator.active.CameraPosition;
				int16[3] cameraEulerRotation = Emulator.active.cameraEulerRotation;
				viewEulerRotation.x = (float)cameraEulerRotation[1] / 0x800;
				viewEulerRotation.y = (float)cameraEulerRotation[0] / 0x800;
				viewEulerRotation.z = (float)cameraEulerRotation[2] / 0x800;

				WindowApp.viewerProjection = Camera.projection;
			} else if (viewMode != .Map && mode == .Map)  {
				if (Terrain.collision != null) {
					let upperBound = Terrain.collision.upperBound;
					let lowerBound = Terrain.collision.lowerBound;
					
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
				}
				
				Camera.orthographic = true;
				Camera.near = 0;

				viewEulerRotation = .(0.5f,0,0.5f);
				WindowApp.viewerProjection = Camera.projection;
			}

			if (mode == .Lock) {
				lockOffset = Camera.position - Emulator.active.SpyroPosition;
			}

			viewerMenu.teleportButton.Enabled = mode == .Free || mode == .Game && Emulator.active.CameraMode;

			viewMode = mode;
		}

		public void ChangeRender(Terrain.RenderMode renderMode) {
			switch (renderMode) {
				case .Collision, .Far: Selection.Clear();
				default: switch (Terrain.renderMode) {
					case .Collision, .Far: Selection.Clear();
					default:
				}
			}
			
			Terrain.renderMode = renderMode;
		}

		public void ToggleFreeCamera(bool toggle) {
			if (toggle) {
				Emulator.active.KillCameraUpdate();
				messageFeed.PushMessage("Free Camera");
				viewerMenu.teleportButton.Enabled = true;
			} else {
				Emulator.active.RestoreCameraUpdate();
				messageFeed.PushMessage("Game Camera");
				viewerMenu.teleportButton.Enabled = viewMode != .Game;
			}
		}

		public void ToggleLimits(bool toggle) {
			drawLimits = toggle;
			messageFeed.PushMessage("Toggled Height Limits");
		}

		public void RecordReplay() {
			if (!Recording.Active) {
				Recording.Record();
				timeline.visible = true;
				viewerMenu.recordButton.text = "Stop Record";
				messageFeed.PushMessage("Begin Recording");
			} else {
				Recording.StopRecord();
				viewerMenu.recordButton.text = "Record";
				messageFeed.PushMessage("Stopped Recording");
			}
		}

		public void Teleport() {
			Emulator.active.SpyroPosition = (.)Camera.position;
			messageFeed.PushMessage("Teleported Spyro to Game Camera");
		}

		void Reload() {
			Terrain.Reload();
			Terrain.ReloadAnimations();
		}

		void ExportTerrain() {
			let dialog = new SaveFileDialog();
			dialog.FileName = "terrain";
			dialog.SetFilter(scope String() .. AppendF("Spyro Terrain (*.{0})|*.{0}|All files (*.*)|*.*", Emulator.active.installment == .SpyroTheDragon ? "s1terrain" : "sterrain"));
			dialog.OverwritePrompt = true;
			dialog.CheckFileExists = true;
			dialog.AddExtension = true;
			dialog.DefaultExt = Emulator.active.installment == .SpyroTheDragon ? "s1terrain" : "sterrain";

			switch (dialog.ShowDialog()) {
				case .Ok(let val):
					if (val == .OK) {
						Terrain.Export(dialog.FileNames[0]);
					}
				case .Err:
			}

			delete dialog;
		}
	}
}
