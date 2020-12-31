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

			let basis = Emulator.spyroBasis.ToMatrixCorrected();

			let targetLocation = basis * Vector3(localPosition[0], localPosition[1], localPosition[2]);
			Renderer.DrawLine(object.position, Emulator.spyroPosition + targetLocation, .(255,255,0), .(255,255,0));

			DrawUtilities.Circle(
				Emulator.spyroPosition + targetLocation,
				Matrix3.Identity * 200 * ((float)positionTimer / maxTime),
				.(255,255,0)
			);
		}
	}
}
