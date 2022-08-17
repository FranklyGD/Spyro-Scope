using SDL2;
using System;

namespace SpyroScope {
	class Timeline : GUIElement {
		Button replayButton;
		Button stopReplayButton;

		Texture playTexture = new .("images/ui/play.png") ~ delete _; 
		Texture pauseTexture = new .("images/ui/pause.png") ~ delete _;

		Texture squareButtonTexture = new .("images/ui/icon_button_square.png") ~ delete _; 
		Texture triangleButtonTexture = new .("images/ui/icon_button_triangle.png") ~ delete _;
		Texture crossButtonTexture = new .("images/ui/icon_button_cross.png") ~ delete _; 
		Texture circleButtonTexture = new .("images/ui/icon_button_circle.png") ~ delete _;

		int hoveredFrame = -1;
		int subDragged;
		enum DisplayMode {
			Minimal,
			Graph,
		}
		DisplayMode displayMode = .Graph;

		public this() {
			PushParent(this);

			replayButton = new .();
			
			replayButton.Anchor = .(0.5f, 0.5f, 1, 1);
			replayButton.Offset = .(-16, 16, -8, 8);
			replayButton.Offset.Shift(-16, -10);
			replayButton.iconTexture = playTexture;
			replayButton.OnActuated.Add(new => ToggleReplay);

			stopReplayButton = new .();
			
			stopReplayButton.Anchor = .(0.5f, 0.5f, 1, 1);
			stopReplayButton.Offset = .(-16, 16, -8, 8);
			stopReplayButton.Offset.Shift(16, -10);
			stopReplayButton.text = "Stop";
			stopReplayButton.OnActuated.Add(new () => {
				stopReplayButton.Enabled = false;
				Recording.StopReplay();
			});
			stopReplayButton.Enabled = false;

			Button clearButton = new .();
			
			clearButton.Anchor = .(0.5f, 0.5f, 1, 1);
			clearButton.Offset = .(-25, 25, -8, 8);
			clearButton.Offset.Shift(0, -26);
			clearButton.text = "Clear";
			clearButton.OnActuated.Add(new () => {
				Recording.ClearRecord();
				if (!Recording.Active) {
					visible = false;
					Recording.StopReplay();
				}
			});

			clearButton = new .();

			clearButton.Anchor = .(0.5f, 0.5f, 1, 1);
			clearButton.Offset = .(-10, 10, -8, 8);
			clearButton.Offset.Shift(-35, -26);
			clearButton.text = "<";
			clearButton.OnActuated.Add(new () => {
				Recording.TrimRecordBefore(Recording.CurrentFrame);
			});

			clearButton = new .();

			clearButton.Anchor = .(0.5f, 0.5f, 1, 1);
			clearButton.Offset = .(-10, 10, -8, 8);
			clearButton.Offset.Shift(35, -26);
			clearButton.text = ">";
			clearButton.OnActuated.Add(new () => {
				Recording.TrimRecordAfter(Recording.CurrentFrame);
			});

			PopParent();
		}

		protected override void Update() {
			replayButton.Enabled = !Recording.Active;
			replayButton.iconTexture = Recording.Playing ? pauseTexture : playTexture;

			if (hoveredElement == this) {
				let halfWidth = drawn.Width / 2;
				hoveredFrame = (int)Math.Round((WindowApp.mousePosition.x - halfWidth) / 3) + Recording.CurrentFrame;
			}
		}

		public override void Draw() {
			let buttonsHeight = 16;
			DrawUtilities.Rect(drawn.top, drawn.bottom, drawn.left, drawn.right, .(0,0,0,192));

			let halfWidth = drawn.Width / 2;
			let frameCaps = (int)(halfWidth / 3) - 3;

			let start = Math.Max(0, Recording.CurrentFrame - frameCaps);
			let end = Math.Min(Recording.FrameCount, Recording.CurrentFrame + frameCaps);
			var offset = start - Recording.CurrentFrame;

			let hcenter = (drawn.left + drawn.right) / 2;

			
			let windowBottom = drawn.bottom - buttonsHeight * 2;
			let windowHeight = windowBottom - drawn.top;

			// For each frame in the viewed range
			for (var i = start; i < end; i++) {
				let frame = Recording.GetFrame(i);

				let previousFrameIndex = i-1;
				Recording.SpyroFrame prevFrame = ?;
				if (previousFrameIndex > -1) {
					prevFrame = Recording.GetFrame(previousFrameIndex);
				} else {
					prevFrame.state = 0;
					prevFrame.input = 0;
					prevFrame.velocity = frame.velocity;
				}
				
				let leftFrame = hcenter - 1.5f + offset * 3;
				let rightFrame = hcenter + 1.5f + offset * 3;

				switch (displayMode) {
					case .Minimal:
						// Draw frame with color of relative speed to max recorded speed
						var speedColor = Color(0,0,0);
						let speed = frame.targetVelocity.Length();
						if (speed > 0) {
							let speedScale = speed / Recording.HighestSpeed;
							speedColor = .((.)(255 * (1 - speedScale)), (.)(255 * speedScale), 0);
						}
	
						DrawUtilities.Rect(drawn.top + 4, drawn.top + 8, leftFrame, rightFrame, speedColor);

					case .Graph:
						let previousLateralSpeed = Math.Sqrt(prevFrame.velocity.x * prevFrame.velocity.x + prevFrame.velocity.y * prevFrame.velocity.y);
						let lateralSpeed = Math.Sqrt(frame.velocity.x * frame.velocity.x + frame.velocity.y * frame.velocity.y);
						Renderer.Line(
							.(leftFrame, drawn.top + windowHeight - previousLateralSpeed / Recording.HighestSpeed * windowHeight,0),
							.(rightFrame, drawn.top + windowHeight - lateralSpeed / Recording.HighestSpeed * windowHeight,0),
							.(255,0,0), .(255,0,0)
						);
						Renderer.Line(
							.(leftFrame, drawn.top + windowHeight - (prevFrame.velocity.z / Recording.HighestSpeed * 0.5f + 0.5f) * windowHeight,0),
							.(rightFrame, drawn.top + windowHeight - (frame.velocity.z / Recording.HighestSpeed * 0.5f + 0.5f) * windowHeight,0),
							.(0,255,0), .(0,255,0)
						);
				}
				

				// Draw face button icon on pressed
				// and line when it remains held
				if (frame.input & 0x10 > 0) {
					let justPressed = prevFrame.input & 0x10 == 0;
					DrawUtilities.Rect(windowBottom - (justPressed ? 36 : 12), windowBottom - 8, leftFrame, rightFrame, .(73,218,124));
					if (justPressed) {
						DrawUtilities.Rect(windowBottom - 48, windowBottom - 24, leftFrame, leftFrame + 24, 0,1,0,1, triangleButtonTexture, .(255,255,255));
					}
				}
				if (frame.input & 0x20 > 0) {
					let justPressed = prevFrame.input & 0x20 == 0;
					DrawUtilities.Rect(windowBottom -  (justPressed ? 36 : 16), windowBottom - 12, leftFrame, rightFrame, .(226,55,55));
					if (prevFrame.input & 0x20 == 0) {
						DrawUtilities.Rect(windowBottom - 48, windowBottom - 24, leftFrame, leftFrame + 24, 0,1,0,1, circleButtonTexture, .(255,255,255));
					}
				}
				if (frame.input & 0x40 > 0) {
					let justPressed = prevFrame.input & 0x40 == 0;
					DrawUtilities.Rect(windowBottom -  (justPressed ? 36 : 20), windowBottom - 16, leftFrame, rightFrame, .(126,171,226));
					if (prevFrame.input & 0x40 == 0) {
						DrawUtilities.Rect(windowBottom - 48, windowBottom - 24, leftFrame, leftFrame + 24, 0,1,0,1, crossButtonTexture, .(255,255,255));
					}
				}
				if (frame.input & 0x80 > 0) {
					let justPressed = prevFrame.input & 0x80 == 0;
					DrawUtilities.Rect(windowBottom -  (justPressed ? 36 : 24), windowBottom - 20, leftFrame, rightFrame, .(208,142,210));
					if (prevFrame.input & 0x80 == 0) {
						DrawUtilities.Rect(windowBottom - 48, windowBottom - 24, leftFrame, leftFrame + 24, 0,1,0,1, squareButtonTexture, .(255,255,255));
					}
				}


				// Every second (30 frames)
				if (i % 30 == 0) {
					Renderer.Line(.((int)hcenter + offset * 3,windowBottom,0), .((int)hcenter + offset * 3,drawn.top,0), .(255,255,255), .(255,255,255));
					WindowApp.fontSmall.Print(scope $"{i/30}s", .((int)hcenter + offset * 3 + 2, windowBottom - WindowApp.fontSmall.height), .(255,255,255));
				}

				// Draw line on currently previewed frame
				if (i == Recording.CurrentFrame) {
					Renderer.Line(.((int)hcenter + offset * 3,windowBottom,0), .((int)hcenter + offset * 3,drawn.top,0), .(255,255,255), .(255,255,255));
				}

				offset++;
			}

			if (hoveredFrame > -1 && hoveredFrame < Recording.FrameCount) {
				offset = hoveredFrame - Recording.CurrentFrame;
				Renderer.Line(.((int)hcenter + offset * 3,windowBottom,0), .((int)hcenter + offset * 3,drawn.top,0), .(255,255,0), .(255,255,0));

				let frame = Recording.GetFrame(hoveredFrame);

				let lateralSpeed = Math.Sqrt(frame.velocity.x * frame.velocity.x + frame.velocity.y * frame.velocity.y);

				WindowApp.fontSmall.Print(scope $"{lateralSpeed / 1000:0.00} m/s",.((int)hcenter + offset * 3 + 2, drawn.top + (windowHeight - WindowApp.fontSmall.height) - lateralSpeed / Recording.HighestSpeed * (windowHeight - WindowApp.fontSmall.height)), .(255,0,0));
				WindowApp.fontSmall.Print(scope $"{frame.velocity.z / 1000:0.00} m/s",.((int)hcenter + offset * 3 + 2, drawn.top + (windowHeight - WindowApp.fontSmall.height) - (frame.velocity.z / Recording.HighestSpeed * 0.5f + 0.5f) * (windowHeight - WindowApp.fontSmall.height)), .(0,255,0));

			}

			base.Draw();
		}
		
		protected override void Pressed() {

		}

		protected override void Dragged(Vector2 mouseDelta) {
			subDragged -= (int)mouseDelta.x;
			if (subDragged / 3 != 0) {
				Recording.PauseReplay();
				Recording.ApplyFrame(Math.Clamp(Recording.CurrentFrame + subDragged / 3, 0, Recording.FrameCount - 1));

				stopReplayButton.Enabled = true;
			}
			subDragged %= 3;
		}

		protected override void Unpressed() {

		}

		protected override void MouseEnter() {
			SDL.SetCursor(Harrows);
		}

		protected override void MouseExit() {
			SDL.SetCursor(arrow);
			hoveredFrame = -1;
		}

		void ToggleReplay() {
			if (Recording.Playing) {
				Recording.PauseReplay();
			} else {
				Recording.Replay();
				stopReplayButton.Enabled = true;
			}
			
			replayButton.iconTexture = Recording.Playing ? pauseTexture : playTexture;
		}
	}
}
