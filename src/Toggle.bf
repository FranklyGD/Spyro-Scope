namespace SpyroScope {
	class Toggle : Button {
		public bool value;

		public Texture toggleIconTexture;

		protected override void Unpressed() {
			if (hoveredElement == this && enabled) {
				value = !value;
				iconTexture = value ? toggleIconTexture : null;
			}

			base.Unpressed();
		}

		public void Toggle() {
			value = !value;
			iconTexture = value ? toggleIconTexture : null;
			OnActuated();
		}
	}
}
