using OpenGL;

namespace SpyroScope {
	class StaticMesh {
		public Vector[] vertices ~ delete _;
		public Vector[] normals ~ delete _;
		public Renderer.Color[] colors ~ delete _;

		uint32[] indices ~ delete _;

		uint16 instanceCount;
		//Matrix4[] instanceMatrices = new .[128] ~ delete _;
		public Matrix4[] instanceMatrices = new .[512] ~ delete _;
		public Vector[] instanceColors = new .[512] ~ delete _;

		bool IsValid;

		uint vertexArrayObject,
		vertexBufferObject,
		normalBufferObject,
		colorBufferObject,
		elementBufferObject,

		matrixBufferObject,
		tintBufferObject;

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

			// Per Vertex
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
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex, 1);

			// Per Instanceunsigned int buffer;
		    GL.glGenBuffers(1, &matrixBufferObject);
		    GL.glBindBuffer(GL.GL_ARRAY_BUFFER, matrixBufferObject);
		    GL.glBufferData(GL.GL_ARRAY_BUFFER, 512 * sizeof(Matrix4), &instanceMatrices[0], GL.GL_DYNAMIC_DRAW);

			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+0, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*0));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+1, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*4));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+2, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*8));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+3, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*12));
			
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+0);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+1);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+2);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+3);

			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+0, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+1, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+2, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+3, 1);

			GL.glGenBuffers(1, &tintBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, tintBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 512 * sizeof(Vector), &instanceColors[0], GL.GL_DYNAMIC_DRAW);

			GL.glEnableVertexAttribArray(Renderer.instanceTintAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.instanceTintAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glVertexAttribDivisor(Renderer.instanceTintAttributeIndex, 1);


			GL.glGenBuffers(1, &elementBufferObject);
			GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
			GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, indices.Count * sizeof(uint32), &indices[0], GL.GL_STATIC_DRAW);

			GL.glBindVertexArray(0);
			Renderer.CheckForErrors();
		}

		public void Draw(Renderer renderer) {
			if (!IsValid) {
				return;
			}

			// draw mesh
			QueueInstance(renderer);
			DrawInstances();
		}

		public void QueueInstance(Renderer renderer) {
			if (!IsValid) {
				return;
			}

			instanceMatrices[instanceCount] = renderer.model;
			instanceColors[instanceCount] = renderer.tint;

			instanceCount++;
			if (instanceCount >= 512) {
				DrawInstances();
			}
		}

		public void DrawInstances() {
			if (instanceCount == 0) {
				return;
			}

			GL.glBindVertexArray(vertexArrayObject);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, matrixBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 2048 * sizeof(Matrix4), null, GL.GL_DYNAMIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, instanceCount * sizeof(Matrix4), &instanceMatrices[0]);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, tintBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 2048 * sizeof(Vector), null, GL.GL_DYNAMIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, instanceCount * sizeof(Vector), &instanceColors[0]);

			GL.glDrawElementsInstanced(GL.GL_TRIANGLES, indices.Count, GL.GL_UNSIGNED_INT, null, instanceCount);
			GL.glBindVertexArray(0);

			instanceCount = 0;
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
