using System;

namespace SpyroScope {
	public struct Color {
		public uint8 r,g,b;
		public this(uint8 r, uint8 g, uint8 b) {
			this.r = r;
			this.g = g;
			this.b = b;
		}

		public static implicit operator Color(Color4 color) {
			return .(color.r, color.g, color.b);
		}

		public static Color Lerp(Color bg, Color fg, float alpha) {
			return .((.)Math.Lerp(bg.r, fg.r, alpha), (.)Math.Lerp(bg.g, fg.g, alpha), (.)Math.Lerp(bg.b, fg.b, alpha));
		}

		[Inline]
		public Vector3 ToVector() {
			return .((float)r / 255, (float)g / 255, (float)b / 255);
		}
	}

	public struct Color4 {
		public uint8 r,g,b,a;
		public this(uint8 r, uint8 g, uint8 b, uint8 a) {
			this.r = r;
			this.g = g;
			this.b = b;
			this.a = a;
		}

		public this(uint8 r, uint8 g, uint8 b) {
			this.r = r;
			this.g = g;
			this.b = b;
			this.a = 255;
		}

		public static implicit operator Color4(Color color) {
			return .(color.r, color.g, color.b, 255);
		}

		[Inline]
		public Vector4 ToVector() {
			return .((float)r / 255, (float)g / 255, (float)b / 255, (float)a / 255);
		}
	}
}
