namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Renderer renderer, Moby object) {
			Vector glidePoint = object.position + .(0,0,(.)height);
			renderer.PushTriangle(
				glidePoint + .(-100,0,100),
				glidePoint + .(100,0,100),
				glidePoint + .(0,0,0),
				.(0,255,255), .(0,255,255), .(0,255,255));
		}
	}
}
