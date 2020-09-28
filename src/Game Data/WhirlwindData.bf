using System;

namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Moby object) {
			Vector glidePoint = .(0,0,(.)height);
			DrawUtilities.Arrow(object.position, glidePoint, radius / 10, .(0,255,255));

			DrawUtilities.Circle(object.position, Matrix.Scale(radius,radius,radius), .(0,255,255));
			DrawUtilities.Circle(object.position + glidePoint, Matrix.Scale(radius,radius,radius), .(0,255,255));

			let positionDifference = Renderer.viewPosition - object.position;
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

			Renderer.DrawLine(offsetedCenter + tangentPoint, offsetedCenter + tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
			Renderer.DrawLine(offsetedCenter - tangentPoint, offsetedCenter - tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
		}
	}
}
