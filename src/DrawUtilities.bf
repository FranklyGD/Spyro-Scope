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
	}
}
