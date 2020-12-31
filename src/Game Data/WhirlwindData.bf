using System;

namespace SpyroScope {
	struct WhirlwindData {
		public uint32 height;
		public uint32 radius;

		public void Draw(Moby object) {
			let position = (Vector3)object.position;

			Vector3 glidePoint = .(0,0,(.)height);
			DrawUtilities.Arrow(position, glidePoint, radius / 10, .(0,255,255));

			DrawUtilities.Circle(position, Matrix3.Scale(radius,radius,radius), .(0,255,255));
			DrawUtilities.Circle(position + glidePoint, Matrix3.Scale(radius,radius,radius), .(0,255,255));

			let positionDifference = Renderer.viewPosition - position;
			let lateralDistance = Math.Sqrt(positionDifference.x * positionDifference.x + positionDifference.y * positionDifference.y);

			// Check if view is inside whirlwind
			if (lateralDistance <= radius) {
				return;
			}

			let lateralDifference = Vector3(positionDifference.x, positionDifference.y, 0);

			let t = radius / lateralDistance;
			float tanAngle = Math.Acos(t);
			let offsetedCenter = position + lateralDifference * (t * radius / lateralDistance);
			let tangentRadius = Math.Sin(tanAngle) * radius;
			let tangentPoint = Vector3(lateralDifference.y / lateralDistance, -lateralDifference.x / lateralDistance, 0) * tangentRadius;

			Renderer.DrawLine(offsetedCenter + tangentPoint, offsetedCenter + tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
			Renderer.DrawLine(offsetedCenter - tangentPoint, offsetedCenter - tangentPoint + glidePoint, .(0,255,255), .(0,255,255));
		}
	}
}
