using System;

namespace SpyroScope {
	static struct DrawUtilities {
		[Inline]
		public static void Axis(Vector position, Matrix basis, Renderer renderer) {
			let squareAngle = Math.PI_f / 2;
			renderer.SetModel(position + basis.x * 0.5f, basis * .Euler(0, -squareAngle, 0) * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(255,0,0));
			PrimitiveShape.cylinder.QueueInstance(renderer);
			renderer.SetModel(position + basis.y * 0.5f, basis * .Euler(squareAngle, 0, 0) * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(0,255,0));
			PrimitiveShape.cylinder.QueueInstance(renderer);
			renderer.SetModel(position + basis.z * 0.5f, basis * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(0,0,255));
			PrimitiveShape.cylinder.QueueInstance(renderer);
		}

		[Inline]
		public static void Circle(Vector position, Matrix basis, Renderer.Color color, Renderer renderer) {
			for (int i < 32) {
				let theta0 = (float)i / 16 * Math.PI_f;
				let theta1 = (float)(i + 1) / 16 * Math.PI_f;
				let point0 = basis * Vector(Math.Cos(theta0), Math.Sin(theta0), 0);
				let point1 = basis * Vector(Math.Cos(theta1), Math.Sin(theta1), 0);
				renderer.DrawLine(position + point0, position + point1, color, color);
			}
		}

		[Inline]
		public static void Arrow(Vector origin, Vector direction, float width, Renderer.Color color, Renderer renderer) {
			if (direction.x * direction.x < 1 && direction.y * direction.y < 1 && direction.z * direction.z < 1) {
				return;
			}

			Matrix arrowMatrix = ?;

			arrowMatrix.z = direction;
			if (arrowMatrix.z.x == 0 && arrowMatrix.z.y == 0) {
				arrowMatrix.x = .(1,0,0);
				arrowMatrix.y = .(0,arrowMatrix.z.z > 0 ? 1 : -1,0);
			} else {
				arrowMatrix.y = Vector.Cross(arrowMatrix.z, .(0,0,1)).Normalized();
				arrowMatrix.x = Vector.Cross(arrowMatrix.y, arrowMatrix.z).Normalized();
			}

			renderer.SetTint(color);

			arrowMatrix.x *= width;
			arrowMatrix.y *= width;
			renderer.SetModel(origin + direction / 2, arrowMatrix);
			PrimitiveShape.cylinder.QueueInstance(renderer);

			arrowMatrix.x *= 2;
			arrowMatrix.y *= 2;
			arrowMatrix.z = arrowMatrix.z.Normalized() * width * 2;
			renderer.SetModel(origin + direction, arrowMatrix);
			PrimitiveShape.cone.QueueInstance(renderer);
		}

		[Inline]
		public static void WireframeSphere(Vector position, Matrix basis, float radius, Renderer.Color color, Renderer renderer) {
			let scaledBasis = basis * radius;
			DrawUtilities.Circle(position, scaledBasis, color, renderer);
			DrawUtilities.Circle(position, Matrix(scaledBasis.y, scaledBasis.z, scaledBasis.x), color, renderer);
			DrawUtilities.Circle(position, Matrix(scaledBasis.z, scaledBasis.x, scaledBasis.y), color, renderer);

			let positionDifference = renderer.viewPosition - position;
			let distance = positionDifference.Length();

			// Check if view is inside collision radius
			if (distance <= radius) {
				return;
			}

			let t = radius / distance;
			float tanAngle = Math.Acos(t);
			let offsetedCenter = position + positionDifference * (t * radius / distance);
			let tangentRadius = Math.Sin(tanAngle) * radius;

			Matrix tangentCircleBasis = ?;
			tangentCircleBasis.z = positionDifference / distance;
			tangentCircleBasis.y = Vector.Cross(positionDifference, renderer.viewBasis.x).Normalized();
			tangentCircleBasis.x = Vector.Cross(tangentCircleBasis.z, tangentCircleBasis.y);

			DrawUtilities.Circle(offsetedCenter, tangentCircleBasis * tangentRadius, color, renderer);
		}

		[Inline]
		public static void Rect(float bottom, float top, float left, float right,
			float uvbottom, float uvtop, float uvleft, float uvright,
			uint textureObject, Renderer.Color4 color, Renderer renderer) {

			renderer.DrawTriangle(.(left,bottom,0), .(left,top,0), .(right,top,0), color, color, color,
					(uvleft, uvbottom), (uvleft, uvtop), (uvright, uvtop), textureObject);
			renderer.DrawTriangle(.(left,bottom,0), .(right,top,0), .(right,bottom,0), color, color, color,
					(uvleft, uvbottom), (uvright, uvtop), (uvright, uvbottom), textureObject);
		}
	}
}
