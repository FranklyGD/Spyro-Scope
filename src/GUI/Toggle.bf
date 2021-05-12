namespace SpyroScope {
	class Toggle : Button {
		public bool value;

		public Texture toggleIconTexture;

		protected override void Unpressed() {
			if (Hovered && Enabled) {
				SetValue(!value);
			}

			base.Unpressed();
		}

		public void Toggle() {
			SetValue(!value);
			OnActuated();
		}

		public void SetValue(bool value) {
			iconTexture = value ? toggleIconTexture : null;
			this.value = value;
		}
	}
}
