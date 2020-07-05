using OpenGL;
using SDL2;
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace SpyroScope {
	class Program {
		static SDL.SDL_GameController* connectedController;

		static void Main() {
			String exePath = scope .();
			Environment.GetExecutableFilePath(exePath);
			String exeDir = scope .();
			Path.GetDirectoryPath(exePath, exeDir);
			Directory.SetCurrentDirectory(exeDir);

			SDL.Init(.Video | .Events);// | .GameController);

			let mainWindow = scope WindowApp();

			while (!mainWindow.closed) {
				SDL.Event event;
				while (SDL.PollEvent(out event) != 0) {
					/*switch (event.type) {
						case .ControllerDeviceadded : {
							if (connectedController != null)
								SDL.GameControllerClose(connectedController);
							connectedController = SDL.GameControllerOpen(event.cdevice.which);
						}
						case .ControllerDeviceremoved : {
							if (connectedController != null)
								SDL.GameControllerClose(connectedController);
						}
						case .ControllerButtondown : {
							if (event.cbutton.button == 8) { // Right Stick Press
								Emulator.ToggleCameraMode();
							}
						}
						default : {}
					}*/

					switch (event.window.windowID) {
						case mainWindow.id : {
							mainWindow.OnEvent(event);
						}
						default : {}
					}
				}

				mainWindow.Run();
				Thread.Sleep(10);
			}
		}
	}

	static {
		public static void* SdlGetProcAddress(StringView string) {
			return SDL.SDL_GL_GetProcAddress(string.ToScopeCStr!());
		}
	}
}
