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

		int subDragged;

		public this() {
			PushParent(this);

			replayButton = new .();
			
			replayButton.Anchor = .(0.5f, 0.5f, 0, 0);
			replayButton.Offset = .(-16, 16, -8, 8);
			replayButton.Offset.Shift(-16, 10);
			replayButton.iconTexture = playTexture;
			replayButton.OnActuated.Add(new => ToggleReplay);

			stopReplayButton = new .();
			
			stopReplayButton.Anchor = .(0.5f, 0.5f, 0, 0);
			stopReplayButton.Offset = .(-16, 16, -8, 8);
			stopReplayButton.Offset.Shift(16, 10);
			stopReplayButton.text = "Stop";
			stopReplayButton.OnActuated.Add(new () => {
				stopReplayButton.Enabled = false;
				Recording.StopReplay();
			});
			stopReplayButton.Enabled = false;

			Button clearButton = new .();
			
			clearButton.Anchor = .(0.5f, 0.5f, 0, 0);
			clearButton.Offset = .(-25, 25, -8, 8);
			clearButton.Offset.Shift(0, 26);
			clearButton.text = "Clear";
			clearButton.OnActuated.Add(new () => {
				Recording.ClearRecord();
				if (!Recording.Active) {
					visible = false;
					Recording.StopReplay();
				}
			});

			clearButton = new .();

			clearButton.Anchor = .(0.5f, 0.5f, 0, 0);
			clearButton.Offset = .(-10, 10, -8, 8);
			clearButton.Offset.Shift(-35, 26);
			clearButton.text = "<";
			clearButton.OnActuated.Add(new () => {
				Recording.TrimRecordBefore(Recording.CurrentFrame);
			});

			clearButton = new .();

			clearButton.Anchor = .(0.5f, 0.5f, 0, 0);
			clearButton.Offset = .(-10, 10, -8, 8);
			clearButton.Offset.Shift(35, 26);
			clearButton.text = ">";
			clearButton.OnActuated.Add(new () => {
				Recording.TrimRecordAfter(Recording.CurrentFrame);
			});

			PopParent();
		}

		protected override void Update() {
			replayButton.Enabled = !Recording.Active;
			replayButton.iconTexture = Recording.Playing ? pauseTexture : playTexture;
		}

		public override void Draw() {
			DrawUtilities.Rect(drawn.top, drawn.bottom, drawn.left, drawn.right, .(0,0,0,128));

			let halfWidth = drawn.Width / 2;
			let frameCaps = (int)(halfWidth / 3) - 3;

			let start = Math.Max(0, Recording.CurrentFrame - frameCaps);
			let end = Math.Min(Recording.FrameCount, Recording.CurrentFrame + frameCaps);
			var offset = start - Recording.CurrentFrame;

			let hcenter = (drawn.left + drawn.right) / 2;

			for (var i = start; i < end; i++) {
				let previousFrameIndex = i-1;
				Recording.SpyroFrame prevFrame = ?;
				if (previousFrameIndex > -1) {
					prevFrame = Recording.GetFrame(previousFrameIndex);
				} else {
					prevFrame.state = 0;
					prevFrame.input = 0;
				}

				let frame = Recording.GetFrame(i);

				var color = Renderer.Color(0,0,0);
				let speed = frame.targetVelocity.Length();
				if (speed > 0) {
					let speedScale = speed / Recording.HighestSpeed;
					color = .((.)(255 * (1 - speedScale)), (.)(255 * speedScale), 0);
				}

				let leftFrame = hcenter - 1.5f + offset * 3;
				let rightFrame = hcenter + 1.5f + offset * 3;

				DrawUtilities.Rect(drawn.bottom - (i == Recording.CurrentFrame ? 16 : 8), drawn.bottom - 4, leftFrame, rightFrame, color);

				if (frame.input & 0x10 > 0) {
					if (prevFrame.input & 0x10 == 0) {
						DrawUtilities.Rect(drawn.bottom - 32, drawn.bottom - 8, leftFrame, leftFrame + 24, 0,1,0,1, triangleButtonTexture, .(255,255,255));
					}
					Renderer.DrawLine(.(leftFrame, drawn.bottom - 13,0), .(rightFrame, drawn.bottom - 13,0), .(73,218,124), .(73,218,124));
				}
				if (frame.input & 0x20 > 0) {
					if (prevFrame.input & 0x20 == 0) {
						DrawUtilities.Rect(drawn.bottom - 32, drawn.bottom - 8, leftFrame, leftFrame + 24, 0,1,0,1, circleButtonTexture, .(255,255,255));
					}
					Renderer.DrawLine(.(leftFrame, drawn.bottom - 12,0), .(rightFrame, drawn.bottom - 12,0), .(226,55,55), .(226,55,55));
				}
				if (frame.input & 0x40 > 0) {
					if (prevFrame.input & 0x40 == 0) {
						DrawUtilities.Rect(drawn.bottom - 32, drawn.bottom - 8, leftFrame, leftFrame + 24, 0,1,0,1, crossButtonTexture, .(255,255,255));
					}
					Renderer.DrawLine(.(leftFrame, drawn.bottom - 11,0), .(rightFrame, drawn.bottom - 11,0), .(126,171,226), .(126,171,226));
				}
				if (frame.input & 0x80 > 0) {
					if (prevFrame.input & 0x80 == 0) {
						DrawUtilities.Rect(drawn.bottom - 32, drawn.bottom - 8, leftFrame, leftFrame + 24, 0,1,0,1, squareButtonTexture, .(255,255,255));
					}
					Renderer.DrawLine(.(leftFrame, drawn.bottom - 10,0), .(rightFrame, drawn.bottom - 10,0), .(208,142,210), .(208,142,210));
				}

				// Every second (30 frames)
				if (i % 30 == 0) {
					Renderer.DrawLine(.((int)hcenter + offset * 3,drawn.bottom,0), .((int)hcenter + offset * 3,drawn.bottom - 16,0), .(255,255,255), .(255,255,255));
					WindowApp.fontSmall.Print(scope String() .. AppendF("{}s", i/30), .((int)hcenter + offset * 3, drawn.bottom - 16 - WindowApp.fontSmall.height), .(255,255,255));
				}
				offset++;
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
