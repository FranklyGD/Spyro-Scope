using OpenGL;
using System.Collections;
using System;

namespace SpyroScope {
	class Mesh {
		public Vector3[] vertices ~ delete _;
		public Vector3[] normals ~ delete _;
		public Color4[] colors ~ delete _;
		public Vector2[] uvs ~ delete _;

		public uint32[] indices ~ delete _;

		public enum UpdateFlags {
			Vertex = 	1 << 0,
			Color = 	1 << 1,
			UV = 		1 << 2,
			Normal = 	1 << 3,
			Element = 	1 << 4,
		}
		UpdateFlags dirty = 0;

		uint16 maxInstances;

		public bool IsValid { get; private set; }

		uint32 vertexArrayObject,
		vertexBufferObject,
		normalBufferObject,
		colorBufferObject,
		uvBufferObject,
		elementBufferObject,

		instanceBufferObject;

		public this(Vector3[] vertices, Vector2[] uvs, Vector3[] normals, Color4[] colors, uint32[] indices) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = uvs;
			this.indices = indices;

			Init();
		}

		public this(Vector3[] vertices, Vector2[] uvs, Vector3[] normals, Color4[] colors) {
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

		public this(Vector3[] vertices, Vector3[] normals, Color4[] colors, uint32[] indices) {
			this.vertices = vertices;
			this.normals = normals;
			this.colors = colors;
			this.uvs = new .[vertices.Count];
			this.indices = indices;

			Init();
		}

		public this(Vector3[] vertices, Vector3[] normals, Color4[] colors) {
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
				vertices.Count >= 3 &&
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
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), vertices.Ptr, GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.positionAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.positionAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			
			GL.glGenBuffers(1, &normalBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, normalBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), normals.Ptr, GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.normalAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.normalAttributeIndex,
				3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);

			GL.glGenBuffers(1, &colorBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, colorBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Color4), colors.Ptr, GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.colorAttributeIndex);	
			GL.glVertexAttribIPointer(Renderer.colorAttributeIndex,
				4, GL.GL_UNSIGNED_BYTE, 0, null);

			GL.glGenBuffers(1, &uvBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, uvBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector2), uvs.Ptr, GL.GL_STATIC_DRAW); 

			GL.glEnableVertexAttribArray(Renderer.uvAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.uvAttributeIndex,
				2, GL.GL_FLOAT, GL.GL_FALSE, 0, null);

			GL.glGenBuffers(1, &elementBufferObject);
			GL.glBindBuffer(GL.GL_ELEMENT_ARRAY_BUFFER, elementBufferObject);
			GL.glBufferData(GL.GL_ELEMENT_ARRAY_BUFFER, indices.Count * sizeof(uint32), indices.Ptr, GL.GL_STATIC_DRAW);

			Renderer.CheckForErrors();
			GL.glBindVertexArray(0);
		}

		public void MakeInstanced(uint16 maxInstances) {
			GL.glBindVertexArray(vertexArrayObject);

			GL.glGenBuffers(1, &instanceBufferObject);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, instanceBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, maxInstances * sizeof(Instance), null, GL.GL_DYNAMIC_DRAW);

			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+0, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Instance), (void*)(4*0));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+1, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Instance), (void*)(4*4));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+2, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Instance), (void*)(4*8));
			GL.glVertexAttribPointer(Renderer.instanceMatrixAttributeIndex+3, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Instance), (void*)(4*12));

			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+0);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+1);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+2);
			GL.glEnableVertexAttribArray(Renderer.instanceMatrixAttributeIndex+3);

			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+0, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+1, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+2, 1);
			GL.glVertexAttribDivisor(Renderer.instanceMatrixAttributeIndex+3, 1);

			GL.glEnableVertexAttribArray(Renderer.instanceTintAttributeIndex);	
			GL.glVertexAttribPointer(Renderer.instanceTintAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Instance), (void*)(4*16));
			GL.glVertexAttribDivisor(Renderer.instanceTintAttributeIndex, 1);

			GL.glBindVertexArray(0);
			Renderer.CheckForErrors();
			this.maxInstances = maxInstances;
		}

		public void DrawInstances(List<Instance> instances) {
			if (instances?.Count == 0) {
				return;
			}
			
			System.Diagnostics.Debug.Assert(maxInstances > 0, "Instance buffer not initialized yet!");

			GL.glBindVertexArray(vertexArrayObject);
			
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, instanceBufferObject);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, maxInstances * sizeof(Instance), null, GL.GL_DYNAMIC_DRAW);

			for (var offset = 0; offset < instances.Count; offset += maxInstances) {
				let instanceCount = Math.Min(maxInstances, instances.Count - offset);

				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, instanceCount * sizeof(Instance), instances.Ptr + offset);
				GL.glDrawElementsInstanced(GL.GL_TRIANGLES, indices.Count, GL.GL_UNSIGNED_INT, null, instanceCount);
			}

			GL.glBindVertexArray(0);
		}

		public void Update() {
			IsValid =
				vertices.Count >= 3 &&
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
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Color4), null, GL.GL_STATIC_DRAW);
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Color4), &colors[0]);
			}

			if (dirty.HasFlag(.UV)) {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, uvBufferObject);
				GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector2), &uvs[0], GL.GL_STATIC_DRAW); 
				GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector2), &uvs[0]);
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
