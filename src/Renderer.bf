using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	class Renderer {
		SDL.Window* window;
		SDL.SDL_GLContext context;

		public struct Color {
			public uint8 r,g,b;
			public this(uint8 r, uint8 g, uint8 b) {
				this.r = r;
				this.g = g;
				this.b = b;
			}
		}

		public struct Color4 {
			public uint8 r,g,b,a;
			public this(uint8 r, uint8 g, uint8 b, uint8 a) {
				this.r = r;
				this.g = g;
				this.b = b;
				this.a = a;
			}
		}

		const uint maxGenericBufferLength = 0x6000;
		uint vertexArrayObject;
		Buffer<Vector> positions;
		Buffer<Vector> normals;
		Buffer<Color> colors;
		DrawQueue[maxGenericBufferLength] drawQueue;
		DrawQueue* lastDrawQueue;
		
		uint32 vertexCount;

		uint vertexShader;
		uint fragmentShader;
		uint program;

		public static uint positionAttributeIndex;
		public static uint normalAttributeIndex;
		public static uint colorAttributeIndex;

		public int uniformModelMatrixIndex; // Object Transform
		public Matrix4 model = .Identity;
		public int uniformViewMatrixIndex; // Camera Inverse Transform
		public Matrix4 view = .Identity;
		public int uniformProjectionMatrixIndex; // Camera Perspective
		public Matrix4 projection = .Identity;
		public int uniformTintIndex; // Overall Tint Color
		public float[3] tint;
		public int uniformZdepthOffsetIndex; // Z-depth Offset (mainly for pushing the wireframe forward to avoid Z-fighting)
		
		public struct Buffer<T> {
			public uint obj;
			public T* map;
			public readonly int bufferLength;

			public this(int bufferLength) {
				obj = 0;

				// Generate
				GL.glGenBuffers(1, &obj);
				// Bind
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, obj);

				// Calculate Buffer size
				let item_size = sizeof(T);
				let buffer_size = item_size * bufferLength;

				let access = GL.GL_MAP_WRITE_BIT | GL.GL_MAP_PERSISTENT_BIT;

				GL.glBufferStorage(GL.GL_ARRAY_BUFFER, buffer_size, null, access);
				map = (T*)GL.glMapBufferRange(GL.GL_ARRAY_BUFFER, 0, buffer_size, access);

				for (int i < bufferLength) {
					*(map + i) = default;
				}

				this.bufferLength = bufferLength;
			}

			//[Optimize]
			public void Set(uint32 index, T value) mut {
				if (index >= bufferLength) {
					return;
				}

				*(map + index) = value;
			}

			public void Dispose() mut {
				GL.glBindBuffer(GL.GL_ARRAY_BUFFER, obj);
				GL.glUnmapBuffer(GL.GL_ARRAY_BUFFER);
				GL.glDeleteBuffers(1, &obj);
			}
		}

		struct DrawQueue {
			public uint16 type;
			public uint16 count;

			public this(uint16 drawType, uint16 vertexCount) {
				type = drawType;
				count = vertexCount;
			}
		}

		public this(SDL.Window* window) {
			drawQueue[0].type = 0;
			drawQueue[0].count = 0;
			lastDrawQueue = &drawQueue[0];
 
			SDL.GL_SetAttribute(.GL_CONTEXT_MAJOR_VERSION, (.)4);
			SDL.GL_SetAttribute(.GL_CONTEXT_MINOR_VERSION, (.)6);
			SDL.GL_SetAttribute(.GL_CONTEXT_FLAGS, (.)SDL.SDL_GLContextFlags.GL_CONTEXT_DEBUG_FLAG);

			context = SDL.GL_CreateContext(window);
			GL.Init(=> SdlGetProcAddress);

			Clear();
			SDL.GL_SwapWindow(window);

			// Compile shaders during run-time
			vertexShader = CompileShader("shaders/vertex.glsl", GL.GL_VERTEX_SHADER);
			fragmentShader = CompileShader("shaders/fragment.glsl", GL.GL_FRAGMENT_SHADER);

			// Link and use the shader program
			program = LinkProgram(vertexShader, fragmentShader);
			GL.glUseProgram(program);

			// Create Buffers/Arrays

			vertexArrayObject = 0;
			GL.glGenVertexArrays(1, &vertexArrayObject);
			GL.glBindVertexArray(vertexArrayObject);

			// Position Buffer
			positions = .(maxGenericBufferLength);
			positionAttributeIndex = FindProgramAttribute(program, "vertexPosition");
			GL.glVertexAttribPointer(positionAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(positionAttributeIndex);

			// Normals Buffer
			normals = .(maxGenericBufferLength);
			normalAttributeIndex = FindProgramAttribute(program, "vertexNormal");
			GL.glVertexAttribPointer(normalAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(normalAttributeIndex);

			// Color Buffer
			colors = .(maxGenericBufferLength);
			colorAttributeIndex = FindProgramAttribute(program, "vertexColor");
			GL.glVertexAttribIPointer(colorAttributeIndex, 3, GL.GL_UNSIGNED_BYTE, 0, null);
			GL.glEnableVertexAttribArray(colorAttributeIndex);

			// Get Uniforms
			uniformModelMatrixIndex = FindProgramUniform(program, "model");
			uniformViewMatrixIndex = FindProgramUniform(program, "view");
			uniformProjectionMatrixIndex = FindProgramUniform(program, "projection");
			uniformZdepthOffsetIndex = FindProgramUniform(program, "zdepthOffset");
			
			uniformTintIndex = FindProgramUniform(program, "tint");

			this.window = window;

			GL.glEnable(GL.GL_FRAMEBUFFER_SRGB); 
			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glEnable(GL.GL_CULL_FACE);
			GL.glCullFace(GL.GL_BACK);
			GL.glFrontFace(GL.GL_CW);

			CheckForErrors();

			PrimitiveShape.Init();
		}

		public ~this() {
			GL.glDeleteVertexArrays(1, &vertexArrayObject);
			GL.glDeleteShader(vertexShader);
			GL.glDeleteShader(fragmentShader);
			GL.glDeleteProgram(program);

			positions.Dispose();
			normals.Dispose();
			colors.Dispose();
		}

		uint CompileShader(String sourcePath, uint shaderType) {
			let shader = GL.glCreateShader(shaderType);

			String source = scope .();
			System.IO.File.ReadAllText(sourcePath, source, true);
			char8* sourceData = source.Ptr;

			GL.glShaderSource(shader, 1, &sourceData, null);
			GL.glCompileShader(shader);

			int status = GL.GL_FALSE;
			GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS, &status);
			Debug.Assert(status == GL.GL_TRUE, "Shader compilation failed");

			return shader;
		}

		uint LinkProgram(uint vertex, uint fragment) {
			let program = GL.glCreateProgram();

			GL.glAttachShader(program, vertex);
			GL.glAttachShader(program, fragment);

			GL.glLinkProgram(program);

			int status = GL.GL_FALSE;
			GL.glGetProgramiv(program, GL.GL_LINK_STATUS, &status);
			Debug.Assert(status == GL.GL_TRUE, "Program linking failed");

			return program;
		}

		uint FindProgramAttribute(uint program, String attribute) {
			let index = GL.glGetAttribLocation(program, attribute.Ptr);

			Debug.Assert(index >= 0, "Attribute not found");

			return (uint)index;
		}

		int FindProgramUniform(uint program, String attribute) {
			let index = GL.glGetUniformLocation(program, attribute.Ptr);

			Debug.Assert(index >= 0, "Uniform not found");

			return index;
		}

		public void PushPoint(Vector position, Vector normal, Color color) {
			positions.Set(vertexCount, position);
			normals.Set(vertexCount, normal);
			colors.Set(vertexCount, color);

			vertexCount++;
		}

		public void DrawLine(Vector p0, Vector p1,
			Color c0, Color c1) {
			if (vertexCount + 2 > maxGenericBufferLength) {
				Draw();
			}
				
			let normal = Vector(0,0,1);

			PushPoint(p0, normal, c0);
			PushPoint(p1, normal, c1);

			if (lastDrawQueue.type == GL.GL_LINES) {
				lastDrawQueue.count += 2;
			} else {
				lastDrawQueue++;
				lastDrawQueue.type = GL.GL_LINES;
				lastDrawQueue.count = 2;
			}
		}

		public void DrawTriangle(Vector p0, Vector p1, Vector p2,
			Color c0, Color c1, Color c2) {
			if (vertexCount + 3 > maxGenericBufferLength) {
				Draw();
			}

			let normal = Vector.Cross(p2 - p0, p1 - p0);

			PushPoint(p0, normal, c0);
			PushPoint(p1, normal, c1);
			PushPoint(p2, normal, c2);

			if (lastDrawQueue.type == GL.GL_TRIANGLES) {
				lastDrawQueue.count += 3;
			} else {
				lastDrawQueue++;
				lastDrawQueue.type = GL.GL_TRIANGLES;
				lastDrawQueue.count = 3;
			}
		}

		public void SetModel(Vector position, Matrix basis) {
			model = Matrix4.Translation(position) * basis;
			GL.glUniformMatrix4fv(uniformModelMatrixIndex, 1, GL.GL_FALSE, (float*)&model);
		}

		public void SetView(Vector position, Matrix basis) {
			view = basis.Transpose() * Matrix4.Translation(-position);
			GL.glUniformMatrix4fv(uniformViewMatrixIndex, 1, GL.GL_FALSE, (float*)&view);
		}

		public void SetPerspectiveProjection(float degreesFoV, float aspect, float near, float far) {
			projection = .Perspective(degreesFoV / 180 * 3.14f, aspect, near, far);
			GL.glUniformMatrix4fv(uniformProjectionMatrixIndex, 1, GL.GL_FALSE, (float*)&projection);
		}

		public void SetTint(Color tint) {
			this.tint = .((float)tint.r / 255, (float)tint.g / 255, (float)tint.b / 255);
			GL.glUniform3fv(uniformTintIndex, 1, &this.tint[0]);
		}

		public void BeginWireframe() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_LINE);
			GL.glUniform1f(uniformZdepthOffsetIndex, 0.5f); // Push the lines a little forward
		}

		public void BeginSolid() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);
			GL.glUniform1f(uniformZdepthOffsetIndex, 0); // Reset depth offset
		}

		public void Draw() {
			SetModel(.Zero, .Identity);
			SetTint(.(255,255,255));

			GL.glBindVertexArray(vertexArrayObject);

			// Flush
			GL.glMemoryBarrier(GL.GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT);

			uint32 offset = 0;
			DrawQueue* drawSlot = &drawQueue[0] + 1; 
			while (drawSlot <= lastDrawQueue) {
				GL.glDrawArrays(drawSlot.type, offset, drawSlot.count);
				offset += drawSlot.count;
				drawSlot++;
			}

			lastDrawQueue = &drawQueue;
			vertexCount = 0;
		}

		public void Sync() {
			// Wait for GPU
			let sync = GL.glFenceSync(GL.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

			while (GL.glClientWaitSync(sync, GL.GL_SYNC_FLUSH_COMMANDS_BIT, 0) == GL.GL_TIMEOUT_EXPIRED) {
				// Insert something here to do while waiting for draw to finish
				SDL.Delay(0);
			}	
		}

		public void Display() {
			SDL.GL_SwapWindow(window);
		}

		public void Clear() {
			GL.glClearColor(0,0,0,1);
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
		}

		public static void CheckForErrors() {
			char8[] buffer = scope .[1024];
			uint severity = 0;
			uint source = 0;
			int messageSize = 0;
			uint mType = 0;
			uint id = 0;

			bool error = false;

			while (GL.glGetDebugMessageLog(1, 1024, &source, &mType, &id, &severity, &messageSize, &buffer[0]) > 0) {
				if (severity == GL.GL_DEBUG_SEVERITY_HIGH) {
					error = true;
				}

				String string = scope .(buffer, 0, 1024);
				Debug.WriteLine(scope String() .. AppendF("OpenGL: {}", string));
			}

			if (error) {
				Debug.FatalError("Fatal OpenGL Error");
			}
		}
	}
}
