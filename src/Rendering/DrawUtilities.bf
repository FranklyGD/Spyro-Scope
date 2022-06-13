using System;

namespace SpyroScope {
	static struct DrawUtilities {
		[Inline]
		public static void Axis(Vector3 position, Matrix3 basis) {
			let job = Renderer.opaquePass.AddJob(PrimitiveShape.cylinder);

			job.AddInstance(.Transform(position + basis.x * 0.5f, basis * .(.(0,0,0.1f),.(0,0.1f,0),.(-1,0,0))), .(1,0,0));
			job.AddInstance(.Transform(position + basis.y * 0.5f, basis * .(.(0.1f,0,0),.(0,0,0.1f),.(0,-1,0))), .(0,1,0));
			job.AddInstance(.Transform(position + basis.z * 0.5f, basis * .(.(0.1f,0,0),.(0,0.1f,0),.(0,0,1))), .(0,0,1));
		}

		[Inline]
		public static void Circle(Vector3 position, Matrix3 basis, Color color) {
			for (int i < 32) {
				let theta0 = (float)i / 16 * Math.PI_f;
				let theta1 = (float)(i + 1) / 16 * Math.PI_f;
				let point0 = basis * Vector3(Math.Cos(theta0), Math.Sin(theta0), 0);
				let point1 = basis * Vector3(Math.Cos(theta1), Math.Sin(theta1), 0);
				Renderer.Line(position + point0, position + point1, color, color);
			}
		}

		[Inline]
		public static void Arrow(Vector3 origin, Vector3 direction, float width, Color color) {
			if (direction.x * direction.x < 1 && direction.y * direction.y < 1 && direction.z * direction.z < 1) {
				return;
			}

			Matrix3 arrowMatrix = ?;

			arrowMatrix.z = direction;
			if (arrowMatrix.z.x == 0 && arrowMatrix.z.y == 0) {
				arrowMatrix.x = .(1,0,0);
				arrowMatrix.y = .(0,arrowMatrix.z.z > 0 ? 1 : -1,0);
			} else {
				arrowMatrix.y = Vector3.Cross(arrowMatrix.z, .(0,0,1)).Normalized();
				arrowMatrix.x = Vector3.Cross(arrowMatrix.y, arrowMatrix.z).Normalized();
			}


			arrowMatrix.x *= width;
			arrowMatrix.y *= width;
			Renderer.opaquePass.AddJob(PrimitiveShape.cylinder) .. AddInstance(.Transform(origin + direction / 2, arrowMatrix), color.ToVector());

			arrowMatrix.x *= 2;
			arrowMatrix.y *= 2;
			arrowMatrix.z = arrowMatrix.z.Normalized() * width * 2;
			Renderer.opaquePass.AddJob(PrimitiveShape.cone) .. AddInstance(.Transform(origin + direction, arrowMatrix), color.ToVector());
		}

		[Inline]
		public static void WireframeSphere(Vector3 position, Matrix3 basis, float radius, Color color) {
			let scaledBasis = basis * radius;
			DrawUtilities.Circle(position, scaledBasis, color);
			DrawUtilities.Circle(position, Matrix3(scaledBasis.y, scaledBasis.z, scaledBasis.x), color);
			DrawUtilities.Circle(position, Matrix3(scaledBasis.z, scaledBasis.x, scaledBasis.y), color);

			let positionDifference = Renderer.viewPosition - position;
			let distance = positionDifference.Length();

			// Check if view is inside collision radius
			if (distance <= radius) {
				return;
			}

			let t = radius / distance;
			float tanAngle = Math.Acos(t);
			let offsetedCenter = position + positionDifference * (t * radius / distance);
			let tangentRadius = Math.Sin(tanAngle) * radius;

			Matrix3 tangentCircleBasis = ?;
			tangentCircleBasis.z = positionDifference / distance;
			tangentCircleBasis.y = Vector3.Cross(positionDifference, Renderer.viewBasis.x).Normalized();
			tangentCircleBasis.x = Vector3.Cross(tangentCircleBasis.z, tangentCircleBasis.y);

			DrawUtilities.Circle(offsetedCenter, tangentCircleBasis * tangentRadius, color);
		}

		[Inline]
		public static void Quad(Vector3[4] points, Vector2[4] uvs, Texture texture, Color4 color) {
			Renderer.Triangle(points[0], points[1], points[2], color, color, color, uvs[0], uvs[1], uvs[2], texture.textureObjectID);
			Renderer.Triangle(points[0], points[2], points[3], color, color, color, uvs[0], uvs[2], uvs[3], texture.textureObjectID);
		}

		[Inline]
		public static void Quad(Vector3[4] points, Color4 color) {
			Quad(points, .(.Zero,.Zero,.Zero,.Zero), Renderer.whiteTexture, color);
		}

		[Inline]
		public static void Rect(float top, float bottom, float left, float right,
			float uvtop, float uvbottom, float uvleft, float uvright,
			Texture texture, Color4 color) {

			Quad(
				.(.(left, top, 0), .(right, top, 0), .(right, bottom, 0), .(left, bottom, 0)),
				.(.(uvleft, uvtop), .(uvright, uvtop), .(uvright, uvbottom), .(uvleft, uvbottom)),
				texture, color
			);
		}

		[Inline]
		public static void Rect(float top, float bottom, float left, float right, Color4 color) {
			Rect(top,bottom,left,right, 0,0,0,0, Renderer.whiteTexture, color);
		}

		[Inline]
		public static void Rect(Rect rect, Rect uvRect, Texture texture, Color4 color) {
			Rect(
				rect.top, rect.bottom, rect.left, rect.right,
				uvRect.top, uvRect.bottom, uvRect.left, uvRect.right,
				texture, color
			);
		}

		[Inline]
		public static void Rect(Rect rect, Color4 color) {
			Rect(
				rect.top, rect.bottom, rect.left, rect.right,
				0,0,0,0,
				Renderer.whiteTexture, color
			);
		}

		[Inline]
		public static void SlicedRect(float top, float bottom, float left, float right,
			float uvtop, float uvbottom, float uvleft, float uvright,
			float uvtopinner, float uvbottominner, float uvleftinner, float uvrightinner,
			Texture texture, Color4 color) {

			var bottomBorder = texture.height * (1 - uvbottominner);
			var leftBorder = texture.width * uvleftinner;
			var topBorder = texture.height * uvtopinner;
			var rightBorder = texture.width * (1 - uvrightinner);

			// Preserved Corners
			Rect(top - topBorder, top, left, left + leftBorder, uvbottominner, uvbottom, uvleft, uvleftinner, texture, color);
			Rect(top - topBorder, top, right - rightBorder, right, uvbottominner, uvbottom, uvrightinner, uvright, texture, color);
			Rect(bottom, bottom + bottomBorder, left, left + leftBorder, uvtop, uvtopinner, uvleft, uvleftinner, texture, color);
			Rect(bottom, bottom + bottomBorder, right - rightBorder, right, uvtop, uvtopinner, uvrightinner, uvright, texture, color);

			// Stretched Edges
			Rect(top - topBorder, top, left + leftBorder, right - rightBorder, uvbottominner, uvbottom, uvleftinner, uvrightinner, texture, color);
			Rect(bottom, bottom + bottomBorder, left + leftBorder, right - rightBorder, uvtop, uvtopinner, uvleftinner, uvrightinner, texture, color);
			Rect(bottom + bottomBorder, top - topBorder, left, left + leftBorder, uvtopinner, uvbottominner, uvleft, uvleftinner, texture, color);
			Rect(bottom + bottomBorder, top - topBorder, right - rightBorder, right, uvtopinner, uvbottominner, uvrightinner, uvright, texture, color);

			// Stretched Center
			Rect(bottom + bottomBorder, top - topBorder, left + leftBorder, right - rightBorder, uvtopinner, uvbottominner, uvleftinner, uvrightinner, texture, color);
		}


		[Inline]
		public static void Grid(Vector3 position, Matrix3 basis, Color4 color) {
			let relativeViewPosition = basis.Transpose() * (Camera.position - position);
			
			let distance = Math.Max(Math.Abs(relativeViewPosition.z), 1000);
			let magnitude = Math.Log10(distance);
			let invMagnitudeFrac = 1 - (magnitude - (int)magnitude);
			let roundedDistance = Math.Pow(10, (int)magnitude - 1);
			let normalizedDistance = distance / roundedDistance * 4 + 1;

			var endColor = color;
			endColor.a = 0;

			
			for (var i = -(int)normalizedDistance; i < normalizedDistance; i++) {
				let baseInterval = Math.Round(relativeViewPosition.y / roundedDistance);
				let interval = baseInterval + i;
				let slidingOffset = position + basis * Vector3(relativeViewPosition.x, interval * roundedDistance, 0);

				let isTenth = interval % 10 == 0;
				let brightness = Math.Max(1f - Math.Abs(interval * roundedDistance - relativeViewPosition.y) / (distance * 4), 0) * (isTenth ? 1 : invMagnitudeFrac * invMagnitudeFrac);
				var midColor = color;
				midColor.a = (.)(255 * brightness);

				Renderer.Line(slidingOffset, slidingOffset + basis.x * distance * 4, midColor, endColor);
				Renderer.Line(slidingOffset, slidingOffset - basis.x * distance * 4, midColor, endColor);
			}

			for (var i = -(int)normalizedDistance; i < normalizedDistance; i++) {
				let baseInterval = Math.Round(relativeViewPosition.x / roundedDistance);
				let interval = baseInterval + i;
				let slidingOffset = position + basis * Vector3(interval * roundedDistance, relativeViewPosition.y, 0);

				let isTenth = interval % 10 == 0;
				let brightness = Math.Max(1f - Math.Abs(interval * roundedDistance - relativeViewPosition.x) / (distance * 4), 0) * (isTenth ? 1 : invMagnitudeFrac * invMagnitudeFrac);
				var midColor = color;
				midColor.a = (.)(255 * brightness);

				Renderer.Line(slidingOffset, slidingOffset + basis.y * distance * 4, midColor, endColor);
				Renderer.Line(slidingOffset, slidingOffset - basis.y * distance * 4, midColor, endColor);
			}
		}
	}
}
