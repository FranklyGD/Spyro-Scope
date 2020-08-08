using OpenGL;
using SDL2;

namespace SpyroScope {
	class WindowState {
		public virtual void Enter() {}
		public virtual void Exit() {}

		public virtual void Update() {}
		public virtual void DrawView(Renderer renderer) {}
		public virtual void DrawGUI(Renderer renderer) {}
		
		public virtual bool OnEvent(SDL.Event event) { return false; }
	}
}