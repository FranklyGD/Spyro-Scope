namespace System {
	extension Math {
		public static float Repeat(float value, float limit) {
			return value - Math.Floor(value / limit) * limit;
		}
	}
}
