using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class RenderJob {
		public Mesh mesh;
		public Texture texture;

		List<Instance> instances = new .() ~ delete _;

		public this(Mesh mesh, Texture texture) {
			this.mesh = mesh;
			this.texture = texture;
		}

		public void AddInstance(Matrix4 matrix, Vector3 tint) {
			if (mesh.IsValid) {
				instances.Add(Instance{matrix = matrix, tint = tint});
			}
		}

		public void Execute() {
			texture.Bind();
			mesh.DrawInstances(instances);
		}
	}
}
