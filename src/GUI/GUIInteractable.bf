namespace SpyroScope {
	abstract class GUIInteractable : GUIElement {
		public enum State {
			Normal,
			Hovered,
			Pressed,
			Disabled
		}
		public State state;

		public Color normalColor = .(255, 255, 255);
		public Color hoveredColor = .(255, 255, 128);
		public Color pressedColor = .(255, 255, 255);
		public Color disabledColor = .(128, 128, 128);

		public Texture normalTexture;
		public Texture pressedTexture;

		public bool Selected { get => selectedElement == this; }

		bool enabled = true;
		public bool Enabled {
			get => enabled;
			set  {
				enabled = value;
				if (enabled) {
					OnEnabled();
				} else {
					OnDisabled();
				}
			}
		}

		protected virtual void OnEnabled() {
			if (Hovered) {
				state = .Hovered;
			} else {
				state = .Normal;
			}
		}

		protected virtual void OnDisabled() {
			state = .Disabled;
		}

		protected override void Pressed() {
			if (enabled) {
				state = .Pressed;
			}
		}

		protected override void Unpressed() {
			if (enabled) {
				if (Hovered) {
					state = .Hovered;
				} else {
					state = .Normal;
				}
			}
		}

		protected override void Selected() {
			if (enabled && !Pressed) {
				state = .Hovered;
			}
		}

		protected override void Unselected() {
			if (enabled) {
				if (Hovered) {
					state = .Hovered;
				} else {
					state = .Normal;
				}
			}
		}

		protected override void MouseEnter() {
			if (enabled) {
				if (Pressed) {
					state = .Pressed;
				} else {
					state = .Hovered;
				}
			}
		}

		protected override void MouseExit() {
			if (enabled) {
				if (Hovered) {
					state = .Hovered;
				} else {
					state = .Normal;
				}
			}
		}
	}
}
