using SDL2;
using System;
using System.Collections;

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

		ViewMode viewMode = .Game;

		/// Is in-game camera no being updated externally
		bool cameraHijacked;

		float cameraSpeed = 64;

		/// The overall motion direction
		Vector3 cameraMotionDirection;

		Vector3 viewEulerRotation;
		Vector3 lockOffset;

		// Options
		bool drawObjectOrigins = true;
		public static bool hideInactive = false;
		bool displayIcons = false;
		bool displayAllData = false;
		bool showManipulator = false;

		// Scene
		bool drawLimits;

		// Objects
		Dictionary<uint16, MobyModelSet> modelSets = new .();

		// UI
		public static Vector3 cursor3DPosition;

		List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		MessageFeed messageFeed;
		Button togglePauseButton, stepButton, cycleTerrainOverlayButton, teleportButton;

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

		Inspector mainInspector;

		(Toggle button, String label)[9] toggleList = .(
			(null, "Wirefra(m)e"),
			(null, "Object (O)rigin Axis"),
			(null, "Hide (I)nactive Objects"),
			(null, "(H)eight Limits"),
			(null, "Free Game (C)amera"),
			(null, "Display Icons"),
			(null, "All Visual Moby Data"),
			(null, "(E)nable Manipulator"),
			(null, "Record")
		);

		Toggle pinInspectorButton;

		Timeline timeline;

		GUIElement faceMenu;
		Input textureIndexInput, rotationInput, depthOffsetInput;
		Toggle mirrorToggle, doubleSidedToggle;

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

			cornerMenu = new .();
			cornerMenu.Offset = .(.Zero, .(260,200));
			GUIElement.PushParent(cornerMenu);

			messageFeed = new .();
			messageFeed.Anchor.start = .(1,0);

			Button viewButton1 = new .();
			Button viewButton2 = new .();
			Button viewButton3 = new .();
			Button viewButton4 = new .();
			
			viewButton1.Offset = .(16,58,16,32);
			viewButton2.Offset = .(58,100,16,32);
			viewButton3.Offset = .(100,142,16,32);
			viewButton4.Offset = .(142,184,16,32);

			viewButton1.text = "Game";
			viewButton2.text = "Free";
			viewButton3.text = "Lock";
			viewButton4.text = "Map";

			viewButton1.enabled = false;

			viewButton1.OnActuated.Add(new () => {
				viewButton1.enabled = false;
				viewButton2.enabled = viewButton3.enabled = viewButton4.enabled = true;
				ToggleView(.Game);
			});
			viewButton2.OnActuated.Add(new () => {
				viewButton2.enabled = false;
				viewButton1.enabled = viewButton3.enabled = viewButton4.enabled = true;
				ToggleView(.Free);
			});
			viewButton3.OnActuated.Add(new () => {
				viewButton3.enabled = false;
				viewButton1.enabled = viewButton2.enabled = viewButton4.enabled = true;
				ToggleView(.Lock);
			});
			viewButton4.OnActuated.Add(new () => {
				viewButton4.enabled = false;
				viewButton1.enabled = viewButton2.enabled = viewButton3.enabled = true;
				ToggleView(.Map);
			});

			Button renderButton1 = new .();
			Button renderButton2 = new .();
			Button renderButton3 = new .();

			renderButton1.Offset = .(16,72,36,52);
			renderButton2.Offset = .(72,128,36,52);
			renderButton3.Offset = .(128,184,36,52);

			renderButton1.text = "Collision";
			renderButton2.text = "Far";
			renderButton3.text = "Near";

			renderButton1.enabled = false;

			renderButton1.OnActuated.Add(new () => {
				renderButton1.enabled = false;
				renderButton2.enabled = renderButton3.enabled = cycleTerrainOverlayButton.enabled = true;
				Terrain.renderMode = .Collision;
				ViewerSelection.currentTriangleIndex = -1;
				ViewerSelection.currentRegionIndex = -1;
				faceMenu.visible = false;
			});
			renderButton2.OnActuated.Add(new () => {
				renderButton2.enabled = cycleTerrainOverlayButton.enabled = false;
				renderButton1.enabled = renderButton3.enabled = true;
				Terrain.renderMode = .Far;
				ViewerSelection.currentTriangleIndex = -1;
				faceMenu.visible = false;
			});
			renderButton3.OnActuated.Add(new () => {
				/*viewButton3.enabled =*/ cycleTerrainOverlayButton.enabled = false;
				renderButton2.enabled = renderButton1.enabled = true;
				Terrain.renderMode = Terrain.renderMode == .NearLQ ? .NearHQ : .NearLQ;
			});

			for (let i < toggleList.Count) {
				Toggle button = new .();

				button.Offset = .(16, 32, 16 + (i + 2) * WindowApp.font.height, 32 + (i + 2) * WindowApp.font.height);
				button.toggleIconTexture = toggledTexture;

				toggleList[i].button = button;
			}

			toggleList[1].button.Toggle();

			toggleList[0].button.OnActuated.Add(new () => {ToggleWireframe(toggleList[0].button.value);});
			toggleList[1].button.OnActuated.Add(new () => {ToggleOrigins(toggleList[1].button.value);});
			toggleList[2].button.OnActuated.Add(new () => {ToggleInactive(toggleList[2].button.value);});
			toggleList[3].button.OnActuated.Add(new () => {ToggleLimits(toggleList[3].button.value);});
			toggleList[4].button.OnActuated.Add(new () => {ToggleFreeCamera(toggleList[4].button.value);});
			toggleList[5].button.OnActuated.Add(new () => {displayIcons = toggleList[5].button.value;});
			toggleList[6].button.OnActuated.Add(new () => {displayAllData = toggleList[6].button.value;});
			toggleList[7].button.OnActuated.Add(new () => {showManipulator = toggleList[7].button.value;});
			toggleList[8].button.OnActuated.Add(new () => {
				if (toggleList[8].button.value) {
					Recording.Record();
					timeline.visible = true;
				} else {
					Recording.StopRecord();
				}
			});

			cycleTerrainOverlayButton = new .();

			cycleTerrainOverlayButton.Offset = .(16, 180, 16 + (toggleList.Count + 2) * WindowApp.font.height, 32 + (toggleList.Count + 2) * WindowApp.font.height);
			cycleTerrainOverlayButton.text = "Terrain Over(l)ay";
			cycleTerrainOverlayButton.OnActuated.Add(new => CycleTerrainOverlay);

			teleportButton = new .();

			teleportButton.Offset = .(16, 180, 16 + (toggleList.Count + 3) * WindowApp.font.height, 32 + (toggleList.Count + 3) * WindowApp.font.height);
			teleportButton.text = "(T)eleport";
			teleportButton.OnActuated.Add(new => Teleport);
			teleportButton.enabled = false;

			GUIElement.PopParent();
			
			sideInspector = new .();
			sideInspector.Anchor = .(1,1,0,1);
			sideInspector.Offset = .(-300,0,0,0);
			GUIElement.PushParent(sideInspector);

			pinInspectorButton = new .();

			pinInspectorButton.Offset = .(0, 16, 0, 16);
			pinInspectorButton.Offset.Shift(2,2);
			pinInspectorButton.toggleIconTexture = toggledTexture;
			
			mainInspector = new .("Object");
			mainInspector.Anchor = .(0,1,0,1);
			mainInspector.Offset = .(4,-4,24,-4);

			mainInspector.AddProperty<int8>("State", 0x48).ReadOnly = true;

			mainInspector.AddProperty<int32>("Position", 0xc, "XYZ");
			mainInspector.AddProperty<int8>("Rotation", 0x44, "XYZ");
			
			mainInspector.AddProperty<uint8>("Type #ID", 0x36).ReadOnly = true;
			mainInspector.AddProperty<Emulator.Address>("Data", 0x0).ReadOnly = true;
			mainInspector.AddProperty<int8>("Held Value", 0x50);

			mainInspector.AddProperty<uint16>("Model #ID", 0x3c);
			mainInspector.AddProperty<uint8>("Color", 0x54, "RGBA");
			mainInspector.AddProperty<uint8>("LOD Distance", 0x4e).postTextInput = " x 1000";

			GUIElement.PopParent();

			timeline = new .();
			timeline.Anchor = .(0, 1, 1, 1);
			timeline.Offset = .(0, 0, -64, 0);
			timeline.visible = false;

			faceMenu = new .();
			faceMenu.Anchor = .(0, 0, 1, 1);
			faceMenu.Offset = .(0,490,-128,0);
			faceMenu.visible = false;
			GUIElement.PushParent(faceMenu);

			textureIndexInput = new .();
			textureIndexInput.Anchor = .(0, 0, 1, 1);
			textureIndexInput.Offset = .(0,64,0,WindowApp.bitmapFont.height - 2);
			textureIndexInput.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -5 + 1);
			textureIndexInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
					if (val * quadCount < Terrain.textures.Count) {
						let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
						int faceIndex = ?;
						if (ViewerSelection.currentRegionTransparent) {
							faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
						} else {
							faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
						}
						let face = visualMesh.GetNearFace(faceIndex);
						face.renderInfo.textureIndex = (.)val;
						visualMesh.SetNearFace(face, faceIndex);

						text .. Clear().AppendF("{}", face.renderInfo.textureIndex);

						return true;
					}
				}
				return false;
			};

			rotationInput = new .();
			rotationInput.Anchor = .(0, 0, 1, 1);
			rotationInput.Offset = .(0,64,0,WindowApp.bitmapFont.height - 2);
			rotationInput.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -4 + 1);
			rotationInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
					int faceIndex = ?;
					if (ViewerSelection.currentRegionTransparent) {
						faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
					} else {
						faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
					}
					let face = visualMesh.GetNearFace(faceIndex);
					face.renderInfo.rotation = (.)val;
					visualMesh.SetNearFace(face, faceIndex);

					text .. Clear().AppendF("{}", face.renderInfo.rotation);
					
					return true;
				}
				return false;
			};

			depthOffsetInput = new .();
			depthOffsetInput.Anchor = .(0, 0, 1, 1);
			depthOffsetInput.Offset = .(0,64,0,WindowApp.bitmapFont.height - 2);
			depthOffsetInput.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -2 + 1);
			depthOffsetInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
					int faceIndex = ?;
					if (ViewerSelection.currentRegionTransparent) {
						faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
					} else {
						faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
					}
					let face = visualMesh.GetNearFace(faceIndex);
					face.renderInfo.depthOffset = (.)val;
					visualMesh.SetNearFace(face, faceIndex);
					
					text .. Clear().AppendF("{}", face.renderInfo.depthOffset);
					
					return true;
				}
				return false;
			};

			mirrorToggle = new .();
			mirrorToggle.Anchor = .(0, 0, 1, 1);
			mirrorToggle.Offset = .(0,16,0,16);
			mirrorToggle.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -3 + 2);
			mirrorToggle.toggleIconTexture = toggledTexture;
			mirrorToggle.OnActuated.Add(new () => {
				let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
				int faceIndex = ?;
				if (ViewerSelection.currentRegionTransparent) {
					faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
				} else {
					faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
				}
				let face = visualMesh.GetNearFace(faceIndex);
				face.flipped = mirrorToggle.value;
				visualMesh.SetNearFace(face, faceIndex);
			});

			doubleSidedToggle = new .();
			doubleSidedToggle.Anchor = .(0, 0, 1, 1);
			doubleSidedToggle.Offset = .(0,16,0,16);
			doubleSidedToggle.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -1 + 2);
			doubleSidedToggle.toggleIconTexture = toggledTexture;
			doubleSidedToggle.OnActuated.Add(new () => {
				if (faceMenu.visible) {
					let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
					int faceIndex = ?;
					if (ViewerSelection.currentRegionTransparent) {
						faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
					} else {
						faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
					}
					let face = visualMesh.GetNearFace(faceIndex);
					face.renderInfo.doubleSided = doubleSidedToggle.value;
					visualMesh.SetNearFace(face, faceIndex);
				}
			});

			GUIElement.PopParent();
		}

		public ~this() {
			Terrain.Clear();

			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			delete modelSets;

			Recording.ClearRecord();
		}

		public override void Enter() {
			GUIElement.SetActiveGUI(guiElements);

			togglePauseButton.iconTexture = Emulator.active.Paused ? playTexture : pauseTexture;
			stepButton.enabled = Emulator.active.Paused;

			toggleList[4].button.value = teleportButton.enabled = Emulator.active.CameraMode;
			if (Emulator.active.CameraMode) {
				toggleList[4].button.iconTexture = toggleList[4].button.toggleIconTexture;
			}
		}

		public override void Exit() {
			GUIElement.SetActiveGUI(null);
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
	
					if (object.dataPointer.IsNull) {
						break;
					}

					Moby.allocated.Add(object);
					
					objPointer += sizeof(Moby);
				}
			}

			cornerMenuInterp = Math.MoveTo(cornerMenuInterp, cornerMenuVisible ? 1 : 0, 0.1f);
			cornerMenu.Offset = .(.(-200 * (1 - cornerMenuInterp), 0), .(200,280));

			sideInspectorInterp = Math.MoveTo(sideInspectorInterp, sideInspectorVisible ? 1 : 0, 0.1f);
			sideInspector.Offset = .(.(-300 * sideInspectorInterp,0), .(300,0));

			if (Emulator.active.loadingStatus == .Loading || Emulator.active.gameState > 0) {
				return;
			}

			if (faceMenu.visible) {
				let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
				int faceIndex = ?;
				if (ViewerSelection.currentRegionTransparent) {
					faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
				} else {
					faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
				}

				let face = visualMesh.GetNearFace(faceIndex);
				
				textureIndexInput.SetValidText(scope String() .. AppendF("{}", face.renderInfo.textureIndex));
				rotationInput.SetValidText(scope String() .. AppendF("{}", face.renderInfo.rotation));
				depthOffsetInput.SetValidText(scope String() .. AppendF("{}", face.renderInfo.depthOffset));
				mirrorToggle.SetValue(face.flipped);
				doubleSidedToggle.SetValue(face.renderInfo.doubleSided);
			}

			Terrain.Update();

			if (showManipulator) {
				if (ViewerSelection.currentObjIndex > -1) {
					let moby = Moby.allocated[ViewerSelection.currentObjIndex];
					Translator.Update(moby.position, moby.basis);
				/*} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
					Translator.Update(Terrain.collision.mesh.vertices[ViewerSelection.currentTriangleIndex * 3], .Identity);*/
				} else {
					Translator.Update(Emulator.active.SpyroPosition, Emulator.active.spyroBasis.ToMatrixCorrected());
				}
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
			
			for (let object in Moby.allocated) {
				if (!hideInactive || object.IsActive) {
					if ((!showManipulator || ViewerSelection.currentObjIndex != Moby.allocated.Count) && drawObjectOrigins) {
						object.DrawOriginAxis();
					}

					DrawMoby(object);
				}
			}

			if (displayAllData) {
				for (let object in Moby.allocated) {
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

			if (ViewerSelection.currentRegionIndex > 0) {
				let region = Terrain.regions[ViewerSelection.currentRegionIndex];
				DrawUtilities.Axis(.((int)region.metadata.centerX * 16, (int)region.metadata.centerY * 16, (int)region.metadata.centerZ * 16), .Scale(1000));
			}

			if (ViewerSelection.hoveredObjIndex >= Moby.allocated.Count || ViewerSelection.currentObjIndex >= Moby.allocated.Count) {
				Selection.Reset();
				ViewerSelection.hoveredObjects.Clear();
			}

			DrawSpyroInformation();

			// Draw all queued instances
			PrimitiveShape.DrawInstances();

			for (let modelSet in modelSets.Values) {
				modelSet.DrawInstances();
			}

			// Draw world's origin
			Renderer.DrawLine(.Zero, .(10000,0,0), .(255,255,255), .(255,0,0));
			Renderer.DrawLine(.Zero, .(0,10000,0), .(255,255,255), .(0,255,0));
			Renderer.DrawLine(.Zero, .(0,0,10000), .(255,255,255), .(0,0,255));

			if (drawLimits) {
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
				for	(let object in Moby.allocated) {
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
			} else if (faceMenu.visible) {
				let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
				let metadata = visualMesh.metadata;
				
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Region: {}", ViewerSelection.currentRegionIndex), .(0, WindowApp.height - (.)WindowApp.bitmapFont.height * 11), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Center: <{},{},{}>", (int)metadata.centerX * 16, (int)metadata.centerY * 16, (int)metadata.centerZ * 16), .(0, WindowApp.height - WindowApp.bitmapFont.height * 10), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Offset: <{},{},{}>", (int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16), .(0, WindowApp.height - WindowApp.bitmapFont.height * 9), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Scaled Vertically: {}", metadata.verticallyScaledDown), .(0, WindowApp.height - WindowApp.bitmapFont.height * 8), .(255,255,255));

				int faceIndex = ?;
				if (ViewerSelection.currentRegionTransparent) {
					faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
				} else {
					faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
				}

				let face = visualMesh.GetNearFace(faceIndex);
				
				let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
				TextureQuad* textureInfo = &Terrain.textures[face.renderInfo.textureIndex * quadCount];
				if (Emulator.active.installment != .SpyroTheDragon) {
					textureInfo++;
				}
			
				
				DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height, 256, 490, .(0,0,0,128));

				var partialUV = textureInfo[0].GetVramPartialUV();
				DrawUtilities.Rect(WindowApp.height - 128, WindowApp.height, 0,128, partialUV.leftY, partialUV.leftY + (1f / 16), partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));

				const int[4][2] offsets = .(
					(128, 64),
					(128 + 64, 64),
					(128, 0),
					(128 + 64, 0)
				);
				for (let qi < 4) {
					let offset = offsets[qi];

					partialUV = textureInfo[1 + qi].GetVramPartialUV();
					DrawUtilities.Rect(WindowApp.height - (offset[1] + 64), WindowApp.height - offset[1], offset[0], offset[0] + 64, partialUV.leftY, partialUV.leftY + (1f / 16), partialUV.left, partialUV.right, VRAM.decoded, .(255,255,255));
				}
				
				WindowApp.bitmapFont.Print(scope String() .. AppendF("Face Index: {}", faceIndex), .(260, WindowApp.height - WindowApp.bitmapFont.height * 6), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. Append("Tex Index"), .(260, WindowApp.height - WindowApp.bitmapFont.height * 5), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. Append("Rotation"), .(260, WindowApp.height - WindowApp.bitmapFont.height * 4), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. Append("Mirror"), .(260, WindowApp.height - WindowApp.bitmapFont.height * 3), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. Append("Depth Offset"), .(260, WindowApp.height - WindowApp.bitmapFont.height * 2), .(255,255,255));
				WindowApp.bitmapFont.Print(scope String() .. Append("Double Sided"), .(260, WindowApp.height - WindowApp.bitmapFont.height), .(255,255,255));

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
			DrawUtilities.Rect(0,280,0,200 * cornerMenuInterp, .(0,0,0,192));
			DrawUtilities.Rect(0,WindowApp.height,WindowApp.width - 300 * sideInspectorInterp,WindowApp.width, .(0,0,0,192));

			for (let element in guiElements) {
				if (element.GetVisibility()) {
					element.Draw();
				}
			}

			for (let toggle in toggleList) {
				if (toggle.button.visible) {
					WindowApp.fontSmall.Print(toggle.label, .(toggle.button.drawn.right + 8, toggle.button.drawn.top + 1), .(255,255,255));
				}
			}

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
							toggleList[4].button.Toggle();
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
										var moby = Moby.allocated[ViewerSelection.currentObjIndex];
										moby.position = (.)position;
										Moby.GetAddress(ViewerSelection.currentObjIndex).Write(&moby);
									});
								/*} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
									Translator.OnDragged.Add(new (position) => {
										var triangle = Terrain.collision.triangles[ViewerSelection.currentTriangleIndex].Unpack(false);
										triangle[0] = (.)position;
										Terrain.collision.SetNearVertex((.)ViewerSelection.currentTriangleIndex, triangle, true);
									});*/
								} else {
									Translator.OnDragBegin.Add(new => Emulator.active.KillSpyroUpdate);
									Translator.OnDragged.Add(new (position) => {
										Emulator.active.SpyroPosition = (.)position;
									});
									Translator.OnDragEnd.Add(new => Emulator.active.RestoreSpyroUpdate);
								}
							}
						}

						if (!(showManipulator && Translator.hovered)) {
							Selection.Select();
							
							if (ViewerSelection.currentObjIndex > -1) {
								let address = Moby.GetAddress(ViewerSelection.currentObjIndex);
								let reference = &Moby.allocated[ViewerSelection.currentObjIndex];
								mainInspector.SetData(address, reference);
							} else {
								mainInspector.SetData(.Null, null);
							}
						}

						faceMenu.visible = (Terrain.renderMode == .NearLQ || Terrain.renderMode == .NearHQ) && ViewerSelection.currentRegionIndex > -1 && ViewerSelection.currentTriangleIndex > -1;
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
						if (Emulator.active.loadingStatus == .Idle) {
							cornerMenuVisible = !Translator.dragged && (cornerMenuVisible && WindowApp.mousePosition.x < 200 || WindowApp.mousePosition.x < 10) && WindowApp.mousePosition.y < 260;
							sideInspectorVisible = !Translator.dragged && ViewerSelection.currentObjIndex > -1 && (pinInspectorButton.value || (sideInspectorVisible && WindowApp.mousePosition.x > WindowApp.width - 300 || WindowApp.mousePosition.x > WindowApp.width - 10));
						} else {
							cornerMenuVisible = sideInspectorVisible = false;
						}

						if (showManipulator && Translator.MouseMove(WindowApp.mousePosition)) {
							Selection.Clear();
						} else if (Emulator.active.loadingStatus != .Loading && Emulator.active.gameState == 0) {
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
							case .M : {
								toggleList[0].button.Toggle();
							}
							case .O : {
								toggleList[1].button.Toggle();
							}
							case .L : {
								CycleTerrainOverlay();
							}
							case .K : {
								uint32 health = 0;
								Emulator.healthAddresses[(int)Emulator.active.rom].Write(&health);
							}
							case .T : {
								if (Emulator.active.CameraMode) {
									Teleport();
								}
							}
							case .C : {
								toggleList[4].button.Toggle();
							}
							case .H : {
								toggleList[3].button.Toggle();
							}
							case .I : {
								toggleList[2].button.Toggle();

								/*// Does not currently work as intended
								if (Emulator.InputMode) {
									Emulator.RestoreInputRelay();
									messageFeed.PushMessage("Emulator Input");
								} else {
									Emulator.KillInputRelay();
									messageFeed.PushMessage("Manual Input");
								}*/
							}
							case .E : {
								if (!Translator.dragged) {
									toggleList[7].button.OnActuated();
								}
							}
							case .V : {
								windowApp.GoToState<VRAMViewerState>();
							}
							case .R : {
								Reload();
							}
							case .F : {
								if (Recording.Playing) {
									Recording.StopReplay();
								} else {
									Recording.Replay();
								}
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
					Emulator.active.ReadFromRAM(Emulator.modelPointers[(int)Emulator.active.rom] + 4 * object.objectTypeID, &modelSetAddress, 4);

					if (modelSetAddress != 0) {
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
		
		void OnSceneChanging() {
			Selection.Reset();

			// Clear model data since the texture locations change in VRAM for every level
			// Also since the object models have stopped drawing beyond this point
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			modelSets.Clear();

			lastUpdatedSceneChanging = .Now;
		}

		void OnSceneChanged() {
			Terrain.Clear();
			Terrain.Load();

			lastUpdatedSceneChange = .Now;
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
			if (ViewerSelection.currentTriangleIndex > -1 && ViewerSelection.currentTriangleIndex < Terrain.collision.specialTriangleCount) {
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
			if (Emulator.active.Paused) {
				Emulator.active.RestoreUpdate();
				messageFeed.PushMessage("Resumed Game Update");
				togglePauseButton.iconTexture = pauseTexture;
				stepButton.enabled = false;
			} else {
				Emulator.active.KillUpdate();
				messageFeed.PushMessage("Paused Game Update");
				togglePauseButton.iconTexture = playTexture;
				stepButton.enabled = true;
			}
		}

		void Step() {
			togglePauseButton.iconTexture = playTexture;
			Emulator.active.Step();
		}

		void ToggleWireframe(bool toggle) {
			Terrain.wireframe = toggle;
			messageFeed.PushMessage("Toggled Wireframe");
		}

		void ToggleOrigins(bool toggle) {
			drawObjectOrigins = toggle;
			messageFeed.PushMessage("Toggled Object Origins");
		}

		void ToggleInactive(bool toggle) {
			hideInactive = toggle;
			messageFeed.PushMessage("Toggled Inactive Visibility");
		}

		void ToggleView(ViewMode mode) {
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
				let upperBound = Terrain.collision.upperBound;
				let lowerBound = Terrain.collision.lowerBound;

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

			if (mode == .Lock) {
				lockOffset = Camera.position - Emulator.active.SpyroPosition;
			}

			viewMode = mode;

			switch (viewMode) {
				case .Free: messageFeed.PushMessage("Free View");
				case .Lock: messageFeed.PushMessage("Lock View");
				case .Game: messageFeed.PushMessage("Game View");
				case .Map: messageFeed.PushMessage("Map View");
			}
		}

		void ToggleFreeCamera(bool toggle) {
			if (toggle) {
				Emulator.active.KillCameraUpdate();
				messageFeed.PushMessage("Free Camera");
				teleportButton.enabled = true;
			} else {
				Emulator.active.RestoreCameraUpdate();
				messageFeed.PushMessage("Game Camera");
				teleportButton.enabled = false;
			}
		}

		void ToggleLimits(bool toggle) {
			drawLimits = toggle;
			messageFeed.PushMessage("Toggled Height Limits");
		}

		void CycleTerrainOverlay() {
			if (Terrain.collision.overlay == .Deform) {
				ViewerSelection.currentAnimGroupIndex = -1;
			}

			Terrain.collision.CycleOverlay();

			String overlayType;
			switch (Terrain.collision.overlay) {
				case .None: overlayType = "None";
				case .Flags: overlayType = "Flags";
				case .Deform: overlayType = "Deform";
				case .Water: overlayType = "Water";
				case .Sound: overlayType = "Sound";
				case .Platform: overlayType = "Platform";
			}
			messageFeed.PushMessage(new String() .. AppendF("Terrain Overlay [{}]", overlayType));
		}

		void Teleport() {
			Emulator.active.SpyroPosition = (.)Camera.position;
			messageFeed.PushMessage("Teleported Spyro to Game Camera");
		}

		void Reload() {
			Terrain.Reload();
			Terrain.ReloadAnimations();
		}
	}
}
