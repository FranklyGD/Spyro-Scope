using System;
using System.Diagnostics;

namespace SpyroScope {
	class SetupState : WindowState {
		Stopwatch stopwatch = new .() ~ delete _;

		public override void Enter() {
			stopwatch.Start();
		}
		
		public override void Exit() {
			stopwatch.Reset();
		}

		public override void Update() {
			if (Emulator.rom != .None) {
				if (stopwatch.ElapsedMilliseconds > 3000) {
					windowApp.GoToState!<ViewerState>();
				}
			} else if (stopwatch.ElapsedMilliseconds > 1000) {
				if (Emulator.emulator == .None) {
					Emulator.FindEmulator();
				} else {
					Emulator.CheckEmulatorStatus();
					if (Emulator.emulator != .None) {
						Emulator.FindGame();
					}
				}
				
				stopwatch.Restart();
			}
		}

		public override void DrawGUI(Renderer renderer) {
			String message = .Empty;
			if (Emulator.emulator == .None) {
				message = "Waiting for Emulator";
			} else {
				if (Emulator.rom == .None) {
					message = "Waiting for Game";
				} else {
					message = Emulator.gameNames[(int)Emulator.rom];
				}
				
				let baseline = WindowApp.font.height;
				let emulator = Emulator.emulatorNames[(int)Emulator.emulator];
				let halfWidth = WindowApp.font.CalculateWidth(emulator) / 2;
				WindowApp.font.Print(emulator, .(-halfWidth, baseline, 0), .(255,255,255), renderer);
			}

			let baseline = -WindowApp.font.height / 2;
			let halfWidth = WindowApp.font.CalculateWidth(message) / 2;
			WindowApp.font.Print(message, .(-halfWidth, baseline, 0), .(255,255,255), renderer);

			if (Emulator.emulator == .None || Emulator.rom == .None) {
				let t = (float)stopwatch.ElapsedMilliseconds / 1000 * 3.14f;
				DrawUtilities.Rect(baseline - 4, baseline - 2, -halfWidth * Math.Sin(t), halfWidth * Math.Sin(t),
					0,0,0,0, Renderer.textureDefaultWhite, .(255,255,255), renderer);
			} else {
				let t = 1f - (float)stopwatch.ElapsedMilliseconds / 3000;
				DrawUtilities.Rect(baseline - 4, baseline - 2, -halfWidth * t, halfWidth * t,
					0,0,0,0, Renderer.textureDefaultWhite, .(255,255,255), renderer);
			}
		}
	}
}
