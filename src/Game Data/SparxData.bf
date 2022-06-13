namespace SpyroScope {
	struct SparxData {
		int16 positionTimer;
		int16 a;
		int16[3] localPosition;

		static int16 maxTime;
		static int16 lastTime;

		public void Draw(Moby object) {
			if (positionTimer > lastTime) {
				maxTime = positionTimer;
			}
			lastTime = positionTimer;

			let basis = Emulator.active.spyroBasis.ToMatrixCorrected();

			let targetLocation = basis * Vector3(localPosition[0], localPosition[1], localPosition[2]);
			Renderer.Line(object.position, Emulator.active.SpyroPosition + targetLocation, .(255,255,0), .(255,255,0));

			DrawUtilities.Circle(
				Emulator.active.SpyroPosition + targetLocation,
				Matrix3.Identity * 200 * ((float)positionTimer / maxTime),
				.(255,255,0)
			);
		}
	}
}
