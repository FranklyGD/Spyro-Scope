using OpenGL;
using SDL2;
using System;
using System.Collections;
using System.Diagnostics;

namespace SpyroScope {
	static class Renderer {
		static SDL.Window* window;
		static SDL.SDL_GLContext context;

		static bool useSync;

		public struct Color {
			public uint8 r,g,b;
			public this(uint8 r, uint8 g, uint8 b) {
				this.r = r;
				this.g = g;
				this.b = b;
			}

			public static implicit operator Color(Color4 color) {
				return .(color.r, color.g, color.b);
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

			public this(uint8 r, uint8 g, uint8 b) {
				this.r = r;
				this.g = g;
				this.b = b;
				this.a = 255;
			}

			public static implicit operator Color4(Color color) {
				return .(color.r, color.g, color.b, 255);
			}
		}

		const uint maxGenericBufferLength = 0x6000;
		static uint vertexArrayObject;
		static Buffer<Vector> positions;
		static Buffer<Vector> normals;
		static Buffer<Color4> colors;
		static Buffer<(float,float)> uvs;
		static DrawQueue[maxGenericBufferLength] drawQueue;
		static DrawQueue* startDrawQueue, lastDrawQueue;
		
		static uint32 vertexCount, vertexOffset;

		static uint vertexShader;
		static uint fragmentShader;
		static uint program;

		// Shader Inputs
		public static uint positionAttributeIndex;
		public static uint normalAttributeIndex;
		public static uint colorAttributeIndex;
		public static uint uvAttributeIndex;

		public static uint instanceMatrixAttributeIndex;
		public static uint instanceTintAttributeIndex;

		// Shader Uniforms
		public static Matrix4 model = .Identity;
		public static int uniformViewMatrixIndex; // Camera Inverse Transform
		public static Matrix4 view = .Identity;
		public static Vector viewPosition = .Zero;
		public static Matrix viewBasis = .Identity;
		public static int uniformProjectionMatrixIndex; // Camera Perspective
		public static Matrix4 projection = .Identity;

		public static Vector tint = .(1,1,1);
		public static int uniformZdepthOffsetIndex; // Z-depth Offset (mainly for pushing the wireframe forward to avoid Z-fighting)
		public static int uniformRetroShadingIndex; // Change shading from modern to emulated
		public static Texture whiteTexture ~ delete _;

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
			public uint8 texture;

			public this(uint16 drawType, uint16 vertexCount, uint8 textureObject) {
				type = drawType;
				count = vertexCount;
				texture = textureObject;
			}
		}

		public static void Init(SDL.Window* window) {
			drawQueue[0].type = 0;
			drawQueue[0].count = 0;
			startDrawQueue = lastDrawQueue = &drawQueue[0];

			// Initialize OpenGL
			SDL.GL_SetAttribute(.GL_CONTEXT_FLAGS, (uint32)SDL.SDL_GLContextFlags.GL_CONTEXT_DEBUG_FLAG);

			context = SDL.GL_CreateContext(window);
			GL.Init(=> SdlGetProcAddress);

			int32 majorVersion = ?;
			int32 minorVersion = ?;
			GL.glGetIntegerv(GL.GL_MAJOR_VERSION, (.)&majorVersion);
			GL.glGetIntegerv(GL.GL_MINOR_VERSION, (.)&minorVersion);

			if (majorVersion > 3 || majorVersion == 3 && minorVersion > 1) {
				useSync = true;
			}

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
			GL.glVertexAttribIPointer(colorAttributeIndex, 4, GL.GL_UNSIGNED_BYTE, 0, null);
			GL.glEnableVertexAttribArray(colorAttributeIndex);

			// UV Buffer
			uvs = .(maxGenericBufferLength);
			uvAttributeIndex = FindProgramAttribute(program, "vertexTextureMapping");
			GL.glVertexAttribPointer(uvAttributeIndex, 2, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(uvAttributeIndex);

			uint tempBufferID = ?;
			GL.glGenBuffers(1, &tempBufferID);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, tempBufferID);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(Matrix4), &model, GL.GL_STATIC_DRAW);
			
			instanceMatrixAttributeIndex = FindProgramAttribute(program, "instanceModel");

			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+0, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*0));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+1, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*4));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+2, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*8));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+3, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4), (void*)(4*12));

			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+0);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+1);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+2);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+3);

			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+0, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+1, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+2, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+3, 1);

			GL.glGenBuffers(1, &tempBufferID);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, tempBufferID);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(Vector), &tint, GL.GL_STATIC_DRAW);

			instanceTintAttributeIndex = FindProgramAttribute(program, "instanceTint");
			GL.glVertexAttribPointer(instanceTintAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(instanceTintAttributeIndex);
			GL.glVertexAttribDivisor(instanceTintAttributeIndex, 1);

			// Get Uniforms
			uniformViewMatrixIndex = FindProgramUniform(program, "view");
			uniformProjectionMatrixIndex = FindProgramUniform(program, "projection");
			uniformZdepthOffsetIndex = FindProgramUniform(program, "zdepthOffset");
			uniformRetroShadingIndex = FindProgramUniform(program, "retroShading");

			// Create Default Texture

			var whiteTextureData = Color(255,255,255);
			whiteTexture = new .(1, 1, GL.GL_RGB, GL.GL_RGB, &whiteTextureData);

			Renderer.window = window;

			GL.glEnable(GL.GL_FRAMEBUFFER_SRGB); 
			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glEnable(GL.GL_BLEND);
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);

			GL.glEnable(GL.GL_CULL_FACE);
			GL.glCullFace(GL.GL_BACK);
			GL.glFrontFace(GL.GL_CW);

			CheckForErrors();

			PrimitiveShape.Init();
		}

		public static void Unload() {
			GL.glDeleteVertexArrays(1, &vertexArrayObject);
			GL.glDeleteShader(vertexShader);
			GL.glDeleteShader(fragmentShader);
			GL.glDeleteProgram(program);

			positions.Dispose();
			normals.Dispose();
			colors.Dispose();
		}

		static uint CompileShader(String sourcePath, uint shaderType) {
			let shader = GL.glCreateShader(shaderType);

			String source = scope .();
			System.IO.File.ReadAllText(sourcePath, source, true);
			char8* sourceData = source.Ptr;

			GL.glShaderSource(shader, 1, &sourceData, null);
			GL.glCompileShader(shader);

			int status = GL.GL_FALSE;
			GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS, &status);
			if (status == GL.GL_FALSE) {
				int length = 0;
				GL.glGetShaderiv(shader, GL.GL_INFO_LOG_LENGTH, &length);

				String message = scope String();
				let ptr = message.PrepareBuffer(length);
				GL.glGetShaderInfoLog(shader, length, null, ptr);

				Debug.Write(message);
				Debug.FatalError("Shader compilation failed");
			}

			return shader;
		}

		static uint LinkProgram(uint vertex, uint fragment) {
			let program = GL.glCreateProgram();

			GL.glAttachShader(program, vertex);
			GL.glAttachShader(program, fragment);

			GL.glLinkProgram(program);

			int status = GL.GL_FALSE;
			GL.glGetProgramiv(program, GL.GL_LINK_STATUS, &status);
			Debug.Assert(status == GL.GL_TRUE, "Program linking failed");

			return program;
		}

		static uint FindProgramAttribute(uint program, String attribute) {
			let index = GL.glGetAttribLocation(program, attribute.Ptr);

			Debug.Assert(index >= 0, "Attribute not found");

			return (uint)index;
		}

		static int FindProgramUniform(uint program, String attribute) {
			let index = GL.glGetUniformLocation(program, attribute.Ptr);

			Debug.Assert(index >= 0, "Uniform not found");

			return index;
		}

		public static void PushPoint(Vector position, Vector normal, Color4 color, (float,float) uv) {
			if (vertexCount >= maxGenericBufferLength) {
				return;
			}

			positions.Set(vertexCount, position);
			normals.Set(vertexCount, normal);
			colors.Set(vertexCount, color);
			uvs.Set(vertexCount, uv);

			vertexCount++;
		}

		public static void DrawLine(Vector p0, Vector p1,
			Color4 c0, Color4 c1) {
			if (vertexCount + 2 > maxGenericBufferLength) {
				Draw();
			}
				
			let normal = Vector(0,0,1);

			PushPoint(p0, normal, c0, (0,0));
			PushPoint(p1, normal, c1, (0,0));

			if (lastDrawQueue.type == GL.GL_LINES) {
				lastDrawQueue.count += 2;
			} else {
				lastDrawQueue++;
				lastDrawQueue.type = GL.GL_LINES;
				lastDrawQueue.count = 2;
				lastDrawQueue.texture = (uint8)whiteTexture.textureObjectID;
			}
		}

		public static void DrawTriangle(Vector p0, Vector p1, Vector p2,
			Color4 c0, Color4 c1, Color4 c2,
			(float,float) uv0, (float,float) uv1, (float,float) uv2, uint textureObject) {
			if (vertexCount + 3 > maxGenericBufferLength) {
				Draw();
			}

			let normal = Vector.Cross(p1 - p0, p2 - p0);

			PushPoint(p0, normal, c0, uv0);
			PushPoint(p1, normal, c1, uv1);
			PushPoint(p2, normal, c2, uv2);

			if (lastDrawQueue.type == GL.GL_TRIANGLES && lastDrawQueue.texture == textureObject) {
				lastDrawQueue.count += 3;
			} else {
				lastDrawQueue++;
				lastDrawQueue.type = GL.GL_TRIANGLES;
				lastDrawQueue.count = 3;
				lastDrawQueue.texture = (.)textureObject;
			}
		}

		public static void DrawTriangle(Vector p0, Vector p1, Vector p2,
			Color4 c0, Color4 c1, Color4 c2) {
			DrawTriangle(p0, p1, p2, c0, c1, c2, (0,0), (0,0), (0,0), whiteTexture.textureObjectID);
		}

		public static void SetModel(Vector position, Matrix basis) {
			model = Matrix4.Translation(position) * basis;
		}

		public static void SetView(Vector position, Matrix basis) {
			viewPosition = position;
			viewBasis = basis;
			view = basis.Transpose() * Matrix4.Translation(-position);
			GL.glUniformMatrix4fv(uniformViewMatrixIndex, 1, GL.GL_FALSE, (float*)&view);
		}

		public static void SetProjection(Matrix4 projection) {
			Renderer.projection = projection;
			GL.glUniformMatrix4fv(uniformProjectionMatrixIndex, 1, GL.GL_FALSE, (float*)&Renderer.projection);
		}

		public static void SetTint(Color tint) {
			Renderer.tint = .((float)tint.r / 255, (float)tint.g / 255, (float)tint.b / 255);
			//GL.glUniform3fv(uniformTintIndex, 1, &this.tint[0]);
		}

		public static void BeginWireframe() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_LINE);
			GL.glUniform1f(uniformZdepthOffsetIndex, -0.2f); // Push the lines a little forward
		}

		public static void BeginSolid() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);
			GL.glUniform1f(uniformZdepthOffsetIndex, 0); // Reset depth offset
		}

		public static void BeginRetroShading() {
			GL.glUniform1f(uniformRetroShadingIndex, 1);
		}

		public static void BeginDefaultShading() {
			GL.glUniform1f(uniformRetroShadingIndex, 0);
		}

		public static void Draw() {
			GL.glBindVertexArray(vertexArrayObject);

			startDrawQueue++;
			while (startDrawQueue <= lastDrawQueue) {
				GL.glBindTexture(GL.GL_TEXTURE_2D, startDrawQueue.texture);
				GL.glDrawArrays(startDrawQueue.type, vertexOffset, startDrawQueue.count);
				vertexOffset += startDrawQueue.count;
				startDrawQueue++;
			}
			
			startDrawQueue.count = startDrawQueue.type = 0;
			lastDrawQueue = startDrawQueue;
		}

		public static void Sync() {
			// Wait for GPU
			if (useSync) {
				var sync = GL.glFenceSync(GL.GL_SYNC_GPU_COMMANDS_COMPLETE, 0);

				while (GL.glClientWaitSync(sync, GL.GL_SYNC_FLUSH_COMMANDS_BIT, 0) == GL.GL_TIMEOUT_EXPIRED) {
					// Insert something here to do while waiting for draw to finish
					SDL.Delay(0);
				}
				GL.glDeleteSync(sync);
			} else {
				GL.glFinish();
			}
		}

		public static void Display() {
			SDL.GL_SwapWindow(window);
		}

		public static void Clear() {
			GL.glClearColor(0,0,0,1);
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			startDrawQueue = lastDrawQueue = &drawQueue[0];
			vertexCount = vertexOffset = 0;
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
