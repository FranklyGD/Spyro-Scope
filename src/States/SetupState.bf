using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class SetupState : WindowState {
		Stopwatch stopwatch = new .() ~ delete _;

		public override void Enter() {
			Renderer.clearColor = .(0,0,0);
			stopwatch.Start();
		}
		
		public override void Exit() {
			stopwatch.Reset();
		}

		public override void Update() {
			if (!(Emulator.active == null || Emulator.active.rom == .None)) {
				if (stopwatch.ElapsedMilliseconds > 3000) {
					windowApp.GoToState<ViewerState>();
				}
			} else if (stopwatch.ElapsedMilliseconds > 1000) {
				if (Emulator.active == null) {
					let processes = new List<Process>();
					Emulator.FindEmulatorProcesses(processes);
					DeleteContainerAndItems!(processes);
				} else {
					Emulator.active.CheckEmulatorStatus();
					if (Emulator.active.emulator != .None) {
						Emulator.active.FindGame();
					}
				}
				
				stopwatch.Restart();
			}
		}

		public override void DrawGUI() {
			let middleWindow = WindowApp.width / 2;

			String message = .Empty;
			if (Emulator.active == null) {
				message = "Waiting for Emulator";
			} else {
				if (Emulator.active.rom == .None) {
					message = "Waiting for Game";
				} else {
					message = Emulator.gameNames[(int)Emulator.active.rom];
				}
				
				let baseline = WindowApp.height / 2 - WindowApp.font.height * 1.5f;
				let emulator = Emulator.emulatorNames[(int)Emulator.active.emulator];
				let halfWidth = Math.Round(WindowApp.font.CalculateWidth(emulator) / 2);
				WindowApp.font.Print(emulator, .(middleWindow - halfWidth, baseline), .(255,255,255));
			}

			var baseline = (WindowApp.height - WindowApp.font.height) / 2;
			let halfWidth = Math.Round(WindowApp.font.CalculateWidth(message) / 2);
			WindowApp.font.Print(message, .(middleWindow - halfWidth, baseline), .(255,255,255));

			baseline += WindowApp.font.penLine;
			if (Emulator.active == null || Emulator.active.rom == .None) {
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
