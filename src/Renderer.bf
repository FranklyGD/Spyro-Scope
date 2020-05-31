using OpenGL;
using SDL2;
using System;
using System.Diagnostics;

namespace SpyroScope {
	class Renderer {
		SDL.Window* window;
		SDL.SDL_GLContext context;

		public struct Color {
			uint8 r,g,b;
			public this(uint8 r, uint8 g, uint8 b) {
				this.r = r;
				this.g = g;
				this.b = b;
			}
		}

		uint vertexArrayObject;
		Buffer<Vector> positions;
		Buffer<Vector> normals;
		Buffer<Color> colors;
		uint32 vertexCount;

		uint vertexShader;
		uint fragmentShader;
		uint program;

		public int uniformModelMatrixIndex; // Object Transform
		public Matrix4 model = .Identity;
		public int uniformViewMatrixIndex; // Camera Inverse Transform
		public Matrix4 view = .Identity;
		public int uniformProjectionMatrixIndex; // Camera Perspective
		public Matrix4 projection = .Identity;

		struct Buffer<T> {
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

		public this(SDL.Window* window) {
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
			positions = .(0xC000);
			let positionIndex = FindProgramAttribute(program, "vertexPosition");
			GL.glVertexAttribPointer(positionIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(positionIndex);

			// Normals Buffer
			normals = .(0xC000);
			let normalIndex = FindProgramAttribute(program, "vertexNormal");
			GL.glVertexAttribPointer(normalIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(normalIndex);

			// Color Buffer
			colors = .(0xC000);
			let colorIndex = FindProgramAttribute(program, "vertexColor");
			GL.glVertexAttribIPointer(colorIndex, 3, GL.GL_UNSIGNED_BYTE, 0, null);
			GL.glEnableVertexAttribArray(colorIndex);

			// Get Uniforms
			uniformModelMatrixIndex = FindProgramUniform(program, "model");
			uniformViewMatrixIndex = FindProgramUniform(program, "view");
			uniformProjectionMatrixIndex = FindProgramUniform(program, "projection");

			this.window = window;

			
			GL.glEnable(GL.GL_FRAMEBUFFER_SRGB); 
			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glEnable(GL.GL_CULL_FACE);
			GL.glCullFace(GL.GL_BACK);
			GL.glFrontFace(GL.GL_CW);

			CheckForErrors();
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

		//[Optimize]
		public void PushTriangle(Vector p0, Vector p1, Vector p2,
			Color c0, Color c1, Color c2) {
			if (vertexCount + 3 > 0xC000) {
				Draw();
			}

			let normal = Vector.Cross(p2 - p0, p1 - p0);

			PushPoint(p0, normal, c0);
			PushPoint(p1, normal, c1);
			PushPoint(p2, normal, c2);
		}

		public void SetView(Vector position, Matrix basis) {
			view = basis * Matrix4.Translation(-position);
			GL.glUniformMatrix4fv(uniformViewMatrixIndex, 1, GL.GL_FALSE, (float*)&view);
		}

		public void SetPerspectiveProjection(float degreesFoV, float aspect, float near, float far) {
			projection = .Perspective(degreesFoV / 180 * 3.14f, aspect, near, far);
			GL.glUniformMatrix4fv(uniformProjectionMatrixIndex, 1, GL.GL_FALSE, (float*)&projection);
		}

		public void Draw() {
			// Send transform matrices
			GL.glUniformMatrix4fv(uniformModelMatrixIndex, 1, GL.GL_FALSE, (float*)&model);

			// Flush
			GL.glMemoryBarrier(GL.GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT);
			GL.glDrawArrays(GL.GL_TRIANGLES, 0, (int32)vertexCount);

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

		void CheckForErrors() {
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
