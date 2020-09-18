namespace SpyroScope {
	class Toggle : Button {
		public bool toggled;

		public Texture toggleTexture;

		public override void Pressed() {
			if (enabled) {
				toggled = !toggled;
				iconTexture = toggled ? toggleTexture : null;
				OnPressed();
			}
		}
	}
}
