using OpenGL;

namespace SpyroScope {
	class Mesh {
		public Vector3[] vertices ~ delete _;
		public Vector3[] normals ~ delete _;
		public Renderer.Color4[] colors ~ delete _;
		public float[][2] uvs ~ delete _;

		public uint32[] indices ~ delete _;

		public enum UpdateFlags {
			Vertex = 	1 << 0,
			Color = 	1 << 1,
			UV = 		1 << 2,
			Normal = 	1 << 3,
			Element = 	1 << 4,
		}
		UpdateFlags dirty = 0;

		uint16 instanceCount;
		//Matrix4[] instanceMatrices = new .[128] ~ delete _;
		public Matrix4[] instanceMatrices = new .[512] ~ delete _;
		public Vector3[] instanceColors = new .[512] ~ delete _;

		bool IsValid;

		uint32 vertexArrayObject,
		vertexBufferObject,
		normalBufferObject,
		colorBufferObject,
		uvBufferObject,
		elementBufferObject,

		matrixBufferObject,
		tintBufferObject;

		public this(Vector3[] vertices, float[][2] uvs, Vector3[] normals, Renderer.Color4[] colors, uint32[] indices) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = uvs;
			this.indices = indices;

			Init();
		}

		public this(Vector3[] vertices, float[][2] uvs, Vector3[] normals, Renderer.Color4[] colors) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = uvs;
			this.indices = new uint32[vertices.Count];
			for (int i < vertices.Count) {
				indices[i] = (uint32)i;
			}

			Init();
		}

		public this(Vector3[] vertices, Vector3[] normals, Renderer.Color4[] colors, uint32[] indices) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = new .[vertices.Count];
			this.indices = indices;

			Init();
		}

		public this(Vector3[] vertices, Vector3[] normals, Renderer.Color4[] colors) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = new .[vertices.Count];
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
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), &vertices[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.positionAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.positionAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			
			GL.glGenBuffers(1, &normalBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, normalBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), &normals[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.normalAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.normalAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);

			GL.glGenBuffers(1, &colorBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, colorBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Renderer.Color4), &colors[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.colorAttributeIndex);	
			GL.glVertexAttribIPointer(Renderer.colorAttributeIndex,
				4, GL.GL_UNSIGNED_BYTE, 0, null);

			GL.glGenBuffers(1, &uvBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, uvBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(float[2]), &uvs[0], GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.uvAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.uvAttributeIndex,
				2, GL.GL_FLOAT, GL.GL_FALSE, 0, null);

			// Per Instance
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
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 512 * sizeof(Vector3), &instanceColors[0], GL.GL_DYNAMIC_DRAW);

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

		public void Draw() {
			if (!IsValid) {
				return;
			}

			// draw mesh
			QueueInstance();
			DrawInstances();
		}

		public void QueueInstance() {
			if (!IsValid) {
				return;
			}

			instanceMatrices[instanceCount] = Renderer.model;
			instanceColors[instanceCount] = Renderer.tint;

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
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 512 * sizeof(Matrix4), null, GL.GL_DYNAMIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, instanceCount * sizeof(Matrix4), &instanceMatrices[0]);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, tintBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, 512 * sizeof(Vector3), null, GL.GL_DYNAMIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, instanceCount * sizeof(Vector3), &instanceColors[0]);

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

			if (dirty.HasFlag(.Vertex)) {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, vertexBufferObject);
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), null, GL.GL_STATIC_DRAW);
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector3), &vertices[0]);
			}
			
			if (dirty.HasFlag(.Normal)) {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, normalBufferObject);
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), null, GL.GL_STATIC_DRAW); 
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector3), &normals[0]);
			}

			if (dirty.HasFlag(.Color)) {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, colorBufferObject);
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Renderer.Color4), null, GL.GL_STATIC_DRAW);
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Renderer.Color4), &colors[0]);
			}

			if (dirty.HasFlag(.UV)) {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, uvBufferObject);
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(float[2]), &uvs[0], GL.GL_STATIC_DRAW); 
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(float[2]), &uvs[0]);
			}

			if (dirty.HasFlag(.Element)) {
				GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
				GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, indices.Count * sizeof(uint32), &indices[0], GL.GL_STATIC_DRAW); 
				GL.glBufferSubData(GL.GL_ELEMENT_ARRAY_BUFFER, 0, indices.Count * sizeof(uint32), &indices[0]);
			}

			GL.glBindVertexArray(0);

			dirty = 0;
		}

		public void SetDirty(UpdateFlags flags = (.)~0) {
			dirty |= flags;
		}
	}
}
