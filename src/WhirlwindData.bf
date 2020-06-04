namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Renderer renderer, Moby object) {
			Vector glidePoint = .(0,0,(.)height);

			renderer.SetModel(object.position + glidePoint / 2, .Scale(radius / 10, radius / 10, height));

			PrimitiveShape.cylinder.Draw();
		}
	}
}
