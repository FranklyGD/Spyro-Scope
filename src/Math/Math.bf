namespace System {
	extension Math {
		public static float Repeat(float value, float limit) {
			return value - Math.Floor(value / limit) * limit;
		}

		public static float MoveTo(float from, float to, float delta) {
			let difference = to - from;

			if (delta > Math.Abs(difference)) {
				return to;
			}

			return from + delta * Math.Sign(difference);
		}
	}
}
