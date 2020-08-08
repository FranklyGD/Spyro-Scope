using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class WindowApp {
		SDL.Window* window;
		public static Renderer renderer;
		WindowState state;
		List<WindowState> states = new .();

		public readonly uint32 id;
		public static uint width, height;

		public bool closed { get; private set; }

		public static Matrix4 viewerProjection;
		public static Matrix4 uiProjection;

		// Game Camera
		const float gameFoV = 55;
		public static readonly Matrix4 gameProjection = .Perspective(gameFoV * Math.PI_f / 180, 4f/3f, 300, 175000);

		public static BitmapFont bitmapFont ~ delete _;
		public static SpyroScope.Font font ~ delete _;

		public this() {
			width = 750;
			height = 600;

			window = SDL.CreateWindow("Scope", .Undefined, .Undefined, (.)width, (.)height,
				.Shown | .Resizable | .InputFocus | .Utility | .OpenGL);
			renderer = new .(window);
			bitmapFont = new .("images/font.png", 12, 20);
			font = new .("Roboto-Regular.ttf", 20);

			Camera.fov = 55;
			viewerProjection = Camera.projection;
			uiProjection = .Orthogonal(width, height, -1, 1);

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

			if (renderer != null)
				delete renderer;
			if (window != null)
				SDL.DestroyWindow(window);

			window = null;
		}

		public void Run() {
			renderer.Clear();

			state.Update();

			GL.glBindTexture(GL.GL_TEXTURE_2D, Renderer.textureDefaultWhite);
			renderer.SetView(Camera.position, Camera.basis);
			renderer.SetProjection(WindowApp.viewerProjection);
			GL.glEnable(GL.GL_DEPTH_TEST);
			state.DrawView(renderer);

			renderer.SetView(.Zero, .Identity);
			renderer.SetProjection(WindowApp.uiProjection);
			GL.glDisable(GL.GL_DEPTH_TEST);
			state.DrawGUI(renderer);

			int32 majorVersion = ?;
			int32 minorVersion = ?;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, (.)&majorVersion);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, (.)&minorVersion);
			
			let halfWidth = (float)width / 2;
			let halfHeight = (float)height / 2;

			bitmapFont.Print(scope String() .. AppendF("OpenGL {}.{}", majorVersion, minorVersion), .(halfWidth - bitmapFont.characterWidth * 10, halfHeight - bitmapFont.characterHeight, 0), .(255,255,255,8), renderer);
			
			renderer.Draw();
			renderer.Sync();
			renderer.Display();
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
			uiProjection = .Orthogonal(width, height, 0, 1);
		}

		public void OnEvent(SDL.Event event) {
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
