using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		WindowState state;
		List<WindowState> states = new .();

		public readonly uint32 id;
		public static uint width, height;
		public static (float x, float y) mousePosition;

		public bool closed { get; private set; }

		public static Matrix4 viewerProjection;
		public static Matrix4 uiProjection;

		// Game Camera
		const float gameFoV = 55;
		public static readonly Matrix4 gameProjection = .Perspective(gameFoV * Math.PI_f / 180, 4f/3f, 300, 175000);

		public static BitmapFont bitmapFont ~ delete _;
		public static SpyroScope.Font font ~ delete _;
		public static SpyroScope.Font fontSmall  ~ delete _;

		public this() {
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

			state = new SetupState();
			states.Add(state);
			states.Add(new ViewerState());

			// Attempt to find and bind as the window is being opened
			Emulator.FindEmulator();
			if (Emulator.emulator != .None) {
				Emulator.FindGame();
				if (Emulator.rom != .None) {
					state = states[1];
				}
			}

			state.Enter();

			windowApp = this;
		}

		public ~this() {
			Emulator.UnbindFromEmulator();

			state.Exit();

			DeleteContainerAndItems!(states);

			Renderer.Unload();
			if (window != null)
				SDL.DestroyWindow(window);

			window = null;
		}

		public void Run() {
			Renderer.Clear();

			state.Update();

			GL.glBindTexture(GL.GL_TEXTURE_2D, Renderer.whiteTexture.textureObjectID);
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			GL.glEnable(GL.GL_DEPTH_TEST);
			state.DrawView();

			Renderer.SetView(.Zero, .Identity);
			Renderer.SetProjection(WindowApp.uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);
			state.DrawGUI();

			int32 majorVersion = ?;
			int32 minorVersion = ?;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, (.)&majorVersion);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, (.)&minorVersion);

			bitmapFont.Print(scope String() .. AppendF("OpenGL {}.{}", majorVersion, minorVersion), .((.)WindowApp.width - bitmapFont.characterWidth * 10, 0, 0), .(255,255,255,8));

			Renderer.Draw();
			Renderer.Sync();
			Renderer.Display();
		}

		public mixin GoToState<T>() where T : WindowState {
			for	(let state in states) {
				let test = state is T;
				if (test) {
					this.state.Exit();
					this.state = state; 
					state.Enter();
					return;
				}
			}
			String typeName = scope .();
			typeof(T).GetName(typeName);
			Debug.FatalError(scope String() .. AppendF("Failed to go to state \"{}\"", typeName));
		} 

		public void Close() {
			closed = true;
		}

		void Resize(uint width, uint height) {
			WindowApp.width = width;
			WindowApp.height = height;
			GL.glViewport(0, 0, (.)width, (.)height);

			viewerProjection = Camera.projection;
			uiProjection = .Screen(width, height);
		}

		public void OnEvent(SDL.Event event) {
			if (event.type == .MouseMotion) {
				mousePosition = (event.motion.x, event.motion.y);
			}

			if (state.OnEvent(event)) {
				return;
			}

			switch (event.type) {
				case .WindowEvent : {
					switch (event.window.windowEvent) {
						case .Close : {
							closed = true;
						}
						case .Resized : {
							Resize((.)event.window.data1, (.)event.window.data2);
						}
						default : {}
					}
				}
				default : {}
			}
		}
	}

	static {
		public static WindowApp windowApp;
	}
}
