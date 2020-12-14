namespace SpyroScope {
	static class BitEdit {
		public static mixin Get(var value, var mask) {
			value & mask
		}

		public static mixin Set(var target, var value, var mask) {
			target = (.)(target & ~mask | value & mask);
		}

		public static mixin Set(var target, bool value, var mask) {
			target = (.)(target & ~mask | (value ? mask : 0));
		}
	}
}
