namespace SpyroScope {
	class GUIElement {
		public static bool debug;
		public struct Rect {
			public float left;
			public float right;
			public float bottom;
			public float top;

			public this(float left, float right, float top, float bottom) {
				this.left = left;
				this.right = right;
				this.bottom = bottom;
				this.top = top;
			}

			public void Shift(float x, float y) mut {
				right += x;
				left += x;
				top += y;
				bottom += y;
			}
		}

		public Rect anchor;
		public Rect offset;
		public Rect drawn;

		public bool visible = true;

		public static GUIElement hoveredElement;
		public static GUIElement preselectedElement;

		public virtual void Draw(Rect parentRect) {
			CalculateDrawingRect(parentRect);

			if (!debug) {
				return;
			}

			Renderer.Color debugColor = hoveredElement == this ? .(128,128,16) : .(16,16,16);

			Renderer.DrawLine(
				.(drawn.left, drawn.bottom, 0),
				.(drawn.right, drawn.bottom,0),
				debugColor,
				debugColor
			);

			Renderer.DrawLine(
				.(drawn.left, drawn.top, 0),
				.(drawn.right, drawn.top,0),
				debugColor,
				debugColor
			);

			Renderer.DrawLine(
				.(drawn.left, drawn.top, 0),
				.(drawn.left, drawn.bottom,0),
				debugColor,
				debugColor
			);

			Renderer.DrawLine(
				.(drawn.right, drawn.top, 0),
				.(drawn.right, drawn.bottom,0),
				debugColor,
				debugColor
			);
		}

		public virtual void Update() {}
		public virtual void Pressed() {}

		public void MouseUpdate(Vector mousePosition) {
			if (visible && mousePosition.x > drawn.left && mousePosition.x < drawn.right && mousePosition.y > drawn.top && mousePosition.y < drawn.bottom) {
				hoveredElement = this;
			}
		}

		public void CalculateDrawingRect(Rect parentRect) {
			let width = parentRect.right - parentRect.left;
			let height = parentRect.bottom - parentRect.top;

			let leftAnchor = width * anchor.left;
			let rightAnchor = width * anchor.right;
			let topAnchor = height * anchor.top;
			let bottomAnchor = height * anchor.bottom;

			drawn.left = parentRect.left + leftAnchor + offset.left;
			drawn.right = parentRect.left + rightAnchor + offset.right;
			drawn.top = parentRect.top + topAnchor + offset.top;
			drawn.bottom = parentRect.top + bottomAnchor + offset.bottom;
		}
	}
}
