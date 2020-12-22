using SDL2;
using System.Collections;

namespace SpyroScope {
	class GUIElement {
		public static SDL.SDL_Cursor* arrow;
		public static SDL.SDL_Cursor* Ibeam;

		static bool ignoreMotion;

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

		public GUIElement parent;
		static List<GUIElement> parentStack = new .() ~ delete _;
		static List<GUIElement> activeGUI;

		public static GUIElement hoveredElement;
		public static GUIElement pressedElement;
		public static GUIElement selectedElement;

		public static void Init() {
			arrow = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_ARROW);
			Ibeam = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_IBEAM);
		}

		public static void SetActiveGUI(List<GUIElement> GUI) {
			activeGUI = GUI;
		}

		public static void PushParent(GUIElement parent) {
			parentStack.Add(parent);
		}

		public static void PopParent() {
			parentStack.PopBack();
		}

		public static void GUIUpdate() {
			for (let element in activeGUI) {
				element.Update();
			}
		}

		public static bool GUIEvent(SDL.Event event) {
			let input = selectedElement as Input;
			if (input != null && input.Input(event)) {
				return true;
			}

			switch (event.type) {
				case .MouseMotion: return !ignoreMotion && GUIMouseUpdate(WindowApp.mousePosition);
				case .MouseButtonUp:
					if (GUIMouseRelease(event.button.button)) {
						return true;
					} else {
						ignoreMotion = false;
						return false;
					}
				case .MouseButtonDown:
					if (GUIMousePress(event.button.button)) {
						return true;
					} else {
						ignoreMotion = true;
						return false;
					}
				default: return false;
			}
		}

		static bool GUIMousePress(uint8 button) {
			pressedElement = hoveredElement;
			pressedElement?.Pressed();

			if (selectedElement != hoveredElement) {
				selectedElement?.Unselected();
				hoveredElement?.Selected();
			}
			selectedElement = hoveredElement;

			return hoveredElement != null;
		}

		static bool GUIMouseRelease(uint8 button) {
			if (pressedElement != null) { // Focus was on GUI
				pressedElement.Unpressed();
				pressedElement = null;
				return true;
			}
			return false;
		}

		static bool GUIMouseUpdate((float x, float y) mousePosition) {
			let lastHoveredElement = hoveredElement;
			hoveredElement = null;
			for (let element in activeGUI) {
				element.MouseUpdate(WindowApp.mousePosition);
			}
			if (lastHoveredElement != hoveredElement) {
				lastHoveredElement?.MouseExit();
				hoveredElement?.MouseEnter();
			}
			return hoveredElement != null;
		}

		public this() {
			parent = parentStack.Count > 0 ? parentStack[parentStack.Count - 1] : null;
			activeGUI.Add(this);
		}

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

		protected virtual void Update() {}
		protected virtual void Pressed() {}
		protected virtual void Unpressed() {}
		protected virtual void Selected() {}
		protected virtual void Unselected() {}
		protected virtual void MouseEnter() {}
		protected virtual void MouseExit() {}

		public void MouseUpdate((float x, float y) mousePosition) {
			if (visible &&
				mousePosition.x > drawn.left &&
				mousePosition.x < drawn.right &&
				mousePosition.y > drawn.top &&
				mousePosition.y < drawn.bottom) {

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

		public bool GetVisibility() {
			if (parent != null) {
				return parent.GetVisibility() && visible;
			}
			return visible;
		}
	}
}
