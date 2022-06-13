using System;

namespace SpyroScope {
	class Text : GUIElement {
		String text = new .() ~ delete _;
		public StringView Text {
			get => text;
			set => text.Set(value);
		}
		public Font font = WindowApp.fontSmall;
		public Color4 color = .(255,255,255);

		public override void Draw() {
			font.Print(text, drawn.start, color);

			base.Draw();
		}
	}
}
