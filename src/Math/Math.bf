namespace System {
	extension Math {
		[Inline]
		public static float Repeat(float value, float limit) {
			return value - Math.Floor(value / limit) * limit;
		}

		[Inline]
		public static int Repeat(int value, int limit) {
			return value - (int)Math.Floor((float)value / limit) * limit;
		}
		
		[Inline]
		public static float MoveTo(float from, float to, float delta) {
			let difference = to - from;

			if (delta > Math.Abs(difference)) {
				return to;
			}

			return from + delta * Math.Sign(difference);
		}
	}
}
