namespace SpyroScope {
	class Toggle : Button {
		public bool value;

		public Texture toggleIconTexture;

		public override void Pressed() {
			if (enabled) {
				value = !value;
				iconTexture = value ? toggleIconTexture : null;
				OnActuated();
			}
		}
	}
}
