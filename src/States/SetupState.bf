using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class SetupState : WindowState {
		List<GUIElement> guiElements = new .() ~ DeleteContainerAndItems!(_);

		Stopwatch stopwatch = new .() ~ delete _;
		public List<Process> processes = new .() ~ DeleteContainerAndItems!(_);

		public override void Enter() {
			GUIElement.SetActiveGUI(guiElements);

			Renderer.clearColor = .(0,0,0);
			stopwatch.Start();
		}
		
		public override void Exit() {
			stopwatch.Reset();
			
			GUIElement.SetActiveGUI(null);
		}

		public override void Update() {
			if (!(Emulator.active == null || Emulator.active.romChecksum == 0)) {
				if (stopwatch.ElapsedMilliseconds > 3000) {
					windowApp.GoToState<ViewerState>();
				}
			} else if (stopwatch.ElapsedMilliseconds > 1000) {
				if (Emulator.active == null) {
					ClearAndDeleteItems!(processes);
					Emulator.FindProcesses(processes);

					if (processes.Count == 1) {
						// Automatically bind to the process
						Emulator.BindEmulatorProcess(processes[0]);
					} else {
						// List out and let user choose applicable processes
						if (processes.Count > guiElements.Count) {
							for (var i = guiElements.Count; i < processes.Count; i++) {
								Button processButton = new .();
								processButton.Anchor = .(0.5f, 0.5f, 0.5f, 0.5f);
								processButton.Offset = .(-128, 128, (i + 1) * 16, (i + 2) * 16);
								processButton.text = new String();
							}
						} else {
							for (var i = processes.Count; i < guiElements.Count; i++) {
								delete guiElements.PopBack();
							}
						}

						for (let i < processes.Count) {
							let process = processes[i];
							let processButton = (Button)guiElements[i];

							processButton.text.Set(scope String() .. AppendF("{} - PID: {}", process.ProcessName, process.Id));
							processButton.OnActuated .. Dispose() .Add(new () => {
								Emulator.BindEmulatorProcess(processes[i]);
	
								ClearAndDeleteItems!(processes);
								ClearAndDeleteItems!(guiElements);

								stopwatch.Restart();

								CheckEmulator();
							});
						}

						stopwatch.Restart();
					}
				}

				if (Emulator.active != null) {
					CheckEmulator();
				}
				
				stopwatch.Restart();
			}
		}

		public override void DrawGUI() {
			let middleWindow = WindowApp.width / 2;

			Emulator activeEmulator = Emulator.active;
			String message = .Empty;
			if (activeEmulator == null) {
				message = "Waiting for Emulator";
			} else {
				if (!activeEmulator.Supported) {
					message = scope:: String() .. AppendF("Unknown Module Size: (0x{:x})", activeEmulator.MainModuleSize);
				} else if (activeEmulator.romChecksum == 0) {
					message = "Waiting for Game";
				} else {
					message = scope:: String();
					Emulator.active.GetGameName(message);
				}

				let baseline = WindowApp.height / 2 - WindowApp.font.height * 1.5f;
				let emulatorName = scope String() .. AppendF("{} ({})", activeEmulator.Name, activeEmulator.Version);
				let halfWidth = Math.Round(WindowApp.font.CalculateWidth(emulatorName) / 2);
				WindowApp.font.Print(emulatorName, .(middleWindow - halfWidth, baseline), activeEmulator.Supported ? .(255,255,255) : .(255,255,0));
			}

			var baseline = (WindowApp.height - WindowApp.font.height) / 2;
			let halfWidth = Math.Round(WindowApp.font.CalculateWidth(message) / 2);
			WindowApp.font.Print(message, .(middleWindow - halfWidth, baseline), .(255,255,255));

			baseline += WindowApp.font.penLine;
			if (activeEmulator == null || activeEmulator.romChecksum == 0) {
				let t = (float)stopwatch.ElapsedMilliseconds / 1000 * 3.14f;
				DrawUtilities.Rect(baseline + 2, baseline + 4, middleWindow - halfWidth * Math.Sin(t), middleWindow + halfWidth * Math.Sin(t),
					.(255,255,255));
			} else {
				let t = 1f - (float)stopwatch.ElapsedMilliseconds / 3000;
				DrawUtilities.Rect(baseline + 2, baseline + 4, middleWindow - halfWidth * t, middleWindow + halfWidth * t,
					.(255,255,255));
			}

			for (let element in guiElements) {
				if (element.visible) {
					element.Draw();
				}
			}
		}

		void CheckEmulator() {
			Emulator.active.CheckProcessStatus();
			if (Emulator.active.Supported) {
				Emulator.active.FetchMainAddresses();
				Emulator.active.FindGame();
			}
		}
	}
}
