using SDL2;
using System;

namespace SpyroScope {
	class Input : GUIElement {
		public static int cursor;
		
		public Renderer.Color normalColor = .(255, 255, 255);
		public Renderer.Color activeColor = .(255, 255, 128);
		public Renderer.Color disabledColor = .(128, 128, 128);

		public Texture normalTexture = Renderer.whiteTexture;
		public Texture activeTexture = Renderer.whiteTexture;

		String lastValidText = new .() ~ delete _;
		public String text = new .() ~ delete _;
		public enum InputFormat {
			None,
			Integer,
			Float,
			Hex
		}
		public InputFormat format;
		
		public bool enabled = true;
		public Event<delegate void()> OnSubmit ~ _.Dispose();
		public Event<delegate void()> OnChanged ~ _.Dispose();
		public delegate bool() OnValidate ~ delete _;

		public override void Draw(Rect parentRect) {
			base.Draw(parentRect);

			Renderer.Color color = ?;
			Texture texture = normalTexture;
			if (!enabled) {
				color = disabledColor;
			} else if (selectedElement == this) {
				color = activeColor;
				texture = activeTexture;
			} else {
				color = normalColor;
			}
			DrawUtilities.SlicedRect(drawn.bottom, drawn.top, drawn.left, drawn.right, 0,1,0,1, 0.3f,0.7f,0.3f,0.7f, texture, color);

			let vcenter = (drawn.top + drawn.bottom) / 2;
			let halfHeight = Math.Floor(WindowApp.fontSmall.height / 2);

			let textStartX = drawn.left + 4;
			var cursorPos = 0f;
			if (text != null && !text.IsEmpty) {
				WindowApp.fontSmall.Print(text, .(textStartX, vcenter - halfHeight, 0), .(0,0,0));
				
				cursorPos = WindowApp.fontSmall.CalculateWidth(.(text,0,cursor));
			}

			if (selectedElement == this) {
				cursorPos += textStartX + 1;
				Renderer.DrawLine(.(cursorPos, vcenter - halfHeight, 0), .(cursorPos, vcenter + halfHeight, 0), .(0,0,0), .(0,0,0));
			}
		}

		public bool Input(SDL.Event event) {
			var event;

			switch (event.type) {
				case .KeyDown:
					if (event.key.keysym.sym == .BACKSPACE && text.Length > 0 && cursor > 0) {
						text.Remove(cursor--, 1);
						CheckText();
					}

					if (event.key.keysym.sym == .V) {
						if (event.key.keysym.mod & .CTRL > 0) {
							let clipboard = StringView(SDL.GetClipboardText());
							text.Append(clipboard);
							cursor += clipboard.Length;
							CheckText();
						}
					}

					if (event.key.keysym.sym == .LEFT) {
						if (--cursor < 0) {
							cursor = 0;
						}
					}

					if (event.key.keysym.sym == .RIGHT) {
						if (++cursor > text.Length) {
							cursor = text.Length;
						}
					}

					if (event.key.keysym.sym == .RETURN) {
						selectedElement = null;
						text.Set(lastValidText);
						OnSubmit();
					}
	
				// All key inputs will be consumed while a text input is selected
				return true;

				case .TextInput:
					text.Insert(cursor, .((char8*)&event.text.text[0]));
					cursor++;
					CheckText();
					return true;

				default: return false;
			}
		}

		protected override void MouseEnter() {
			SDL.SetCursor(Ibeam);
		}

		protected override void MouseExit() {
			SDL.SetCursor(arrow);
		}

		void CheckText() {
			if (OnValidate == null || OnValidate.Invoke()) {
				lastValidText.Set(text);
				OnChanged();
			}
		}
	}
}
