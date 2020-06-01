using OpenGL;

namespace SpyroScope {
	class StaticMesh {
		Vector[] vertices ~ delete _;
		Vector[] normals ~ delete _;
		Renderer.Color[] colors ~ delete _;

		uint32[] indices ~ delete _;

		uint vertexArrayObject,
		vertexBufferObject,
		normalBufferObject,
		colorBufferObject,
		elementBufferObject;

		public this(Vector[] vertices, Vector[] normals, Renderer.Color[] colors, uint32[] indices) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.indices = indices;

			Init();
		}

		public this(Vector[] vertices, Vector[] normals, Renderer.Color[] colors) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.indices = new uint32[vertices.Count];
			for (int i < vertices.Count) {
				indices[i] = (uint32)i;
			}

			Init();
		}

		void Init() {
			GL.glGenVertexArrays(1, &vertexArrayObject);
			GL.glBindVertexArray(vertexArrayObject);
			
			let vertexCount = vertices.Count;

			GL.glGenBuffers(1, &vertexBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vertexBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector), &vertices[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.positionAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.positionAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			
			GL.glGenBuffers(1, &normalBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, normalBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector), &normals[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.normalAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.normalAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);

			GL.glGenBuffers(1, &colorBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, colorBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Renderer.Color), &colors[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.colorAttributeIndex);	
			GL.glVertexAttribIPointer(Renderer.colorAttributeIndex,
				3, GL.GL_UNSIGNED_BYTE, 0, null);

			GL.glGenBuffers(1, &elementBufferObject);
			GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
			GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, indices.Count * sizeof(uint32), &indices[0], GL.GL_STATIC_DRAW);

			GL.glBindVertexArray(0);
			Renderer.CheckForErrors();
		}

		public void Draw() {
			// draw mesh
			GL.glBindVertexArray(vertexArrayObject);
			GL.glDrawElements(GL.GL_TRIANGLES, indices.Count, GL.GL_UNSIGNED_INT, null);
			GL.glBindVertexArray(0);
		}
	}
}
