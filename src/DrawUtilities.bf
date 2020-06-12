using System;

namespace SpyroScope {
	static struct DrawUtilities {
		public static mixin Axis(Vector position, Matrix basis, Renderer renderer) {
			let squareAngle = Math.PI_f / 2;
			renderer.SetModel(position + basis * Vector(0.5f,0,0), basis * .Euler(0, squareAngle, 0) * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(255,0,0));
			PrimitiveShape.cylinder.Draw();
			renderer.SetModel(position + basis * Vector(0,0.5f,0), basis * .Euler(squareAngle, 0, 0) * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(0,255,0));
			PrimitiveShape.cylinder.Draw();
			renderer.SetModel(position + basis * Vector(0,0,0.5f), basis * .Scale(0.1f,0.1f,1));
			renderer.SetTint(.(0,0,255));
			PrimitiveShape.cylinder.Draw();
		}

		public static mixin Circle(Vector position, Matrix basis, Renderer.Color color, Renderer renderer) {
			for (int i < 32) {
				let theta0 = (float)i / 16 * Math.PI_f;
				let theta1 = (float)(i + 1) / 16 * Math.PI_f;
				let point0 = basis * Vector(Math.Cos(theta0), Math.Sin(theta0), 0);
				let point1 = basis * Vector(Math.Cos(theta1), Math.Sin(theta1), 0);
				renderer.DrawLine(position + point0, position + point1, color, color);
			}
		}
	}
}
