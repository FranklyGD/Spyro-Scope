using System;

namespace SpyroScope {
	class Toggle : GUIInteractable {
		public bool value;
		
		public Texture toggleIconTexture;
		
		public Event<delegate void(bool)> OnToggled ~ _.Dispose();

		public this() : base() {
			normalTexture = normalButtonTexture;
			pressedTexture = pressedButtonTexture;
			toggleIconTexture = toggledTexture;
		}

		public override void Draw() {
			base.Draw();
			
			Color color;
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

			if (value) {
				let hcenter = (drawn.left + drawn.right) / 2;
				let vcenter = (drawn.top + drawn.bottom) / 2;
				let halfWidth = toggleIconTexture.width / 2;
				let halfHeight = toggleIconTexture.height / 2;
				DrawUtilities.Rect(vcenter - halfHeight, vcenter + halfWidth, hcenter - halfHeight, hcenter + halfHeight, 0,1,0,1, toggleIconTexture, .(255,255,255));
			}
		}

		protected override void Unpressed() {
			if (Hovered && Enabled) {
				Toggle();
			}

			base.Unpressed();
		}

		public void Toggle() {
			value = !value;
			OnToggled(value);
		}
	}
}
