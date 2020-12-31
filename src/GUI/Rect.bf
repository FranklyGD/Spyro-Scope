namespace SpyroScope {
	public struct Rect {
		public Vector2 start, end;

		public float left { get => start.x; set mut => start.x = value; }
		public float right { get => end.x; set mut => end.x = value; }
		public float top { get => start.y; set mut => start.y = value; }
		public float bottom { get => end.y; set mut => end.y = value; }

		public float Width { get => right - left; }
		public float Height { get => bottom - top; }

		public this(float left, float right, float top, float bottom) {
			start.x = left; start.y = top;
			end.x = right; end.y = bottom;
		}

		public void Shift(Vector2 shift) mut {
			start += shift;
			end += shift;
		}

		public void Shift(float x, float y) mut {
			right += x;
			left += x;
			top += y;
			bottom += y;
		}
	}
}
