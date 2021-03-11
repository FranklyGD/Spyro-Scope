using SDL2;
using System;

namespace SpyroScope {
	class Input : GUIElement {
		public static int cursor, selectBegin;
		public static bool dragging, underlyingChanged;
		
		public Renderer.Color normalColor = .(255, 255, 255);
		public Renderer.Color activeColor = .(255, 255, 128);
		public Renderer.Color disabledColor = .(128, 128, 128);

		public Texture normalTexture = normalInputTexture;
		public Texture activeTexture = activeInputTexture;

		String lastValidText = new .() ~ delete _;
		public String text = new .() ~ delete _;
		public StringView preText;
		public StringView postText;
		Vector2 textStart;
		
		public bool enabled = true;
		public bool displayUnderlying = true;
		public Event<delegate void(StringView text)> OnSubmit ~ _.Dispose();
		public Event<delegate void(StringView text)> OnChanged ~ _.Dispose();
		public delegate bool(String text) OnValidate ~ delete _;

		public override void Draw() {
			base.Draw();

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

			textStart = .(Math.Round(drawn.left) + 4, vcenter - halfHeight);
			textStart = WindowApp.fontSmall.Print(preText, textStart, .(0,0,0,128));

			Vector2 postTextStart;
			var cursorPos = 0f;
			if (text != null && !text.IsEmpty) {
				if (selectedElement == this) {
					cursorPos = WindowApp.fontSmall.CalculateWidth(.(text,0,cursor));

					if (SelectionExists()) {
						var selectBeginPos = WindowApp.fontSmall.CalculateWidth(.(text,0,selectBegin));
	
						float left, right;
						if (cursor > selectBegin) {
							left = selectBeginPos;
							right = cursorPos;
						} else {
							left = cursorPos;
							right = selectBeginPos;
						}

						left += textStart.x;
						right += textStart.x;

						DrawUtilities.Rect(textStart.y, vcenter + halfHeight, left, right, .(56,154,232,192));
					}
				}
				
				postTextStart = WindowApp.fontSmall.Print(text, textStart, .(0,0,0));
			} else {
				postTextStart = WindowApp.fontSmall.Print(lastValidText, textStart, .(0,0,0, 128));
			}

			WindowApp.fontSmall.Print(postText, postTextStart, .(0,0,0,128));

			if (selectedElement == this) {
				cursorPos += textStart.x;
				Renderer.DrawLine(.(cursorPos, vcenter - halfHeight, 0), .(cursorPos, vcenter + halfHeight, 0), .(0,0,0), .(0,0,0));

				if (text != null && !text.IsEmpty && displayUnderlying && underlyingChanged && lastValidText != null && !lastValidText.IsEmpty) {
					let validDisplayText = scope String() .. AppendF("= {}", lastValidText);

					let textWidth = WindowApp.fontSmall.CalculateWidth(validDisplayText);
					DrawUtilities.Rect(drawn.top - WindowApp.fontSmall.height - 4, drawn.top, drawn.left, drawn.left + textWidth + 8, .(255,255,255));
					WindowApp.fontSmall.Print(validDisplayText, .(textStart.x, drawn.top - WindowApp.fontSmall.height - 2), .(0,0,0));
				}
			}
		}

		public bool Input(SDL.Event event) {
			var event;

			switch (event.type) {
				case .KeyDown:
					if (enabled && event.key.keysym.sym == .BACKSPACE && text.Length > 0) {
						if (SelectionExists()) {
							let left = GetLeft();
							text.Remove(left, GetRight() - left);
							cursor = left;
						} else if (cursor > 0) {
							text.Remove(cursor--, 1);
						}
						selectBegin = cursor;
						CheckText();
					}
				
					if (event.key.keysym.mod & .CTRL > 0) {
						if (event.key.keysym.sym == .A) {
							SelectAll();
						}

						if (event.key.keysym.sym == .C) {
							Copy();
						}

						if (enabled) {
							// Cut
							if (event.key.keysym.sym == .X) {
								if (SelectionExists()) {
									SDL.SetClipboardText(scope String(GetSelectionText()));
									
									let left = GetLeft();
									text.Remove(left, GetRight() - left);
									cursor = left;
								} else {
									SDL.SetClipboardText(text);
	
									text.Set("");
									cursor = 0;
								}
								selectBegin = cursor;
							}
	
							// Paste
							if (event.key.keysym.sym == .V) {
								if (SelectionExists()) {
									let left = GetLeft();
									let right = GetRight();
	
									text.Remove(left, right - left);
									cursor = left;
								}

								// Remove special spacing character since this is only one line text
								let clipboard = scope String(SDL.GetClipboardText()) .. Replace("\t", "") .. Replace("\n", "");
								text.Insert(cursor, clipboard);
								cursor += clipboard.Length;
								selectBegin = cursor;
								CheckText();
							}
						}
					}

					if (event.key.keysym.sym == .LEFT) {
						if (SelectionExists() && event.key.keysym.mod & .SHIFT == 0) {
							cursor = GetLeft();
						} else if (--cursor < 0) {
							cursor = 0;
						}

						if (event.key.keysym.mod & .SHIFT == 0) {
							selectBegin = cursor;
						}
					}

					if (event.key.keysym.sym == .RIGHT) {
						if (SelectionExists() && event.key.keysym.mod & .SHIFT == 0) {
							cursor = GetRight();
						} else if (++cursor > text.Length) {
							cursor = text.Length;
						}

						if (event.key.keysym.mod & .SHIFT == 0) {
							selectBegin = cursor;
						}
					}

					if (event.key.keysym.sym == .RETURN) {
						selectedElement = null;
						text.Set(lastValidText);
						OnSubmit(text);
					}
	
				// All key inputs will be consumed while a text input is selected
				return true;

				case .TextInput:
					if (enabled) {
						if (SelectionExists()) {
							let left = GetLeft();
							text.Remove(left, GetRight() - left);
							cursor = left;
						}
						text.Insert(cursor, .((char8*)&event.text.text[0]));
						selectBegin = ++cursor;
						CheckText();
					}
					return true;

				case .MouseMotion:
					if (dragging) {
						cursor = WindowApp.fontSmall.NearestTextIndex(text, WindowApp.mousePosition.x - textStart.x);
					}

				default:
			}

			return false;
		}

		protected override void MouseEnter() {
			SDL.SetCursor(Ibeam);
		}

		protected override void MouseExit() {
			SDL.SetCursor(arrow);
		}

		protected override void Pressed() {
			selectBegin = cursor = WindowApp.fontSmall.NearestTextIndex(text, WindowApp.mousePosition.x - (drawn.left + 4));
			dragging = true;
		}

		protected override void Unpressed() {
			dragging = false;
		}

		protected override void Selected() {
			underlyingChanged = false;
		}

		void CheckText() {
			if (OnValidate == null) {
				lastValidText.Set(text);
				OnChanged(lastValidText);
			} else {
				let buffer = scope String(text);
				if (OnValidate(buffer)) {
					lastValidText.Set(buffer);
					OnChanged(lastValidText);
				}
			}

			if (displayUnderlying) {
				underlyingChanged = lastValidText != text;
			}
		}

		public void SetValidText(StringView validText) {
			if (selectedElement != this) {
				text.Set(validText);
			}
			lastValidText.Set(validText);
		}

		[Inline]
		int GetLeft() {
			return Math.Min(cursor, selectBegin);
		}
		
		[Inline]
		int GetRight() {
			return Math.Max(cursor, selectBegin);
		}

		[Inline]
		bool SelectionExists() {
			return cursor != selectBegin;
		}

		[Inline]
		StringView GetSelectionText() {
			return .(text, GetLeft(), Math.Abs(cursor - selectBegin));
		}

		public void SelectAll() {
			selectBegin = 0;
			cursor = text.Length;
		}

		public void Copy() {
			if (SelectionExists()) {
				SDL.SetClipboardText(scope String(GetSelectionText()));
			} else {
				SDL.SetClipboardText(text);
			}
		}
	}
}
