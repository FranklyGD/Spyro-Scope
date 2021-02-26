using System;
namespace SpyroScope {
	class Button : GUIElement {
		public Renderer.Color normalColor = .(255, 255, 255);
		public Renderer.Color hoveredColor = .(255, 255, 128);
		public Renderer.Color pressedColor = .(255, 255, 255);
		public Renderer.Color disabledColor = .(128, 128, 128);

		public Texture normalTexture = normalButtonTexture;
		public Texture pressedTexture = pressedButtonTexture;

		public Texture iconTexture;
		public String text ~ if (_ != null && _.IsDynAlloc) delete _;

		public bool enabled = true;
		public Event<delegate void()> OnActuated ~ _.Dispose();

		Renderer.Color color = normalColor;
		Texture texture = normalTexture;

		public override void Draw(Rect parentRect) {
			base.Draw(parentRect);

			Renderer.Color color = this.color;
			Texture texture = this.texture;
			if (!enabled) {
				color = disabledColor;
				texture = normalTexture;
			}
			DrawUtilities.SlicedRect(drawn.bottom, drawn.top, drawn.left, drawn.right, 0,1,0,1, 0.3f,0.7f,0.3f,0.7f, texture, color);

			if (iconTexture != null) {
				let hcenter = (drawn.left + drawn.right) / 2;
				let vcenter = (drawn.top + drawn.bottom) / 2;
				let halfWidth = iconTexture.width / 2;
				let halfHeight = iconTexture.height / 2;
				DrawUtilities.Rect(vcenter - halfHeight, vcenter + halfWidth, hcenter - halfHeight, hcenter + halfHeight, 0,1,0,1, iconTexture, color);
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

		protected override void Pressed() {
			color = pressedColor;
			texture = pressedTexture;
		}

		protected override void Unpressed() {
			texture = normalTexture;
			if (hoveredElement == this) {
				color = hoveredColor;
			} else {
				color = normalColor;
			}

			if (hoveredElement == this && enabled) {
				OnActuated();
			}
		}

		protected override void MouseEnter() {
			if (pressedElement == this) {
				color = pressedColor;
				texture = pressedTexture;
			} else {
				color = hoveredColor;
				texture = normalTexture;
			}
		}

		protected override void MouseExit() {
			if (pressedElement == this) {
				color = hoveredColor;
				texture = normalTexture;
			} else {
				color = normalColor;
			}
		}
	}
}
