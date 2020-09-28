using OpenGL;
using SDL2;

namespace SpyroScope {
	class WindowState {
		public virtual void Enter() {}
		public virtual void Exit() {}

		public virtual void Update() {}
		public virtual void DrawView() {}
		public virtual void DrawGUI() {}
		
		public virtual bool OnEvent(SDL.Event event) { return false; }
	}
}