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
		bool showManipulator = false;

		// Scene
		bool drawLimits;

		// Objects
		Dictionary<uint16, MobyModelSet> modelSets = new .();

		// UI
		public static Vector3 cursor3DPosition;

		List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		MessageFeed messageFeed;
		Button togglePauseButton, stepButton, teleportButton, recordButton;

		Texture playTexture = new .("images/ui/play.png") ~ delete _; 
		Texture pauseTexture = new .("images/ui/pause.png") ~ delete _; 
		Texture stepTexture = new .("images/ui/step.png") ~ delete _;
		Texture toggledTexture = new .("images/ui/toggle_enabled.png") ~ delete _;

		Texture cameraIconTexture = new .("images/ui/icon_camera.png") ~ delete _; 
		Texture sceneIconTexture = new .("images/ui/icon_scene.png") ~ delete _;
		Texture objectIconTexture = new .("images/ui/icon_object.png") ~ delete _;
		Texture otherIconTexture = new .("images/ui/icon_other.png") ~ delete _;

		Texture gemIconTexture = new .("images/ui/icon_gem.png") ~ delete _;
		Texture gemHolderIconTexture = new .("images/ui/icon_gem_holder.png") ~ delete _;
		Texture basketIconTexture = new .("images/ui/icon_basket.png") ~ delete _;
		Texture vaseIconTexture = new .("images/ui/icon_vase.png") ~ delete _;
		Texture bottleIconTexture = new .("images/ui/icon_bottle.png") ~ delete _;

		Panel cornerMenu;
		bool cornerMenuVisible;
		float cornerMenuInterp;

		GUIElement cameraOptionGroup, sceneOptionGroup, objectOptionGroup, otherOptionGroup;

		Panel collisionOptionGroup, nearTerrainToggleGroup;
		
		Panel sideInspector;
		bool sideInspectorVisible;
		float sideInspectorInterp;

		Inspector mainInspector;
		Inspector.Property<uint8> nextModelProperty;
		Inspector.Property<uint8> keyframeProperty;
		Inspector.Property<uint8> nextKeyframeProperty;

		Toggle freecamToggle;

		(Toggle button, String label, delegate void() event)[6] toggleList = .(
			(null, "Object Origin Axis", new () => ToggleOrigins(toggleList[0].button.value)),
			(null, "Object Models", new () => { ToggleModels(toggleList[1].button.value); toggleList[2].button.Enabled = toggleList[1].button.value; }),
			(null, "Object Models (Exp.)", new () => ToggleModelsExperimental(toggleList[2].button.value)),
			(null, "Inactive Objects", new () => ToggleInactive(toggleList[3].button.value)),
			(null, "Display Icons", new () => {displayIcons = toggleList[4].button.value;}),
			(null, "All Visual Moby Data", new () => {displayAllData = toggleList[5].button.value;})
		);

		Toggle pinInspectorButton, pinMenuButton;

		Timeline timeline;

		GUIElement faceMenu;
		Input textureIndexInput, rotationInput, depthOffsetInput;
		Toggle flipNormalToggle, doubleSidedToggle;

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
			cornerMenu.Offset = .(.Zero, .(200,180));
			cornerMenu.tint = .(0,0,0);
			cornerMenu.texture = GUIElement.bgTexture;
			GUIElement.PushParent(cornerMenu);

			pinMenuButton = new .();

			pinMenuButton.Anchor = .(1, 1, 0, 0);
			pinMenuButton.Offset = .(-16, 0, 0, 16);
			pinMenuButton.Offset.Shift(-2,2);
			pinMenuButton.toggleIconTexture = toggledTexture;

			// Tabs
			var tab = new Button();
			tab.Offset = .(0, 32, 0, 32) .. Shift(8,8);
			tab.normalTexture = tab.pressedTexture = GUIElement.bgOutlineTexture;
			tab.normalColor = .(32,32,32);
			tab.hoveredColor = .(128,128,128);
			tab.pressedColor = .(255,255,255);
			tab.iconTexture = cameraIconTexture;
			tab.OnActuated.Add(new () => {
				cameraOptionGroup.visible = true;
				sceneOptionGroup.visible = false;
				objectOptionGroup.visible = false;
				otherOptionGroup.visible = false;
			});

			tab = new Button();
			tab.Offset = .(0, 32, 0, 32) .. Shift(8 + 36,8);
			tab.normalTexture = tab.pressedTexture = GUIElement.bgOutlineTexture;
			tab.normalColor = .(32,32,32);
			tab.hoveredColor = .(128,128,128);
			tab.pressedColor = .(255,255,255);
			tab.iconTexture = sceneIconTexture;
			tab.OnActuated.Add(new () => {
				cameraOptionGroup.visible = false;
				sceneOptionGroup.visible = true;
				objectOptionGroup.visible = false;
				otherOptionGroup.visible = false;
			});
			
			tab = new Button();
			tab.Offset = .(0, 32, 0, 32) .. Shift(8 + 36*2,8);
			tab.normalTexture = tab.pressedTexture = GUIElement.bgOutlineTexture;
			tab.normalColor = .(32,32,32);
			tab.hoveredColor = .(128,128,128);
			tab.pressedColor = .(255,255,255);
			tab.iconTexture = objectIconTexture;
			tab.OnActuated.Add(new () => {
				cameraOptionGroup.visible = false;
				sceneOptionGroup.visible = false;
				objectOptionGroup.visible = true;
				otherOptionGroup.visible = false;
			});
			
			tab = new Button();
			tab.Offset = .(0, 32, 0, 32) .. Shift(8 + 36*3,8);
			tab.normalTexture = tab.pressedTexture = GUIElement.bgOutlineTexture;
			tab.normalColor = .(32,32,32);
			tab.hoveredColor = .(128,128,128);
			tab.pressedColor = .(255,255,255);
			tab.iconTexture = otherIconTexture;
			tab.OnActuated.Add(new () => {
				cameraOptionGroup.visible = false;
				sceneOptionGroup.visible = false;
				objectOptionGroup.visible = false;
				otherOptionGroup.visible = true;
			});
			
			messageFeed = new .();
			messageFeed.Anchor.start = .(1,0);

			let content = new GUIElement();
			content.Anchor = .(0, 1, 0, 1);
			content.Offset = .(16, -16, 48, -16);
			GUIElement.PushParent(content);

			// Camera
			cameraOptionGroup = new GUIElement();
			cameraOptionGroup.Anchor = .(0, 1, 0, 1);
			GUIElement.PushParent(cameraOptionGroup);

			var text = new Text();
			text.Text = "View";
			text.Offset = .(.(0,1),.Zero);

			var dropdown = new DropdownList();
			dropdown.Anchor = .(0, 1, 0, 0);
			dropdown.Offset = .(84, 0, 0, 16);
			dropdown.AddItem("Game");
			dropdown.AddItem("Free");
			dropdown.AddItem("Lock");
			dropdown.AddItem("Map");
			dropdown.Value = 0;
			dropdown.OnItemSelect.Add(new (option) => ChangeView((.)option));

			freecamToggle = new .();
			freecamToggle.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			freecamToggle.toggleIconTexture = toggledTexture;
			freecamToggle.OnActuated.Add(new () => ToggleFreeCamera(freecamToggle.value));

			text = new Text();
			text.Text = "Free Game (C)amera";
			text.Offset = .(24, 0, 1 + WindowApp.font.height, 0);

			GUIElement.PopParent();

			// Scene
			sceneOptionGroup = new GUIElement();
			sceneOptionGroup.Anchor = .(0, 1, 0, 1);
			GUIElement.PushParent(sceneOptionGroup);
			sceneOptionGroup.visible = false;

			text = new Text();
			text.Text = "Render";
			text.Offset = .(0, 0, 1, 0);

			dropdown = new DropdownList();
			dropdown.Anchor = .(0, 1, 0, 0);
			dropdown.Offset = .(84, 0, 0, 16);
			dropdown.AddItem("Collision");
			dropdown.AddItem("Far");
			dropdown.AddItem("Near LQ");
			dropdown.AddItem("Near HQ");
			dropdown.Value = 0;
			dropdown.OnItemSelect.Add(new (option) => ChangeRender((.)option));

			Toggle button = new .();
			button.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => ToggleSolid(button.value));
			button.SetValue(true);

			text = new Text();
			text.Text = "Solid";
			text.Offset = .(24, 0, 1 * WindowApp.font.height, 0);

			button = new .();
			button.Anchor = .(0.5f, 0.5f, 0, 0);
			button.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => ToggleWireframe(button.value));
			button.SetValue(true);

			text = new Text();
			text.Text = "Wireframe";
			text.Anchor = .(0.5f, 0.5f, 0, 0);
			text.Offset = .(24, 0, 1 * WindowApp.font.height, 0);

			collisionOptionGroup = new .();
			collisionOptionGroup.Anchor = .(0,1,0,0);
			collisionOptionGroup.Offset = .(-2, 2, -2 + 2 * WindowApp.font.height, -2 + 4 * WindowApp.font.height);
			collisionOptionGroup.texture = GUIElement.bgOutlineTexture;
			collisionOptionGroup.tint = .(128,128,128);
			GUIElement.PushParent(collisionOptionGroup);

			text = new Text();
			text.Text = "Overlay";
			text.Offset = .(2,0,2,0);

			dropdown = new DropdownList();
			dropdown.Anchor = .(0.5f,1,0,0);
			dropdown.Offset = .(0,-2,2,18);
			dropdown.AddItem("None");
			dropdown.AddItem("Flags");
			dropdown.AddItem("Deform");
			dropdown.AddItem("Water");
			dropdown.AddItem("Sound");
			dropdown.AddItem("Platform");
			dropdown.Value = 0;
			dropdown.OnItemSelect.Add(new (option) => Terrain.collision.SetOverlay((.)option));
			
			button = new .();
			button.Offset = .(2, 18, 2 + 1 * WindowApp.font.height, 18 + 1 * WindowApp.font.height);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => {
				Terrain.collision.visualizeGrid = button.value;
			});

			text = new Text();
			text.Text = "Show Grid";
			text.Offset = .(26, 0, 2 + 1 * WindowApp.font.height, 0);

			GUIElement.PopParent();

			nearTerrainToggleGroup = new .();
			nearTerrainToggleGroup.Anchor = .(0,1,0,0);
			nearTerrainToggleGroup.Offset = .(-2, 2, -2 + 2 * WindowApp.font.height, -2 + 4 * WindowApp.font.height);
			nearTerrainToggleGroup.texture = GUIElement.bgOutlineTexture;
			nearTerrainToggleGroup.tint = .(128,128,128);
			nearTerrainToggleGroup.visible = false;
			GUIElement.PushParent(nearTerrainToggleGroup);

			Toggle colorsButton = new .();
			colorsButton.Offset = .(2, 18, 2, 18);
			colorsButton.toggleIconTexture = toggledTexture;
			colorsButton.OnActuated.Add(new () => ToggleColors(colorsButton.value));
			colorsButton.SetValue(true);

			text = new Text();
			text.Text = "Color";
			text.Offset = .(26,0,2 + 0 * (text.font.height + 6),0);

			Toggle textureButton = new .();
			textureButton.Anchor = .(0.5f,0.5f,0,0);
			textureButton.Offset = .(0, 16, 2, 18);
			textureButton.toggleIconTexture = toggledTexture;
			textureButton.OnActuated.Add(new () => ToggleTextures(textureButton.value));
			textureButton.SetValue(true);

			text = new Text();
			text.Text = "Texture";
			text.Anchor = .(0.5f,0,0,0);
			text.Offset = .(24,0,2,0);

			button = new .();
			button.Offset = .(2, 18, 2 + 1 * WindowApp.font.height, 18 + 1 * WindowApp.font.height);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => {
				ToggleFadeColors(button.value);
				colorsButton.Enabled = textureButton.Enabled = !button.value;
			});

			text = new Text();
			text.Text = "Show Fade Color";
			text.Offset = .(26,0,2 + (text.font.height + 6),0);
			
			GUIElement.PopParent();

			button = new .();
			button.Offset = .(0, 16, 4 * WindowApp.font.height, 16 + 4 * WindowApp.font.height);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => ToggleLimits(button.value));

			text = new Text();
			text.Text = "Show Height Limits";
			text.Offset = .(24, 0, 1 + 4 * WindowApp.font.height, 0);

			GUIElement.PopParent();

			// Object
			objectOptionGroup = new .();
			objectOptionGroup.Anchor = .(0, 1, 0, 1);
			GUIElement.PushParent(objectOptionGroup);
			objectOptionGroup.visible = false;

			for (let i < toggleList.Count) {
				button = new .();

				button.Offset = .(0, 16, i * WindowApp.font.height, 16 + i * WindowApp.font.height);
				button.toggleIconTexture = toggledTexture;
				button.OnActuated.Add(toggleList[i].event);

				toggleList[i].button = button;

				text = new Text();
				text.Text = toggleList[i].label;
				text.Offset = .(24, 0, 1 + i * WindowApp.font.height, 0);
			}

			GUIElement.PopParent();

			toggleList[0].button.Toggle();
			toggleList[1].button.Toggle();

			// Other
			otherOptionGroup = new .();
			otherOptionGroup.Anchor = .(0, 1, 0, 1);
			GUIElement.PushParent(otherOptionGroup);
			otherOptionGroup.visible = false;

			button = new .();

			button.Offset = .(0, 16, 0, 16);
			button.toggleIconTexture = toggledTexture;
			button.OnActuated.Add(new () => {showManipulator = button.value; });

			text = new Text();
			text.Text = "Enable Manipulator";
			text.Offset = .(24, 0, 1, 0);

			teleportButton = new .();
			
			teleportButton.Anchor = .(0,1,0,0);
			teleportButton.Offset = .(0, 0, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			teleportButton.text = "(T)eleport";
			teleportButton.OnActuated.Add(new => Teleport);
			teleportButton.Enabled = false;
			
			recordButton = new .();

			recordButton.Anchor = .(0,1,0,0);
			recordButton.Offset = .(0, 0, 2 * WindowApp.font.height, 16 + 2 * WindowApp.font.height);
			recordButton.text = "(R)ecord";
			recordButton.OnActuated.Add(new => RecordReplay);
			
			GUIElement.PopParent();
			GUIElement.PopParent();
			GUIElement.PopParent();
			
			sideInspector = new .();
			sideInspector.Anchor = .(1,1,0,1);
			sideInspector.Offset = .(-300,0,0,0);
			sideInspector.texture = GUIElement.bgTexture;
			sideInspector.tint = .(0,0,0);
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

			mainInspector.AddProperty<uint8>("Model/Anim", 0x3c);
			nextModelProperty = mainInspector.AddProperty<uint8>("Nxt Mdl/Anim", 0x3d);
			keyframeProperty = mainInspector.AddProperty<uint8>("Keyframe", 0x3e);
			nextKeyframeProperty = mainInspector.AddProperty<uint8>("Nxt Keyframe", 0x3f);

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
			textureIndexInput.OnXcrement = new => Inspector.Property<int>.XcrementNumber;

			textureIndexInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let quadCount = Emulator.active.installment == .SpyroTheDragon ? 21 : 6;
					if (val * quadCount < Terrain.textures.Count) {
						text .. Clear().AppendF("{}", BitEdit.Get!(val, 0x7f));

						return true;
					}
				}
				return false;
			};

			textureIndexInput.OnSubmit.Add(new (text) => {
				if (int.Parse(text) case .Ok(var val)) {
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
				}
			});

			rotationInput = new .();
			rotationInput.Anchor = .(0, 0, 1, 1);
			rotationInput.Offset = .(0,64,0,WindowApp.bitmapFont.height - 2);
			rotationInput.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -4 + 1);
			rotationInput.OnXcrement = new => Inspector.Property<int>.XcrementNumber;
			rotationInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let maskedVal = BitEdit.Get!(val, 0b0011);
					text .. Clear().AppendF("{}", maskedVal);
					
					return true;
				}
				return false;
			};

			rotationInput.OnSubmit.Add(new (text) => {
				if (int.Parse(text) case .Ok(var val)) {
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
				}
			});

			depthOffsetInput = new .();
			depthOffsetInput.Anchor = .(0, 0, 1, 1);
			depthOffsetInput.Offset = .(0,64,0,WindowApp.bitmapFont.height - 2);
			depthOffsetInput.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -2 + 1);
			depthOffsetInput.OnXcrement = new => Inspector.Property<int>.XcrementNumber;
			depthOffsetInput.OnValidate = new (text) => {
				if (int.Parse(text) case .Ok(let val)) {
					let maskedVal = BitEdit.Get!(val, 0b0011);
					text .. Clear().AppendF("{}", maskedVal);
					
					return true;
				}
				return false;
			};

			depthOffsetInput.OnSubmit.Add(new (text) => {
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
				}
			});

			flipNormalToggle = new .();
			flipNormalToggle.Anchor = .(0, 0, 1, 1);
			flipNormalToggle.Offset = .(0,16,0,16);
			flipNormalToggle.Offset.Shift(256 + 128 + 32, WindowApp.bitmapFont.height * -3 + 2);
			flipNormalToggle.toggleIconTexture = toggledTexture;
			flipNormalToggle.OnActuated.Add(new () => {
				let visualMesh = Terrain.regions[ViewerSelection.currentRegionIndex];
				int faceIndex = ?;
				if (ViewerSelection.currentRegionTransparent) {
					faceIndex = visualMesh.nearFaceTransparentIndices[ViewerSelection.currentTriangleIndex];
				} else {
					faceIndex = visualMesh.nearFaceIndices[ViewerSelection.currentTriangleIndex];
				}
				let face = visualMesh.GetNearFace(faceIndex);
				face.flipped = flipNormalToggle.value;
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
			stepButton.Enabled = Emulator.active.Paused;

			freecamToggle.value = teleportButton.Enabled = Emulator.active.CameraMode;
			if (Emulator.active.CameraMode) {
				freecamToggle.iconTexture = freecamToggle.toggleIconTexture;
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
	
					if (object.IsNull) {
						break;
					}

					Moby.allocated.Add(object);
					
					objPointer += sizeof(Moby);
				}
			}

			cornerMenuInterp = Math.MoveTo(cornerMenuInterp, cornerMenuVisible ? 1 : 0, 0.1f);
			cornerMenu.Offset = .(.(-200 * (1 - cornerMenuInterp), 0), .(200,180));

			sideInspectorInterp = Math.MoveTo(sideInspectorInterp, sideInspectorVisible ? 1 : 0, 0.1f);
			sideInspector.Offset = .(.(-300 * sideInspectorInterp,0), .(300,0));

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
				flipNormalToggle.SetValue(face.flipped);
				doubleSidedToggle.SetValue(face.renderInfo.doubleSided);
			}

			if (Emulator.active.loadingStatus == .Loading) {
				return;
			}

			Terrain.Update();

			if (showManipulator && (Emulator.active.loadingStatus == .Idle && Emulator.active.gameState <= 1)) {
				if (ViewerSelection.currentObjIndex > -1) {
					let moby = Moby.allocated[ViewerSelection.currentObjIndex];
					Translator.Update(moby.position, moby.basis);
				} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
					Translator.Update(Terrain.collision.mesh.vertices[ViewerSelection.currentTriangleIndex], .Identity);
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
				if (!object.IsNull && (object.IsActive || showInactive)) {
					if ((!showManipulator || ViewerSelection.currentObjIndex != Moby.allocated.Count) && drawObjectOrigins) {
						object.DrawOriginAxis();
					}

					if (drawObjectModels) {
						DrawMoby(object);
					}
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
				WindowApp.bitmapFont.Print(scope String() .. Append("Flip Normal"), .(260, WindowApp.height - WindowApp.bitmapFont.height * 3), .(255,255,255));
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
							freecamToggle.Toggle();
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
								} else if (Terrain.renderMode == .Collision && ViewerSelection.currentTriangleIndex > -1) {
									Translator.OnDragged.Add(new (position) => {
										var triangle = Terrain.collision.GetTriangle(ViewerSelection.currentTriangleIndex / 3);
										triangle[ViewerSelection.currentTriangleIndex % 3] = (.)position;
										Terrain.collision.SetTriangle((.)ViewerSelection.currentTriangleIndex / 3, triangle, true);
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

						if (!(showManipulator && Translator.hovered)) {
							Selection.Select();
							
							if (ViewerSelection.currentObjIndex > -1) {
								let address = Moby.GetAddress(ViewerSelection.currentObjIndex);
								let reference = &Moby.allocated[ViewerSelection.currentObjIndex];
								mainInspector.SetData(address, reference);

								Emulator.Address modelSetAddress = ?;
								Emulator.modelPointers[(int)Emulator.active.rom].GetAtIndex(&modelSetAddress, reference.objectTypeID);

								let possiblyAnimated = reference.HasModel && (int32)modelSetAddress < 0;
								nextModelProperty.ReadOnly = !possiblyAnimated;
								keyframeProperty.ReadOnly = !possiblyAnimated;
								nextKeyframeProperty.ReadOnly = !possiblyAnimated;
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
						if (Emulator.active.loadingStatus == .Idle || Emulator.active.loadingStatus == .CutsceneIdle) {
							cornerMenuVisible = !Translator.dragged && pinMenuButton.value || ((cornerMenuVisible && WindowApp.mousePosition.x < 200 || WindowApp.mousePosition.x < 10) && WindowApp.mousePosition.y < 180);
							sideInspectorVisible = !Translator.dragged && ViewerSelection.currentObjIndex > -1 && (pinInspectorButton.value || (sideInspectorVisible && WindowApp.mousePosition.x > WindowApp.width - 300 || WindowApp.mousePosition.x > WindowApp.width - 10));
						} else {
							cornerMenuVisible = sideInspectorVisible = false;
						}

						if (showManipulator && Translator.MouseMove(WindowApp.mousePosition)) {
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
								if (teleportButton.Enabled) {
									Teleport();
								}
							}
							case .C : {
								freecamToggle.Toggle();
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
						if (object.[Friend]o != 0xff) {
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
						if (object.[Friend]o == 0xff) {
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
		
		void OnSceneChanging() {
			Selection.Reset();

			// Clear model data since the texture locations change in VRAM for every level
			// Also since the object models have stopped drawing beyond this point
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			modelSets.Clear();

			lastUpdatedSceneChanging = .Now;

			faceMenu.visible = false;
			sideInspectorVisible = false;
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

		void ToggleWireframe(bool toggle) {
			Terrain.wireframe = toggle;
			messageFeed.PushMessage("Toggled Render Wireframe");
		}

		void ToggleSolid(bool toggle) {
			Terrain.solid = toggle;
			messageFeed.PushMessage("Toggled Render Solid");
		}

		void ToggleTextures(bool toggle) {
			Terrain.textured = toggle;
			messageFeed.PushMessage("Toggled Terrain Textures");
		}

		void ToggleColors(bool toggle) {
			Terrain.Colored = toggle;
			messageFeed.PushMessage("Toggled Terrain Vertex Colors");
		}

		void ToggleFadeColors(bool toggle) {
			Terrain.UsingFade = toggle;
			messageFeed.PushMessage("Toggled Terrain Fade Colors");
		}

		void ToggleOrigins(bool toggle) {
			drawObjectOrigins = toggle;
			messageFeed.PushMessage("Toggled Object Origins");
		}

		void ToggleModels(bool toggle) {
			drawObjectModels = toggle;
			messageFeed.PushMessage("Toggled Object Models");
		}

		void ToggleModelsExperimental(bool toggle) {
			drawObjectExperimentalModels = toggle;
			messageFeed.PushMessage("Toggled Object Models Experimental");
		}

		void ToggleInactive(bool toggle) {
			showInactive = toggle;
			messageFeed.PushMessage("Toggled Inactive Visibility");
		}

		void ChangeView(ViewMode mode) {
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

			teleportButton.Enabled = mode == .Free || mode == .Game && Emulator.active.CameraMode;

			viewMode = mode;
		}

		void ChangeRender(Terrain.RenderMode renderMode) {
			Terrain.renderMode = renderMode;

			switch (renderMode) {
				case .Collision:
					ViewerSelection.currentTriangleIndex = -1;
					ViewerSelection.currentRegionIndex = -1;
					faceMenu.visible = false;
					nearTerrainToggleGroup.visible = false;
					collisionOptionGroup.visible = true;

				case .Far:
					ViewerSelection.currentTriangleIndex = -1;
					faceMenu.visible = false;
					nearTerrainToggleGroup.visible = false;
					collisionOptionGroup.visible = false;

				case .NearLQ, .NearHQ:
					nearTerrainToggleGroup.visible = true;
					collisionOptionGroup.visible = false;
			}
		}

		void ToggleFreeCamera(bool toggle) {
			if (toggle) {
				Emulator.active.KillCameraUpdate();
				messageFeed.PushMessage("Free Camera");
				teleportButton.Enabled = true;
			} else {
				Emulator.active.RestoreCameraUpdate();
				messageFeed.PushMessage("Game Camera");
				teleportButton.Enabled = viewMode != .Game;
			}
		}

		void ToggleLimits(bool toggle) {
			drawLimits = toggle;
			messageFeed.PushMessage("Toggled Height Limits");
		}

		void RecordReplay() {
			if (!Recording.Active) {
				Recording.Record();
				timeline.visible = true;
				recordButton.text = "Stop Record";
				messageFeed.PushMessage("Begin Recording");
			} else {
				Recording.StopRecord();
				recordButton.text = "Record";
				messageFeed.PushMessage("Stopped Recording");
			}
		}

		void Teleport() {
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
