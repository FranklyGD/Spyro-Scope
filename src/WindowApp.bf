using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		WindowState state, lastState;
		List<WindowState> states = new .();

		public readonly uint32 id;
		public static int width, height;
		public static Vector2 mousePosition;

		public bool closed { get; private set; }

		public static Matrix4 viewerProjection;
		public static Matrix4 uiProjection;

		// Game Camera
		const float gameFoV = 55;
		public static readonly Matrix4 gameProjection = .Perspective(gameFoV * Math.PI_f / 180, 4f/3f, 300, 175000);

		public static BitmapFont bitmapFont ~ delete _;
		public static FTFont font ~ delete _;
		public static FTFont fontSmall  ~ delete _;

		public this() {
			windowApp = this;

			width = 750;
			height = 600;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, (.)width, (.)height,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			Renderer.Init(window);

			bitmapFont = new .("images/ui/font.png", 12, 20);
			font = new .("fonts/Roboto-Regular.ttf", 20);
			fontSmall = new .("fonts/Roboto-Regular.ttf", 14);

			Camera.fov = 55;
			viewerProjection = Camera.projection;
			uiProjection = .Screen(width, height);

			id = SDL.GetWindowID(window);
			GUIElement.Init();

			state = new SetupState();
			states.Add(state);
			states.Add(new ViewerState());
			states.Add(new VRAMViewerState());

			// Attempt to find and bind as the window is being opened
			let processes = new List<Process>();
			Emulator.FindProcesses(processes);

			if (processes.Count == 1) {
				Emulator.BindEmulatorProcess(processes[0]);
			}

			DeleteContainerAndItems!(processes);

			if (Emulator.active != null && Emulator.active.Supported) {
				Emulator.active.FetchMainAddresses();
				Emulator.active.FindGame();
				if (Emulator.active.romChecksum != 0) {
					state = states[1];
				}
			}

			state.Enter();
		}

		public ~this() {
			state.Exit();
			DeleteContainerAndItems!(states);

			Emulator.UnbindAllEmulators();

			Renderer.Unload();
			if (window != null)
				SDL.DestroyWindow(window);

			window = null;
		}

		public void Run() {
			Renderer.Clear();
			
			GUIElement.GUIUpdate();
			state.Update();

			if (lastState != state) {
				// Do not draw immediately, as all the values for drawing have not initialized yet
				lastState = state;
				return;
			}
			
			state.DrawView();

			Renderer.SetView(.Zero, .Identity);
			Renderer.SetProjection(WindowApp.uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);
			state.DrawGUI();


			int32 majorVersion = ?;
			int32 minorVersion = ?;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, (.)&majorVersion);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, (.)&minorVersion);

			
#if DEBUG
			let versionString = scope String("Spyro Scope (DEV)");
#else
			let versionString = scope $"Spyro Scope {Program.versionInfo.FileVersion}";
#endif

			let openglVersionString = scope $"OpenGL {majorVersion}.{minorVersion}";

			bitmapFont.Print(versionString, .(WindowApp.width - bitmapFont.characterWidth * versionString.Length, 0), .(255,255,255,8));
			bitmapFont.Print(openglVersionString, .(WindowApp.width - bitmapFont.characterWidth * 10, bitmapFont.height), .(255,255,255,8));

			Renderer.Draw();
			Renderer.Sync();
			Renderer.Display();
		}

		public void GoToState<T>() where T : WindowState {
			for	(let state in states) {
				let test = state is T;
				if (test) {
					this.state.Exit();
					lastState = this.state;
					this.state = state; 
					state.Enter();
					return;
				}
			}
			String typeName = scope .();
			typeof(T).GetName(typeName);
			Debug.FatalError(scope $"Failed to go to state \"{typeName}\"");
		} 

		public void Close() {
			closed = true;
		}

		public void Rename(String title) {
			SDL.SetWindowTitle(window, title);
		}

		void Resize(int width, int height) {
			WindowApp.width = width;
			WindowApp.height = height;

			viewerProjection = Camera.projection;
			uiProjection = .Screen(width, height);
			
			GL.glViewport(0, 0, width, height);
			Frame.ResizeAllToWindow();
		}

		public void OnEvent(SDL.Event event) {
			switch (event.type) {
				case .WindowEvent: {
					switch (event.window.windowEvent) {
						case .Close: {
							closed = true;
						}
						case .Resized: {
							Resize(event.window.data1, event.window.data2);
						}
						default:
					}
				}
				default:
			}

			if (event.type == .MouseMotion) {
				mousePosition = .(event.motion.x, event.motion.y);
			}

			if (GUIElement.GUIEvent(event) || state.OnEvent(event)) {
				return;
			}
		}
	}

	static {
		public static WindowApp windowApp;
	}
}
