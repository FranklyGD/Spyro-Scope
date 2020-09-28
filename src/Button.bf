using System;
namespace SpyroScope {
	class Button : GUIElement {
		public Renderer.Color normal = .(255, 255, 255);
		public Renderer.Color hovered = .(255, 255, 128);
		public Renderer.Color pressed = .(255, 255, 255);
		public Renderer.Color disabled = .(128, 128, 128);

		public Texture normalTexture = Renderer.whiteTexture;
		public Texture pressedTexture = Renderer.whiteTexture;

		public Texture iconTexture;
		public String text;

		public bool enabled = true;
		public Event<delegate void()> OnPressed ~ _.Dispose();

		public override void Draw(Rect parentRect) {
			base.Draw(parentRect);

			Renderer.Color color = disabled;
			Texture texture = pressedTexture;
			if (enabled) {
				color = normal;
				texture = normalTexture;
				if (GUIElement.hoveredElement == this || GUIElement.preselectedElement == this) {
					color = hovered;
					if (GUIElement.hoveredElement == GUIElement.preselectedElement) {
						color = pressed;
						texture = pressedTexture;
					}
				}
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
				WindowApp.fontSmall.Print(text, .(hcenter - halfWidth, vcenter - halfHeight, 0), .(0,0,0));
			}
		}

		public override void Pressed() {
			if (enabled) {
				OnPressed();
			}
		}
	}
}
