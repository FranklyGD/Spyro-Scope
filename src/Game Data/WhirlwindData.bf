using System;

namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Renderer renderer, Moby object) {
			Vector glidePoint = .(0,0,(.)height);
			DrawUtilities.Arrow(object.position, glidePoint, radius / 10, Renderer.Color(0,255,255), renderer);

			DrawUtilities.Circle(object.position, Matrix.Scale(radius,radius,radius), Renderer.Color(0,255,255), renderer);
			DrawUtilities.Circle(object.position + glidePoint, Matrix.Scale(radius,radius,radius), Renderer.Color(0,255,255), renderer);

			let positionDifference = renderer.viewPosition - object.position;
			let lateralDistance = Math.Sqrt(positionDifference.x * positionDifference.x + positionDifference.y * positionDifference.y);

			// Check if view is inside whirlwind
			if (lateralDistance <= radius) {
				return;
			}

			let lateralDifference = Vector(positionDifference.x, positionDifference.y, 0);

			let t = radius / lateralDistance;
			float tanAngle = Math.Acos(t);
			let offsetedCenter = object.position + lateralDifference * (t * radius / lateralDistance);
			let tangentRadius = Math.Sin(tanAngle) * radius;
			let tangentPoint = Vector(lateralDifference.y / lateralDistance, -lateralDifference.x / lateralDistance, 0) * tangentRadius;

			renderer.DrawLine(offsetedCenter + tangentPoint, offsetedCenter + tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
			renderer.DrawLine(offsetedCenter - tangentPoint, offsetedCenter - tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
		}
	}
}
