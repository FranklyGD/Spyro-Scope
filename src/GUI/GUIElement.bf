using SDL2;
using System.Collections;

namespace SpyroScope {
	class GUIElement {
		public static SDL.SDL_Cursor* arrow;
		public static SDL.SDL_Cursor* Ibeam;
		public static SDL.SDL_Cursor* Harrows;
		public static SDL.SDL_Cursor* Varrows;

		static bool ignoreMotion;

		public static bool debug;

		private Rect anchor;
		public ref Rect Anchor {
			get => ref anchor;
			set {
				if (anchor == value) return;
				anchor = value;
				Resize();
			}
		}

		private Rect offset;
		public ref Rect Offset {
			get => ref offset;
			set {
				if (offset == value) return;
				offset = value;
				Resize();
			}
		}

		public Rect drawn;

		public bool visible = true;

		public GUIElement parent;
		public List<GUIElement> children = new .();

		static List<GUIElement> parentStack = new .() ~ delete _;
		static List<GUIElement> activeGUI;

		public static GUIElement hoveredElement;
		public static GUIElement pressedElement;
		public static GUIElement selectedElement;

		public static Texture normalButtonTexture ~ delete _; 
		public static Texture pressedButtonTexture ~ delete _;
		public static Texture normalInputTexture ~ delete _; 
		public static Texture activeInputTexture ~ delete _;

		public bool Hovered { get => hoveredElement == this; }
		public bool Pressed { get => pressedElement == this; }

		public static void Init() {
			arrow = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_ARROW);
			Ibeam = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_IBEAM);
			Harrows = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_SIZEWE);
			Varrows = SDL.CreateSystemCursor(.SDL_SYSTEM_CURSOR_SIZENS);

			normalButtonTexture = new .("images/ui/button_normal.png");
			pressedButtonTexture = new .("images/ui/button_pressed.png");
			normalInputTexture = new .("images/ui/input_normal.png"); 
			activeInputTexture = new .("images/ui/input_active.png");
		}

		public static void SetActiveGUI(List<GUIElement> GUI) {
			activeGUI = GUI;

			if (activeGUI != null) {
				for (let element in activeGUI) {
					element.Resize();
				}
			}
		}

		public static void PushParent(GUIElement parent) {
			parentStack.Add(parent);
		}

		public static void PopParent() {
			parentStack.PopBack();
		}

		public static void GUIUpdate() {
			if (activeGUI == null) {
				return;
			}

			for (let element in activeGUI) {
				element.UpdateInternal();
			}
		}

		public static bool GUIEvent(SDL.Event event) {
			if (activeGUI == null) {
				return false;
			}

			let input = selectedElement as Input;
			if (input != null && input.Input(event)) {
				return true;
			}

			switch (event.type) {
				case .WindowEvent: 
					if (event.window.windowEvent == .Resized) {
						for (let element in activeGUI) {
							element.Resize();
						}
					}
					return false;

				case .MouseMotion: return !ignoreMotion && GUIMouseUpdate(.(event.motion.xrel, event.motion.yrel));
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
				if (hoveredElement is GUIInteractable) {
					hoveredElement?.Selected();
				}
				selectedElement = hoveredElement;
			}

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

		static bool GUIMouseUpdate(Vector2 mouseDelta) {
			let lastHoveredElement = hoveredElement;
			hoveredElement = null;

			pressedElement?.Dragged(mouseDelta);

			for (let element in activeGUI) {
				element.MouseUpdate();
			}

			if (lastHoveredElement != hoveredElement) {
				lastHoveredElement?.MouseExit();
				hoveredElement?.MouseEnter();
			}

			return hoveredElement != null;
		}

		public this() {
			parent = parentStack.Count > 0 ? parentStack[parentStack.Count - 1] : null;
			if (parent != null) {
				parent.children.Add(this);
			} else {
				activeGUI.Add(this);
			}
		}

		public ~this() {
			if (hoveredElement == this) {
				hoveredElement.MouseExit();
				hoveredElement = null;
			}

			if (pressedElement == this) {
				pressedElement = null;
			}

			if (selectedElement == this) {
				selectedElement.Unselected();
				selectedElement = null;
			}

			DeleteContainerAndItems!(children);
		}

		public virtual void Draw() {
			for (let child in children) {
				child.Draw();
			}

			if (!debug) {
				return;
			}

			Renderer.Color debugColor = Hovered ? .(128,128,16) : .(16,16,16);

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

		void UpdateInternal() {
			Update();
			for (let child in children) {
				child.UpdateInternal();
			}
		}

		protected virtual void Update() {}
		protected virtual void Pressed() {}
		protected virtual void Dragged(Vector2 mouseDelta) {}
		protected virtual void Unpressed() {}
		protected virtual void Selected() {}
		protected virtual void Unselected() {}
		protected virtual void MouseEnter() {}
		protected virtual void MouseExit() {}

		void Resize() {
			let parentRect = parent == null ? Rect(0, WindowApp.width, 0, WindowApp.height): parent.drawn;
			CalculateDrawingRect(parentRect);

			for (let child in children) {
				child.Resize();
			}
		}

		public void MouseUpdate() {
			if (visible &&
				WindowApp.mousePosition.x > drawn.left &&
				WindowApp.mousePosition.x < drawn.right &&
				WindowApp.mousePosition.y > drawn.top &&
				WindowApp.mousePosition.y < drawn.bottom) {

				hoveredElement = this;

				for (let child in children) {
					child.MouseUpdate();
				}
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
