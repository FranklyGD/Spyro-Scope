using System;

namespace SpyroScope {
	static struct PrimitiveShape {
		public static Mesh cube ~ delete _;
		public static Mesh cylinder ~ delete _;
		public static Mesh cone ~ delete _;

		public static void Init() {
			GenerateCube();
			GenerateCylinder(16);
			GenerateCone(16);
		}

		public static void GenerateCube() {
			let vertices = new Vector3[24](
				.(0.5f,0.5f,0.5f),
				.(0.5f,0.5f,0.5f),
				.(0.5f,0.5f,0.5f),
				.(-0.5f,0.5f,0.5f),
				.(-0.5f,0.5f,0.5f),
				.(-0.5f,0.5f,0.5f),
				.(0.5f,-0.5f,0.5f),
				.(0.5f,-0.5f,0.5f),
				.(0.5f,-0.5f,0.5f),
				.(-0.5f,-0.5f,0.5f),
				.(-0.5f,-0.5f,0.5f),
				.(-0.5f,-0.5f,0.5f),

				.(0.5f,0.5f,-0.5f),
				.(0.5f,0.5f,-0.5f),
				.(0.5f,0.5f,-0.5f),
				.(-0.5f,0.5f,-0.5f),
				.(-0.5f,0.5f,-0.5f),
				.(-0.5f,0.5f,-0.5f),
				.(0.5f,-0.5f,-0.5f),
				.(0.5f,-0.5f,-0.5f),
				.(0.5f,-0.5f,-0.5f),
				.(-0.5f,-0.5f,-0.5f),
				.(-0.5f,-0.5f,-0.5f),
				.(-0.5f,-0.5f,-0.5f)
			);

			let normals = new Vector3[24](
				.(1.0f,0.0f,0.0f),
				.(0.0f,1.0f,0.0f),
				.(0.0f,0.0f,1.0f),
				.(-1.0f,0.0f,0.0f),
				.(0.0f,1.0f,0.0f),
				.(0.0f,0.0f,1.0f),
				.(1.0f,0.0f,0.0f),
				.(0.0f,-1.0f,0.0f),
				.(0.0f,0.0f,1.0f),
				.(-1.0f,0.0f,0.0f),
				.(0.0f,-1.0f,0.0f),
				.(0.0f,0.0f,1.0f),
				
				.(1.0f,0.0f,0.0f),
				.(0.0f,1.0f,0.0f),
				.(0.0f,0.0f,-1.0f),
				.(-1.0f,0.0f,0.0f),
				.(0.0f,1.0f,0.0f),
				.(0.0f,0.0f,-1.0f),
				.(1.0f,0.0f,0.0f),
				.(0.0f,-1.0f,0.0f),
				.(0.0f,0.0f,-1.0f),
				.(-1.0f,0.0f,0.0f),
				.(0.0f,-1.0f,0.0f),
				.(0.0f,0.0f,-1.0f)
			);

			let colors = new Color4[24];
			for	(int i < 24) {
				colors[i] = .(255,255,255);
			}

			let indices = new uint32[36](
				0, 12, 6, 6, 12, 18,
				1, 4, 13, 13, 4, 16,
				2, 8, 5, 5, 8, 11,
				3, 9, 15, 15, 9, 21,
				7, 19, 10, 10, 19, 22,
				14, 17, 20, 20, 17, 23
			);

			cube = new .(vertices, normals, colors, indices);
			cube.MakeInstanced(128);
		}

		public static void GenerateCylinder(int subdivisions) {
			let loop = scope Vector3[subdivisions];
			for (int i < subdivisions) {
				let theta = (float)i / subdivisions * Math.PI_f * 2;
				loop[i] = .(Math.Cos(theta) / 2, Math.Sin(theta) / 2, 0);
			}

			let vertices = new Vector3[subdivisions * 4];
			for (int i < subdivisions) {
				vertices[i + subdivisions * 0] = vertices[i + subdivisions * 1] = loop[i];
				vertices[i + subdivisions * 0].z = vertices[i + subdivisions * 1].z = 0.5f;
				vertices[i + subdivisions * 2] = vertices[i + subdivisions * 3] = loop[i];
				vertices[i + subdivisions * 2].z = vertices[i + subdivisions * 3].z = -0.5f;
			}

			let normals = new Vector3[subdivisions * 4];
			for (int i < subdivisions) {
				normals[i + subdivisions * 0] = .(0,0,1);
				normals[i + subdivisions * 1] = normals[i + subdivisions * 2] = loop[i] * 2;
				normals[i + subdivisions * 3] = .(0,0,-1);
			}

			let colors = new Color4[subdivisions * 4];
			for	(int i < subdivisions * 4) {
				colors[i] = .(255,255,255);
			}

			let indices = new uint32[(subdivisions - 2) * (2 * 3) + subdivisions * (2 * 3)];

			let otherCapStart = (uint32)subdivisions * 3;
			let capTringles = subdivisions - 2;
			for	(int i < capTringles) {
				indices[i * 3 + 0] = 0;
				indices[i * 3 + 1] = (uint32)i + 2;
				indices[i * 3 + 2] = (uint32)i + 1;
				
				indices[(i + capTringles) * 3 + 0] = otherCapStart;
				indices[(i + capTringles) * 3 + 1] = otherCapStart + (uint32)i + 1;
				indices[(i + capTringles) * 3 + 2] = otherCapStart + (uint32)i + 2;
			}

			let loopBridgeStart = capTringles * 6;
			for (int i = 0; i < subdivisions; i++) {
				let index = (uint32)(i % subdivisions);
				let indexPlusOne = (uint32)((i + 1) % subdivisions);
				indices[loopBridgeStart + i * 6 + 0] = (uint32)subdivisions + index;
				indices[loopBridgeStart + i * 6 + 1] = (uint32)subdivisions + indexPlusOne;
				indices[loopBridgeStart + i * 6 + 2] = (uint32)subdivisions * 2 + index;
				
				indices[loopBridgeStart + i * 6 + 3] = (uint32)subdivisions + indexPlusOne;
				indices[loopBridgeStart + i * 6 + 4] = (uint32)subdivisions * 2 + indexPlusOne;
				indices[loopBridgeStart + i * 6 + 5] = (uint32)subdivisions * 2 + index;
			}

			cylinder = new .(vertices, normals, colors, indices);
			cylinder.MakeInstanced(128);
		}

		public static void GenerateCone(int subdivisions) {
			let loop = scope Vector3[subdivisions];
			for (int i < subdivisions) {
				let theta = (float)i / subdivisions * Math.PI_f * 2;
				loop[i] = .(Math.Cos(theta) / 2, Math.Sin(theta) / 2, 0);
			}

			let vertices = new Vector3[subdivisions * 3];
			for (int i < subdivisions) {
				vertices[i + subdivisions * 0] = .(0, 0, 0.5f);
				vertices[i + subdivisions * 1] = vertices[i + subdivisions * 2] = loop[i];
				vertices[i + subdivisions * 1].z = vertices[i + subdivisions * 2].z = -0.5f;
			}

			let normals = new Vector3[subdivisions * 3];
			for (int i < subdivisions) {
				normals[i + subdivisions * 0] = normals[i + subdivisions * 1] = loop[i] * 1.788854382f;
				normals[i + subdivisions * 0].z = normals[i + subdivisions * 1].z = 0.4472135955f;
				normals[i + subdivisions * 2] = .(0,0,-1);
			}

			let colors = new Color4[subdivisions * 3];
			for	(int i < subdivisions * 3) {
				colors[i] = .(255,255,255);
			}

			let indices = new uint32[subdivisions * (2 * 3) + (subdivisions - 2) * (3)];

			for (int i = 0; i < subdivisions; i++) {
				let index = (uint32)(i % subdivisions);
				let indexPlusOne = (uint32)((i + 1) % subdivisions);
				indices[i * 6 + 0] = index;
				indices[i * 6 + 1] = indexPlusOne;
				indices[i * 6 + 2] = (uint32)subdivisions + index;
				
				indices[i * 6 + 3] = indexPlusOne;
				indices[i * 6 + 4] = (uint32)subdivisions + indexPlusOne;
				indices[i * 6 + 5] = (uint32)subdivisions + index;
			}

			let capTringlesStart = subdivisions * (2 * 3);
			let capTringles = subdivisions - 2;
			for	(int i < capTringles) {
				indices[capTringlesStart + i * 3 + 0] = (uint32)subdivisions * 2;
				indices[capTringlesStart + i * 3 + 1] = (uint32)subdivisions * 2 + (uint32)i + 1;
				indices[capTringlesStart + i * 3 + 2] = (uint32)subdivisions * 2 + (uint32)i + 2;
			}

			cone = new .(vertices, normals, colors, indices);
			cone.MakeInstanced(128);
		}
	}
}
