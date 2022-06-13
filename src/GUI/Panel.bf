namespace SpyroScope {
	class Panel : GUIElement {
		public Color4 tint = .(255,255,255);
		public Texture texture = Renderer.whiteTexture;

		public override void Draw() {
			DrawUtilities.SlicedRect(drawn.bottom, drawn.top, drawn.left, drawn.right, 0,1,0,1, 0.3f,0.7f,0.3f,0.7f, texture, tint);

			base.Draw();
		}
	}
}
