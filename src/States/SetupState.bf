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

		public override void DrawGUI() {
			let middleWindow = WindowApp.width / 2;

			String message = .Empty;
			if (Emulator.emulator == .None) {
				message = "Waiting for Emulator";
			} else {
				if (Emulator.rom == .None) {
					message = "Waiting for Game";
				} else {
					message = Emulator.gameNames[(int)Emulator.rom];
				}
				
				let baseline = WindowApp.height / 2 - WindowApp.font.height * 1.5f;
				let emulator = Emulator.emulatorNames[(int)Emulator.emulator];
				let halfWidth = WindowApp.font.CalculateWidth(emulator) / 2;
				WindowApp.font.Print(emulator, .(middleWindow - halfWidth, baseline, 0), .(255,255,255));
			}

			var baseline = (WindowApp.height - WindowApp.font.height) / 2;
			let halfWidth = WindowApp.font.CalculateWidth(message) / 2;
			WindowApp.font.Print(message, .(middleWindow - halfWidth, baseline, 0), .(255,255,255));

			baseline += WindowApp.font.penLine;
			if (Emulator.emulator == .None || Emulator.rom == .None) {
				let t = (float)stopwatch.ElapsedMilliseconds / 1000 * 3.14f;
				DrawUtilities.Rect(baseline + 2, baseline + 4, middleWindow - halfWidth * Math.Sin(t), middleWindow + halfWidth * Math.Sin(t),
					.(255,255,255));
			} else {
				let t = 1f - (float)stopwatch.ElapsedMilliseconds / 3000;
				DrawUtilities.Rect(baseline + 2, baseline + 4, middleWindow - halfWidth * t, middleWindow + halfWidth * t,
					.(255,255,255));
			}
		}
	}
}
