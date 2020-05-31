namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Renderer renderer, Moby object) {
			Vector glidePoint = object.position + .(0,0,(.)height);
			renderer.PushTriangle(
				glidePoint + .(-300,0,0), glidePoint + .(300,0,0), glidePoint + .(0,0,300),
				.(255,255,0), .(255,255,0), .(255,255,0));
			renderer.PushTriangle(
				glidePoint + .(-300,0,0), glidePoint + .(300,0,0), glidePoint + .(0,0,300),
				.(255,255,0), .(255,255,0), .(255,255,0));
		}
	}
}
