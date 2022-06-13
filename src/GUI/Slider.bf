using System;

namespace SpyroScope {
	class Slider : GUIInteractable {
		float value;
		public float Value {
			get => value;
			set {
				let workingRange = 1 - portion;
				let normalizedValue = (value - min) / (max - min);

				let newAnchor = normalizedValue * workingRange;

				if (direction == .Horizontal) {
					Anchor = .(newAnchor, newAnchor + portion, 0, 1);
				} else {
					Anchor = .(0, 1, newAnchor, newAnchor + portion);
				}

				this.value = value;
			}
		}

		public enum Direction {
			Horizontal,
			Vertical,
		}
		public Direction direction;
		public float portion, min, max = 1;

		public bool round;

		static float storedDelta;

		public Event<delegate void(float value)> OnChanged ~ _.Dispose();

		public this() {
			normalTexture = normalButtonTexture;
			pressedTexture = pressedButtonTexture;
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
		}

		protected override void Pressed() {
			storedDelta = 0;
		}

		protected override void Dragged(Vector2 mouseDelta) {
			let workingRange = 1 - portion;

			storedDelta += mouseDelta.x / (direction == .Horizontal ? parent.drawn.Width : parent.drawn.Height);

			if (!Enabled) {
				return;
			}

			float delta = 0;
			if (round) {
				let incrementDelta = workingRange / Math.Round(max);
				if (Math.Abs(storedDelta) > incrementDelta / 2) {
					delta = incrementDelta * Math.Sign(storedDelta);
				}
			} else {
				delta = storedDelta;
			}

			if (delta != 0) {
				let oldAnchor = direction == .Horizontal ? Anchor.left : Anchor.top;
				let newAnchor = Math.Clamp(oldAnchor + delta, 0, workingRange);

				if (direction == .Horizontal) {
					Anchor = .(newAnchor, newAnchor + portion, 0, 1);
				} else {
					Anchor = .(0, 1, newAnchor, newAnchor + portion);
				}

				let normalizedValue = newAnchor / workingRange;
				value = Math.Lerp(min, max, normalizedValue);

				if (round) {
					value = Math.Round(value);
				}

				OnChanged(value);
				storedDelta -= newAnchor - oldAnchor;
			}
		}
	}
}
