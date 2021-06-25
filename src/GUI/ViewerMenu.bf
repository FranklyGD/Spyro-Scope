using System;

namespace SpyroScope {
	class ViewerMenu : Panel {
		bool showing;
		float motionInterp;

		Texture cameraIconTexture = new .("images/ui/icon_camera.png") ~ delete _; 
		Texture sceneIconTexture = new .("images/ui/icon_scene.png") ~ delete _;
		Texture objectIconTexture = new .("images/ui/icon_object.png") ~ delete _;
		Texture otherIconTexture = new .("images/ui/icon_other.png") ~ delete _;

		Toggle pinMenuButton;
		public Toggle freecamToggle, manipulatorToggle, objectSpaceToggle;
		
		GUIElement cameraOptionGroup, sceneOptionGroup, objectOptionGroup, otherOptionGroup;
		public Button teleportButton, recordButton;
		Panel collisionOptionGroup, nearTerrainToggleGroup;

		public this(ViewerState viewerState) : base() {
			(Toggle button, String label, delegate void(bool) event)[6] toggleList = .(
				(null, "Object Origin Axis", new => viewerState.ToggleOrigins),
				(null, "Object Models", new => viewerState.ToggleModels),
				(null, "Object Models (Exp.)", new => viewerState.ToggleModelsExperimental),
				(null, "Inactive Objects", new => viewerState.ToggleInactive),
				(null, "Display Icons", new => viewerState.ToggleIcons),
				(null, "All Visual Moby Data", new => viewerState.ToggleMobyData)
			);

			Offset = .(.Zero, .(200,180));
			tint = .(0,0,0);
			texture = GUIElement.bgTexture;

			GUIElement.PushParent(this);

			pinMenuButton = new .();

			pinMenuButton.Anchor = .(1, 1, 0, 0);
			pinMenuButton.Offset = .(-16, 0, 0, 16);
			pinMenuButton.Offset.Shift(-2,2);

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
			dropdown.OnItemSelect.Add(new (option) => viewerState.ChangeView((.)option));

			freecamToggle = new .();
			freecamToggle.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			freecamToggle.OnToggled.Add(new => viewerState.ToggleFreeCamera);

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
			dropdown.OnItemSelect
				.. Add(new (option) => viewerState.ChangeRender((.)option))
				.. Add(new (option) => OnRenderModeSelect((.)option));

			Toggle button = new .();
			button.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			button.OnToggled.Add(new => viewerState.ToggleSolid);
			button.value = true;

			text = new Text();
			text.Text = "Solid";
			text.Offset = .(24, 0, 1 * WindowApp.font.height, 0);

			button = new .();
			button.Anchor = .(0.5f, 0.5f, 0, 0);
			button.Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);
			button.OnToggled.Add(new => viewerState.ToggleWireframe);
			button.value = true;

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
			button.OnToggled.Add(new (value) => Terrain.collision.visualizeGrid = value);

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
			colorsButton.OnToggled.Add(new => viewerState.ToggleColors);
			colorsButton.value = true;

			text = new Text();
			text.Text = "Color";
			text.Offset = .(26,0,2 + 0 * (text.font.height + 6),0);

			Toggle textureButton = new .();
			textureButton.Anchor = .(0.5f,0.5f,0,0);
			textureButton.Offset = .(0, 16, 2, 18);
			textureButton.OnToggled.Add(new => viewerState.ToggleTextures);
			textureButton.value = true;

			text = new Text();
			text.Text = "Texture";
			text.Anchor = .(0.5f,0,0,0);
			text.Offset = .(24,0,2,0);

			button = new .();
			button.Offset = .(2, 18, 2 + 1 * WindowApp.font.height, 18 + 1 * WindowApp.font.height);
			button.OnToggled.Add(new (value) => {
				viewerState.ToggleFadeColors(value);
				colorsButton.Enabled = textureButton.Enabled = !value;
			});

			text = new Text();
			text.Text = "Show Fade Color";
			text.Offset = .(26,0,2 + (text.font.height + 6),0);

			GUIElement.PopParent();

			button = new .();
			button.Offset = .(0, 16, 4 * WindowApp.font.height, 16 + 4 * WindowApp.font.height);
			button.OnToggled.Add(new => viewerState.ToggleLimits);

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
				button.OnToggled.Add(toggleList[i].event);

				toggleList[i].button = button;

				text = new Text();
				text.Text = toggleList[i].label;
				text.Offset = .(24, 0, 1 + i * WindowApp.font.height, 0);
			}

			GUIElement.PopParent();

			toggleList[0].button.value = true;
			toggleList[1].button.value = true;

			// Other
			otherOptionGroup = new .();
			otherOptionGroup.Anchor = .(0, 1, 0, 1);
			GUIElement.PushParent(otherOptionGroup);
			otherOptionGroup.visible = false;

			manipulatorToggle = new .();
			manipulatorToggle.Offset = .(0, 16, 0, 16);

			text = new Text();
			text.Text = "Enable Manipulator";
			text.Offset = .(24, 0, 1, 0);

			objectSpaceToggle = new .();
			objectSpaceToggle .Offset = .(0, 16, 1 * WindowApp.font.height, 16 + 1 * WindowApp.font.height);

			text = new Text();
			text.Text = "Object Space";
			text.Offset = .(24, 0, 1 + 1 * WindowApp.font.height, 0);

			teleportButton = new .();

			teleportButton.Anchor = .(0,1,0,0);
			teleportButton.Offset = .(0, 0, 2 * WindowApp.font.height, 16 + 2 * WindowApp.font.height);
			teleportButton.text = "(T)eleport";
			teleportButton.OnActuated.Add(new => viewerState.Teleport);
			teleportButton.Enabled = false;

			recordButton = new .();

			recordButton.Anchor = .(0,1,0,0);
			recordButton.Offset = .(0, 0, 3 * WindowApp.font.height, 16 + 3 * WindowApp.font.height);
			recordButton.text = "(R)ecord";
			recordButton.OnActuated.Add(new => viewerState.RecordReplay);

			GUIElement.PopParent();
			GUIElement.PopParent();
			GUIElement.PopParent();
		}

		protected override void Update() {
			showing = !Translator.dragged && pinMenuButton.value || ((showing && WindowApp.mousePosition.x < 200 || WindowApp.mousePosition.x < 10) && WindowApp.mousePosition.y < 180);
			motionInterp = Math.MoveTo(motionInterp, showing ? 1 : 0, 0.1f);
			Offset = .(.(-200 * (1 - motionInterp), 0), .(200,180));
		}

		void OnRenderModeSelect(Terrain.RenderMode renderMode) {
			switch (renderMode) {
				case .Collision:
					nearTerrainToggleGroup.visible = false;
					collisionOptionGroup.visible = true;

				case .Far:
					nearTerrainToggleGroup.visible = false;
					collisionOptionGroup.visible = false;

				case .NearLQ, .NearHQ:
					nearTerrainToggleGroup.visible = true;
					collisionOptionGroup.visible = false;
			}
		}
	}
}
