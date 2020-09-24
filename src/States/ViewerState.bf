using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class ViewerState : WindowState {
		bool dislodgeCamera;
		bool cameraHijacked;
		float cameraSpeed = 64;
		Vector cameraMotion;
		Vector viewEulerRotation;

		bool drawObjectOrigins = true;
		bool hideInactive = false;

		int currentObjIndex = -1;
		int hoveredObjIndex = -1;
		int currentAnimGroupIndex = -1;
		int hoveredAnimGroupIndex = -1;
		List<(Emulator.Address<Moby>, Moby)> objectList = new .(128) ~ delete _;
		List<int> hoveredObjects = new .() ~ delete _;

		Terrain collisionTerrain = new .() ~ delete _;
		bool drawLimits;

		Dictionary<uint16, MobyModelSet> modelSets = new .();

		Vector mousePosition;

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

		(Toggle button, String label)[6] toggleList = .(
			(null, "Collision Wirefra(m)e"),
			(null, "Object (O)rigin Axis"),
			(null, "Hide (I)nactive Objects"),
			(null, "(H)eight Limits"),
			(null, "Game/Free (V)iew"),
			(null, "Free (C)amera")
		);

		public this() {
			togglePauseButton = new .();
			guiElements.Add(togglePauseButton);

			togglePauseButton.anchor = .(0.5f, 0.5f, 0, 0);
			togglePauseButton.offset = .(-16, 16, -16, 16);
			togglePauseButton.offset.Shift(-16, 32);
			togglePauseButton.normalTexture = normalButtonTexture;
			togglePauseButton.pressedTexture = pressedButtonTexture;
			togglePauseButton.OnPressed.Add(new => TogglePause);

			stepButton = new .();
			guiElements.Add(stepButton);

			stepButton.anchor = .(0.5f, 0.5f, 0, 0);
			stepButton.offset = .(-16, 16, -16, 16);
			stepButton.offset.Shift(16, 32);
			stepButton.normalTexture = normalButtonTexture;
			stepButton.pressedTexture = pressedButtonTexture;
			stepButton.iconTexture = stepTexture;
			stepButton.OnPressed.Add(new => Step);

			Toggle button;
			for (let i < toggleList.Count) {
				button = new .();
				guiElements.Add(button);
				
				button.offset = .(16, 32, 16 + i * WindowApp.font.height, 32 + i * WindowApp.font.height);
				button.normalTexture = normalButtonTexture;
				button.pressedTexture = pressedButtonTexture;
				button.toggleTexture = toggledTexture;

				toggleList[i].button = button;
			}

			toggleList[1].button.Pressed();

			toggleList[0].button.OnPressed.Add(new () => {ToggleWireframe(toggleList[0].button.toggled);});
			toggleList[1].button.OnPressed.Add(new () => {ToggleOrigins(toggleList[1].button.toggled);});
			toggleList[2].button.OnPressed.Add(new () => {ToggleInactive(toggleList[2].button.toggled);});
			toggleList[3].button.OnPressed.Add(new () => {ToggleLimits(toggleList[3].button.toggled);});
			toggleList[4].button.OnPressed.Add(new () => {ToggleView(toggleList[4].button.toggled);});
			toggleList[5].button.OnPressed.Add(new () => {ToggleFreeCamera(toggleList[5].button.toggled);});

			cycleTerrainOverlayButton = new .();
			guiElements.Add(cycleTerrainOverlayButton);

			cycleTerrainOverlayButton.offset = .(16, 180, 16 + toggleList.Count * WindowApp.font.height, 32 + toggleList.Count * WindowApp.font.height);
			cycleTerrainOverlayButton.normalTexture = normalButtonTexture;
			cycleTerrainOverlayButton.pressedTexture = pressedButtonTexture;
			cycleTerrainOverlayButton.text = "Terrain Over(l)ay";
			cycleTerrainOverlayButton.OnPressed.Add(new => CycleTerrainOverlay);

			teleportButton = new .();
			guiElements.Add(teleportButton);

			teleportButton.offset = .(16, 180, 16 + (toggleList.Count + 1) * WindowApp.font.height, 32 + (toggleList.Count + 1) * WindowApp.font.height);
			teleportButton.normalTexture = normalButtonTexture;
			teleportButton.pressedTexture = pressedButtonTexture;
			teleportButton.text = "(T)eleport";
			teleportButton.OnPressed.Add(new => Teleport);
			teleportButton.enabled = false;
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
			
			togglePauseButton.iconTexture = Emulator.PausedMode ? playTexture : pauseTexture;
			toggleList[4].button.toggled = teleportButton.enabled = Emulator.CameraMode;
			if (Emulator.CameraMode) {
				toggleList[4].button.iconTexture = toggleList[4].button.toggleTexture;
			}
		}

		public override void Exit() {
			delete Emulator.OnSceneChanged;
		}

		public override void Update() {
			Emulator.CheckEmulatorStatus();

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				windowApp.GoToState!<SetupState>();
			}

			Emulator.FetchRAMBaseAddress();
			Emulator.FetchImportantObjects();

			collisionTerrain.Update();

			UpdateView();

			for (let element in guiElements) {
				element.Update();
			}
		}

		public override void DrawView(Renderer renderer) {
			collisionTerrain.Draw(renderer);
			if (dislodgeCamera) {
				DrawGameCameraFrustrum();
			}

			Emulator.Address<Moby> objPointer = ?;
			Emulator.objectArrayPointers[(int)Emulator.rom].Read(&objPointer);
			
			objectList.Clear();
			while (true) {
				Moby object = ?;
				objPointer.Read(&object);

				if (object.dataPointer.IsNull) {
					break;
				}
				
				objPointer += sizeof(Moby);

				if (hideInactive && !object.IsActive) {
					continue;
				}

				objectList.Add((objPointer, object));

				DrawMoby(object, renderer);

				if (drawObjectOrigins) {
					object.DrawOriginAxis(renderer);
				}
			}

			if (currentObjIndex != -1) {
				let (address, object) = objectList[currentObjIndex];
				object.DrawData(renderer);
			}

			DrawSpyroInformation();

			// Draw all queued instances
			PrimitiveShape.DrawInstances();

			for (let modelSet in modelSets.Values) {
				for (let model in modelSet.models) {
					model.DrawInstances();
				}
			}

			if (drawLimits) {
				uint32 currentWorldId = ?;
				Emulator.currentWorldIdAddress[(int)Emulator.rom].Read(&currentWorldId);

				uint32 deathHeight;
				if (Emulator.rom == .YearOfTheDragon) {
					uint32 currentSubWorldId = ?;
					Emulator.currentSubWorldIdAddress.Read(&currentSubWorldId);

					deathHeight = Emulator.deathPlaneHeights[currentWorldId * 4 + currentSubWorldId];
				} else {
					deathHeight = Emulator.deathPlaneHeights[currentWorldId];
				}

				if (Camera.position.z > deathHeight) {
					DrawUtilities.Grid(.(0,0,deathHeight), .Identity, .(255,64,32), renderer);
				}
				
				let flightHeight = Emulator.maxFreeflightHeights[currentWorldId];
				if (Camera.position.z < flightHeight) {
					DrawUtilities.Grid(.(0,0,flightHeight), .Identity, .(32,64,255), renderer);
				}
			}

			renderer.SetModel(.Zero, .Identity);
			renderer.SetTint(.(255,255,255));
			renderer.Draw();
		}

		public override void DrawGUI(Renderer renderer) {
			for	(let (address, object) in objectList) {
				switch ((uint8)object.m) {
					case 1: case 2: case 5: case 10: case 25: // Allow any of these values to pass
					default: continue; // If the data does not contain a valid gem value, skip drawing an icon
				}

				var offsettedPosition = object.position;
				if (object.objectTypeID != 1) {
					offsettedPosition.z += 0x100;
				}

				var screenPosition = Camera.SceneToScreen(offsettedPosition);
				if (screenPosition.z > 10000) { // Must be in front of view
					//let screenSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
					
					Texture containerIcon = object.objectTypeID == 1 ? null : gemHolderIconTexture;
					Renderer.Color iconTint = .(64,64,64);
					switch (object.objectTypeID) {
						case 0xc8:
							iconTint = .(192,64,32);
							containerIcon = basketIconTexture;
						case 0xc9:
							iconTint = .(32,64,192);
							containerIcon = vaseIconTexture;
						case 0xd1:
							iconTint = .(16,192,0);
							containerIcon = bottleIconTexture;
					}

					if (containerIcon != null) {
						let halfWidth = vaseIconTexture.width / 2;
						let halfHeight = vaseIconTexture.height / 2;
						DrawUtilities.Rect(screenPosition.y - halfHeight, screenPosition.y + halfHeight, screenPosition.x - halfWidth, screenPosition.x + halfWidth, 0,1,0,1, containerIcon, iconTint, renderer);
					}

					if (true) {
						
						//screenPosition.z = 0;
						var halfWidth = (float)gemIconTexture.width / 2;
						var halfHeight = (float)gemIconTexture.height / 2;

						if (containerIcon != null) {
							halfWidth *= 0.75f;
							halfHeight *= 0.75f;
						}
						
						Renderer.Color color = .(255,255,255);
						switch ((uint8)object.m) {
							case 1: color = .(255,0,0);
							case 2: color = .(0,255,0);
							case 5: color = .(32,16,255);
							case 10: color = .(255,128,0);
							case 25: color = .(255,32,255);
						}

						DrawUtilities.Rect(screenPosition.y - halfHeight, screenPosition.y + halfHeight, screenPosition.x - halfWidth, screenPosition.x + halfWidth, 0,1,0,1, gemIconTexture, color, renderer);
					}
				}
			}

			if (objectList.Count > 0) {
				if (currentObjIndex != -1) {
					let (address, currentObject) = objectList[currentObjIndex];
					// Begin overlays
					var screenPosition = Camera.SceneToScreen(currentObject.position);
					if (drawObjectOrigins && screenPosition.z > 0) { // Must be in front of view
						let screenSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
						DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(16,16,16), renderer);

						Emulator.Address objectArrayPointer = ?;
						Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);

						screenPosition.y += screenSize;
						screenPosition.x = Math.Floor(screenPosition.x);
						screenPosition.y = Math.Floor(screenPosition.y);
						DrawUtilities.Rect(screenPosition.y, screenPosition.y + WindowApp.bitmapFont.characterHeight * 2, screenPosition.x, screenPosition.x + WindowApp.bitmapFont.characterWidth * 10,
							.(0,0,0,192), renderer);

						screenPosition.y += 2;
						WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]", address),
							screenPosition, .(255,255,255), renderer);
						WindowApp.bitmapFont.Print(scope String() .. AppendF("TYPE: {:X4}", currentObject.objectTypeID),
							screenPosition + .(0,WindowApp.bitmapFont.characterHeight,0), .(255,255,255), renderer);
					}
				}

				if (hoveredObjIndex != -1) {
					let (address, hoveredObject) = objectList[hoveredObjIndex];
					// Begin overlays
					var screenPosition = Camera.SceneToScreen(hoveredObject.position);
					if (screenPosition.z > 0) { // Must be in front of view
						let screenSize = Camera.SceneSizeToScreenSize(150, screenPosition.z);
						screenPosition.z = 0;
						DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(128,64,16), renderer);
					}
				}

				if (collisionTerrain.overlay == .Deform && hoveredAnimGroupIndex != -1) {
					let hoveredAnimGroup = collisionTerrain.animationGroups[hoveredAnimGroupIndex];
					// Begin overlays
					var screenPosition = Camera.SceneToScreen(hoveredAnimGroup.center);
					if (screenPosition.z > 0) { // Must be in front of view
						let screenSize = Camera.SceneSizeToScreenSize(hoveredAnimGroup.radius - 50, screenPosition.z);
						screenPosition.z = 0;
						DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(128,64,16), renderer);
					}
				}
			}

			if (hoveredObjects.Count > 0) {
				DrawUtilities.Rect(mousePosition.y, mousePosition.y + WindowApp.bitmapFont.characterHeight * hoveredObjects.Count, mousePosition.x, mousePosition.x + WindowApp.bitmapFont.characterWidth * 16, .(0,0,0,16), renderer);
			}
			for	(let i < hoveredObjects.Count) {
				WindowApp.bitmapFont.Print(scope String() .. AppendF("[{}]: {:X4}", objectList[i].0, (objectList[i].1).objectTypeID), mousePosition + .(0,i * WindowApp.bitmapFont.characterHeight,0), .(255,255,255), renderer);
			}

			// Begin window relative position UI
			if (!toggleList[0].button.visible) {
				DrawMessageFeed();
			} else {
				DrawUtilities.Rect(0,200,0,200, .(0,0,0,192), renderer);
			}

			if (collisionTerrain.overlay == .Flags) {
				// Legend
				let leftPaddingBG = 4;
				let bottomPaddingBG = 4;

				// Background
				let backgroundHeight = 18 * collisionTerrain.collisionTypes.Count + 2;
				DrawUtilities.Rect((.)WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 8 + 36,
					.(0,0,0,192), renderer);

				// Content
				for (let i < collisionTerrain.collisionTypes.Count) {
					let flag = collisionTerrain.collisionTypes[i];
					String label = scope String() .. AppendF("Unknown {}", flag);
					Renderer.Color color = .(255, 0, 255);
					if (flag < 11 /*Emulator.collisionTypes.Count*/) {
						(label, color) = Emulator.collisionTypes[flag];
					}

					let leftPadding = 8;
					let bottomPadding = 8 + 18 * i;
					DrawUtilities.Rect((.)WindowApp.height - (bottomPadding + 16), (.)WindowApp.height - bottomPadding, leftPadding, leftPadding + 16, color, renderer);

					WindowApp.bitmapFont.Print(label, .(leftPadding + 24, (.)WindowApp.height - (bottomPadding + 15), 0), .(255,255,255), renderer);
				}
			} else if (collisionTerrain.overlay == .Deform) {
				if (currentAnimGroupIndex != -1) {
					let animationGroup = collisionTerrain.animationGroups[currentAnimGroupIndex];
					var screenPosition = Camera.SceneToScreen(animationGroup.center);
					if (screenPosition.z > 0) { // Must be in front of view
						let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
						screenPosition.z = 0;
						DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(16,16,0), renderer);
					}

					let leftPaddingBG = 4;
					let bottomPaddingBG = 4;
	
					// Background
					let backgroundHeight = 18 * 6;
					DrawUtilities.Rect((.)WindowApp.height - (bottomPaddingBG * 2 + backgroundHeight), WindowApp.height - bottomPaddingBG, leftPaddingBG, leftPaddingBG + 12 * 14 + 8,
						.(0,0,0,192), renderer);
	
					// Content
					let currentKeyframe = animationGroup.CurrentKeyframe;
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Group Index {}", currentAnimGroupIndex), .(8, (.)WindowApp.height - (18 * 5 + 8 + 15), 0), .(255,255,255), renderer);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Keyframe {}", (uint)currentKeyframe), .(8, (.)WindowApp.height - (18 * 4 + 8 + 15), 0), .(255,255,255), renderer);
					let keyframeData = animationGroup.GetKeyframeData(currentKeyframe);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Flag {}", (uint)keyframeData.flag), .(8, (.)WindowApp.height - (18 * 3 + 8 + 15), 0), .(255,255,255), renderer);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("Interp. {}", (uint)keyframeData.interpolation), .(8, (.)WindowApp.height - (18 * 2 + 8 + 15), 0), .(255,255,255), renderer);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("From State {}", (uint)keyframeData.fromState), .(8, (.)WindowApp.height - (18 * 1 + 8 + 15), 0), .(255,255,255), renderer);
					WindowApp.bitmapFont.Print(scope String() .. AppendF("To State {}", (uint)keyframeData.toState), .(8, (.)WindowApp.height - (18 * 0 + 8 + 15), 0), .(255,255,255), renderer);
				} else {
					for (let animationGroup in collisionTerrain.animationGroups) {
						var screenPosition = Camera.SceneToScreen(animationGroup.center);
						if (screenPosition.z > 0) { // Must be in front of view
							let screenSize = Camera.SceneSizeToScreenSize(animationGroup.radius, screenPosition.z);
							screenPosition.z = 0;
							DrawUtilities.Circle(screenPosition, Matrix.Scale(screenSize,screenSize,screenSize), Renderer.Color(16,16,0), renderer);
						}
					}
				}
			}

			for (let element in guiElements) {
				if (element.visible) {
					element.Draw(.(0, WindowApp.width, 0, WindowApp.height), renderer);
				}
			}

			for (let toggle in toggleList) {
				if (toggle.button.visible) {
					WindowApp.fontSmall.Print(toggle.label, .(toggle.button.drawn.right + 8, toggle.button.drawn.top + 1, 0), .(255,255,255), renderer);
				}
			}
		}

		public override bool OnEvent(SDL2.SDL.Event event) {
			switch (event.type) {
				case .MouseButtonDown : {
					if (GUIElement.hoveredElement != null) {
						GUIElement.preselectedElement = .hoveredElement;
					} else {
						if (event.button.button == 3) {
							SDL.SetRelativeMouseMode(true);
							cameraHijacked = true;
							if (!dislodgeCamera && !Emulator.CameraMode) {
								toggleList[4].button.Pressed();
							}
						}
						if (event.button.button == 1) {
							currentObjIndex = hoveredObjIndex;

							if (currentObjIndex != -1) {
								Emulator.Address objectArrayPointer = ?;
								Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);
			
								SDL.SetClipboardText(scope String() .. AppendF("{}", objectArrayPointer + currentObjIndex * sizeof(Moby)));
							}

							if (collisionTerrain.overlay == .Deform) {
								currentAnimGroupIndex = hoveredAnimGroupIndex;
								if (hoveredAnimGroupIndex != -1) {
									Emulator.Address objectArrayPointer = ?;
									Emulator.ReadFromRAM(Emulator.objectArrayPointers[(int)Emulator.rom], &objectArrayPointer, 4);
	
									SDL.SetClipboardText(scope String() .. AppendF("{}", objectArrayPointer + currentObjIndex * sizeof(Moby)));
								}
							}
						}
					}
				}
				case .MouseMotion : {
					if (cameraHijacked) {
						if (dislodgeCamera) {
							viewEulerRotation.z -= (.)event.motion.xrel * 0.001f;
							viewEulerRotation.x += (.)event.motion.yrel * 0.001f;
							viewEulerRotation.x = Math.Clamp(viewEulerRotation.x, -0.5f, 0.5f);
						} else {
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
					} else {
						mousePosition = .(event.motion.x, event.motion.y, 0);

						if (mousePosition.x < 200 && mousePosition.y < 200) {
							for (let toggle in toggleList) {
								toggle.button.visible = true;
							}
							cycleTerrainOverlayButton.visible = teleportButton.visible = true;
						} else {
							for (let toggle in toggleList) {
								toggle.button.visible = false;
							}
							cycleTerrainOverlayButton.visible = teleportButton.visible = false;
						}

						GUIElement.hoveredElement = null;
						for (let element in guiElements) {
							element.MouseUpdate(mousePosition);
						}
						var closestDistance = float.PositiveInfinity;
						hoveredObjIndex = GetObjectIndexUnderMouse(ref closestDistance);
						if (collisionTerrain.overlay == .Deform) {
							hoveredAnimGroupIndex = GetTerrainAnimationGroupIndexUnderMouse(ref closestDistance);
							if (hoveredAnimGroupIndex != -1) {
								hoveredObjIndex = -1;
							}
						}
					}
				}
				case .MouseButtonUp : {
					if (GUIElement.preselectedElement != null) { // Focus was on GUI
						if (GUIElement.preselectedElement == .hoveredElement) {
							GUIElement.preselectedElement.Pressed();
						}
					} else {
						if (event.button.button == 3) {	
							SDL.SetRelativeMouseMode(false);
							cameraHijacked = false;
							cameraMotion = .(0,0,0);
						}
					}
					GUIElement.preselectedElement = null;
				}
				case .MouseWheel : {
					cameraSpeed += (float)event.wheel.y;
					if (cameraSpeed < 8) {
						cameraSpeed = 8;
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
								toggleList[5].button.Pressed();
							}
							case .V : {
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
							default : {}
						}
	
						if (cameraHijacked) {
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
				}
				case .KeyUp : {
					if (event.key.keysym.scancode == .LCtrl) {
						cameraSpeed /= 8;
						cameraMotion /= 8;
					}
	
					if (cameraHijacked) {
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

		void DrawMoby(Moby object, Renderer renderer) {
			if (object.HasModel) {
				if (modelSets.ContainsKey(object.objectTypeID)) {
					let basis = Matrix.Euler(
						-(float)object.eulerRotation.x / 0x80 * Math.PI_f,
						(float)object.eulerRotation.y / 0x80 * Math.PI_f,
						-(float)object.eulerRotation.z / 0x80 * Math.PI_f
					);

					renderer.SetModel(object.position, basis * 2);
					renderer.SetTint(object.IsActive ? .(255,255,255) : .(32,32,32));
					modelSets[object.objectTypeID].models[object.modelID].QueueInstance(renderer);
				} else {
					Emulator.Address modelSetAddress = ?;
					Emulator.ReadFromRAM(Emulator.modelPointers[(int)Emulator.rom] + 4 * object.objectTypeID, &modelSetAddress, 4);

					if (modelSetAddress != 0 && (int32)modelSetAddress > 0) {
						modelSets.Add(object.objectTypeID, new .(modelSetAddress));
					}
				}
			}
		}

		void UpdateView() {
			if (!dislodgeCamera) {
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
			if (cameraHijacked) {
				let cameraMotionDirection = Camera.basis  * cameraMotion;
				
				if (dislodgeCamera) {
					Camera.position += cameraMotionDirection;
				} else {
					let cameraNewPosition = Emulator.cameraPosition.ToVector() + cameraMotionDirection;
					Emulator.cameraPosition = cameraNewPosition.ToVectorInt();
					Emulator.MoveCameraTo(&Emulator.cameraPosition);
				}
			}
		}

		void OnSceneChanged() {
			currentObjIndex = hoveredObjIndex = -1;
			currentAnimGroupIndex = hoveredAnimGroupIndex = -1;

			collisionTerrain.Reload();
		}

		void PushMessageToFeed(String message) {
			messageFeed.Add((message, .Now + TimeSpan(0, 0, 2)));
		}

		void DrawGameCameraFrustrum() {
			let cameraBasis = Emulator.cameraBasisInv.ToMatrixCorrected().Transpose();
			let cameraBasisCorrected = Matrix(cameraBasis.y, cameraBasis.z, -cameraBasis.x);
			let renderer = WindowApp.renderer;

			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.cameraPosition, Emulator.cameraPosition + cameraBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

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

			renderer.DrawLine(nearTopLeft, farTopLeft , .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopRight, farTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomRight, farBottomRight, .(16,16,16), .(16,16,16));
			
			renderer.DrawLine(nearTopLeft, nearTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearBottomLeft, nearBottomRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopLeft, nearBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(nearTopRight, nearBottomRight, .(16,16,16), .(16,16,16));

			renderer.DrawLine(farTopLeft, farTopRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farBottomLeft, farBottomRight, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farTopLeft, farBottomLeft, .(16,16,16), .(16,16,16));
			renderer.DrawLine(farTopRight, farBottomRight, .(16,16,16), .(16,16,16));
		}

		void DrawSpyroInformation() {
			let renderer = WindowApp.renderer;
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroIntendedVelocity / 10, 25, Renderer.Color(255,255,0), renderer);
			DrawUtilities.Arrow(Emulator.spyroPosition, Emulator.spyroPhysicsVelocity / 10, 50, Renderer.Color(255,128,0), renderer);

			let viewerSpyroBasis = Emulator.spyroBasis.ToMatrixCorrected();
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(500,0,0), .(255,0,0), .(255,0,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,500,0), .(0,255,0), .(0,255,0));
			renderer.DrawLine(Emulator.spyroPosition, Emulator.spyroPosition + viewerSpyroBasis * Vector(0,0,500), .(0,0,255), .(0,0,255));

			let radius = 0x164;

			DrawUtilities.WireframeSphere(Emulator.spyroPosition, viewerSpyroBasis, radius, Renderer.Color(32,32,32), renderer);
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
					.(0,0,0,(.)(192 * fade)), WindowApp.renderer);
				WindowApp.font.Print(message, offsetOrigin + .(2,0,0), .(255,255,255,(.)(255 * fade)),  WindowApp.renderer);
			}
		}

		int GetObjectIndexUnderMouse(ref float closestDepth) {
			var closestObjectIndex = -1;

			hoveredObjects.Clear();
			for (int objectIndex = 0; objectIndex < objectList.Count; objectIndex++) {
				let (address, object) = objectList[objectIndex];
				
				let screenPosition = Camera.SceneToScreen(object.position);

				if (screenPosition.z == 0) {
					continue;
				}

				let selectSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
				if (mousePosition.x < screenPosition.x + selectSize && mousePosition.x > screenPosition.x - selectSize &&
					mousePosition.y < screenPosition.y + selectSize && mousePosition.y > screenPosition.y - selectSize) {

					hoveredObjects.Add(objectIndex);

					if (screenPosition.z < closestDepth) {
						closestObjectIndex = objectIndex;
						closestDepth = screenPosition.z;
					}
				}
			}

			return closestObjectIndex;
		}

		int GetTerrainAnimationGroupIndexUnderMouse(ref float closestDepth) {
			var closestGroupIndex = -1;

			for (int groupIndex = 0; groupIndex < collisionTerrain.animationGroups.Count; groupIndex++) {
				let group = collisionTerrain.animationGroups[groupIndex];
				
				let screenPosition = Camera.SceneToScreen(group.center);

				if (screenPosition.z == 0) {
					continue;
				}

				let selectSize = Camera.SceneSizeToScreenSize(group.radius, screenPosition.z);
				if (screenPosition.z < closestDepth &&
					mousePosition.x < screenPosition.x + selectSize && mousePosition.x > screenPosition.x - selectSize &&
					mousePosition.y < screenPosition.y + selectSize && mousePosition.y > screenPosition.y - selectSize) {

					closestGroupIndex = groupIndex;
					closestDepth = screenPosition.z;
				}
			}

			return closestGroupIndex;
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
			collisionTerrain.wireframe = toggle;
			PushMessageToFeed("Toggled Terrain Wireframe");
		}

		void ToggleOrigins(bool toggle) {
			drawObjectOrigins = toggle;
			PushMessageToFeed("Toggled Object Origins");
		}

		void ToggleInactive(bool toggle) {
			hideInactive = toggle;
			PushMessageToFeed("Toggled Inactive Visibility");
		}

		void ToggleView(bool toggle) {
			dislodgeCamera = toggle;
			if (dislodgeCamera) {
				PushMessageToFeed("Free View");
			} else {
				PushMessageToFeed("Game View");
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
			if (collisionTerrain.overlay == .Deform) {
				currentAnimGroupIndex = -1;
			}

			collisionTerrain.CycleOverlay();

			String overlayType;
			switch (collisionTerrain.overlay) {
				case .None:
					overlayType = "None";
				case .Flags:
					overlayType = "Flags";
				case .Deform:
					overlayType = "Deform";
				case .Water:
					overlayType = "Water";
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
