using OpenGL;

namespace SpyroScope {
	class StaticMesh {
		public Vector[] vertices ~ delete _;
		public Vector[] normals ~ delete _;
		public Renderer.Color[] colors ~ delete _;

		uint32[] indices ~ delete _;

		bool IsValid;

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

		public ~this() {
			GL.glDeleteVertexArrays(1, &vertexArrayObject);
		}

		void Init() {
			IsValid =
				vertices.Count > 3 &&
				vertices.Count == normals.Count &&
				vertices.Count == colors.Count &&
				indices.Count % 3 == 0;

			if (!IsValid) {
				return;
			}

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
			if (!IsValid) {
				return;
			}

			// draw mesh
			GL.glBindVertexArray(vertexArrayObject);
			GL.glDrawElements(GL.GL_TRIANGLES, indices.Count, GL.GL_UNSIGNED_INT, null);
			GL.glBindVertexArray(0);
		}

		public void Update() {
			IsValid =
				vertices.Count > 3 &&
				vertices.Count == normals.Count &&
				vertices.Count == colors.Count &&
				indices.Count % 3 == 0;

			if (!IsValid) {
				return;
			}

			let vertexCount = vertices.Count;
			GL.glBindVertexArray(vertexArrayObject);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vertexBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector), null, GL.GL_STATIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector), &vertices[0]);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, normalBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector), null, GL.GL_STATIC_DRAW); 
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector), &normals[0]);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, colorBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Renderer.Color), null, GL.GL_STATIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Renderer.Color), &colors[0]);

			GL.glBindVertexArray(0);
		}
	}
}
