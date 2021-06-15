using System;
namespace SpyroScope {
	class Button : GUIInteractable {
		public Texture iconTexture;
		public String text ~ if (_ != null && _.IsDynAlloc) delete _;

		public Event<delegate void()> OnActuated ~ _.Dispose();

		public this() : base() {
			normalTexture = normalButtonTexture;
			pressedTexture = pressedButtonTexture;
		}

		public override void Draw() {
			base.Draw();

			Renderer.Color color;
			Texture texture;

			switch (state) {
				case .Normal: color = normalColor; texture = normalTexture;
				case .Hovered: color = hoveredColor; texture = normalTexture;
				case .Pressed: color = pressedColor; texture = pressedTexture;
				case .Disabled: color = disabledColor; texture = normalTexture;
			}

			if (texture != null) {
				DrawUtilities.SlicedRect(drawn.bottom, drawn.top, drawn.left, drawn.right, 0,1,0,1, 0.3f,0.7f,0.3f,0.7f, texture, color);
			}

			if (iconTexture != null) {
				let hcenter = (drawn.left + drawn.right) / 2;
				let vcenter = (drawn.top + drawn.bottom) / 2;
				let halfWidth = iconTexture.width / 2;
				let halfHeight = iconTexture.height / 2;
				DrawUtilities.Rect(vcenter - halfHeight, vcenter + halfWidth, hcenter - halfHeight, hcenter + halfHeight, 0,1,0,1, iconTexture, .(255,255,255));
			}

			if (text != null && !text.IsEmpty) {
				let hcenter = (drawn.left + drawn.right) / 2;
				let vcenter = (drawn.top + drawn.bottom) / 2;
				let textWidth = WindowApp.fontSmall.CalculateWidth(text);
				let halfWidth = Math.Floor(textWidth / 2);
				let halfHeight = Math.Floor(WindowApp.fontSmall.height / 2);
				WindowApp.fontSmall.Print(text, .(hcenter - halfWidth, vcenter - halfHeight), .(0,0,0));
			}
		}

		protected override void Unpressed() {
			base.Unpressed();

			if (Hovered && Enabled) {
				OnActuated();
			}
		}
	}
}
