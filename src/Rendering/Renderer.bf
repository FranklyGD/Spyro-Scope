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
		static bool enableDebug;

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

			public static Color Lerp(Color bg, Color fg, float alpha) {
				return .((.)Math.Lerp(bg.r, fg.r, alpha), (.)Math.Lerp(bg.g, fg.g, alpha), (.)Math.Lerp(bg.b, fg.b, alpha));
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
		static uint32 vertexArrayObject;
		static uint32[6] bufferID = .(?);
		static Vector3[maxGenericBufferLength] positions;
		static Vector3[maxGenericBufferLength] normals;
		static Color4[maxGenericBufferLength] colors;
		static Vector2[maxGenericBufferLength] uvs;
		static DrawQueue[maxGenericBufferLength] drawQueue;
		static DrawQueue* startDrawQueue, lastDrawQueue;
		
		static uint32 vertexCount, vertexOffset;

		static uint vertexShader;
		static uint fragmentShader;
		static uint program;

		public static Color4 clearColor = .(0,0,0);

		// Shader Inputs
		public static uint positionAttributeIndex;
		public static uint normalAttributeIndex;
		public static uint colorAttributeIndex;
		public static uint uvAttributeIndex;

		public static uint instanceMatrixAttributeIndex;
		public static uint instanceTintAttributeIndex;

		// Shader Uniforms
		public static Matrix4 model = .Identity;
		public static int uniformViewMatrixIndex; // Camera Transform
		public static int uniformViewInvMatrixIndex; // Camera Inverse Transform
		public static Matrix4 view = .Identity;
		public static Vector3 viewPosition = .Zero;
		public static Matrix3 viewBasis = .Identity;
		public static int uniformProjectionMatrixIndex; // Camera Perspective
		public static Matrix4 projection = .Identity;
		public static int uniformSpecularIndex;

		public static Vector3 tint = .(1,1,1);
		public static int uniformZdepthOffsetIndex; // Z-depth Offset (mainly for pushing the wireframe forward to avoid Z-fighting)
		public static int uniformRetroShadingIndex; // Change shading from modern to emulated

		public static Texture whiteTexture ~ delete _; // Used with solid colors
		public static Texture halfWhiteTexture ~ delete _; // Used with emulating games' color

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

			useSync = majorVersion > 3 || majorVersion == 3 && minorVersion > 1;
			enableDebug = majorVersion == 4 && minorVersion > 2;

			Clear();
			SDL.GL_SwapWindow(window);

			// Create Default Texture
			var solidTextureData = Color(255,255,255);
			whiteTexture = new .(1, 1, GL.GL_SRGB, GL.GL_RGB, &solidTextureData);
			solidTextureData = Color(128,128,128);
			halfWhiteTexture = new .(1, 1, GL.GL_SRGB, GL.GL_RGB, &solidTextureData);

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

			
			GL.glGenBuffers(6, (.)&bufferID);

			// Position Buffer
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[0]);
			positionAttributeIndex = FindProgramAttribute(program, "vertexPosition");
			GL.glVertexAttribPointer(positionAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(positionAttributeIndex);

			// Normals Buffer
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[1]);
			normalAttributeIndex = FindProgramAttribute(program, "vertexNormal");
			GL.glVertexAttribPointer(normalAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(normalAttributeIndex);

			// Color Buffer
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[2]);
			colorAttributeIndex = FindProgramAttribute(program, "vertexColor");
			GL.glVertexAttribIPointer(colorAttributeIndex, 4, GL.GL_UNSIGNED_BYTE, 0, null);
			GL.glEnableVertexAttribArray(colorAttributeIndex);

			// UV Buffer
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[3]);
			uvAttributeIndex = FindProgramAttribute(program, "vertexTextureMapping");
			GL.glVertexAttribPointer(uvAttributeIndex, 2, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(uvAttributeIndex);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[4]);
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

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[5]);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(Vector3), &tint, GL.GL_STATIC_DRAW);

			instanceTintAttributeIndex = FindProgramAttribute(program, "instanceTint");
			GL.glVertexAttribPointer(instanceTintAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, 0, null);
			GL.glEnableVertexAttribArray(instanceTintAttributeIndex);
			GL.glVertexAttribDivisor(instanceTintAttributeIndex, 1);

			// Get Uniforms
			uniformViewMatrixIndex = FindProgramUniform(program, "view");
			uniformViewInvMatrixIndex = FindProgramUniform(program, "viewInv");
			uniformProjectionMatrixIndex = FindProgramUniform(program, "projection");
			uniformSpecularIndex = FindProgramUniform(program, "specularAmount");
			uniformZdepthOffsetIndex = FindProgramUniform(program, "zdepthOffset");
			uniformRetroShadingIndex = FindProgramUniform(program, "retroShading");

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
			GL.glDeleteBuffers(6, (.)&bufferID);
			GL.glDeleteShader(vertexShader);
			GL.glDeleteShader(fragmentShader);
			GL.glDeleteProgram(program);
		}

		static uint CompileShader(String sourcePath, uint shaderType) {
			let shader = GL.glCreateShader(shaderType);

			String source = scope .();
			System.IO.File.ReadAllText(sourcePath, source, true);
			char8* sourceData = source.Ptr;

			GL.glShaderSource(shader, 1, &sourceData, null);
			GL.glCompileShader(shader);

			int32 status = GL.GL_FALSE;
			GL.glGetShaderiv(shader, GL.GL_COMPILE_STATUS, &status);
			if (status == GL.GL_FALSE) {
				int32 length = 0;
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

			int32 status = GL.GL_FALSE;
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

		public static void PushPoint(Vector3 position, Vector3 normal, Color4 color, Vector2 uv) {
			if (vertexCount >= maxGenericBufferLength) {
				return;
			}

			positions[vertexCount] = position;
			normals[vertexCount] = normal;
			colors[vertexCount] = color;
			uvs[vertexCount] = uv;

			vertexCount++;
		}

		public static void DrawLine(Vector3 p0, Vector3 p1,
			Color4 c0, Color4 c1) {
			if (vertexCount + 2 > maxGenericBufferLength) {
				Draw();
				startDrawQueue = lastDrawQueue = &drawQueue[0];
				vertexCount = vertexOffset = 0;
			}
				
			let normal = Vector3(0,0,1);

			PushPoint(p0, normal, c0, .Zero);
			PushPoint(p1, normal, c1, .Zero);

			if (lastDrawQueue.type == GL.GL_LINES) {
				lastDrawQueue.count += 2;
			} else {
				lastDrawQueue++;
				lastDrawQueue.type = GL.GL_LINES;
				lastDrawQueue.count = 2;
				lastDrawQueue.texture = (uint8)whiteTexture.textureObjectID;
			}
		}

		public static void DrawTriangle(Vector3 p0, Vector3 p1, Vector3 p2,
			Color4 c0, Color4 c1, Color4 c2,
			Vector2 uv0, Vector2 uv1, Vector2 uv2, uint textureObject) {
			if (vertexCount + 3 > maxGenericBufferLength) {
				Draw();
				startDrawQueue = lastDrawQueue = &drawQueue[0];
				vertexCount = vertexOffset = 0;
			}

			let normal = Vector3.Cross(p1 - p0, p2 - p0);

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

		public static void DrawTriangle(Vector3 p0, Vector3 p1, Vector3 p2,
			Color4 c0, Color4 c1, Color4 c2) {
			DrawTriangle(p0, p1, p2, c0, c1, c2, .Zero, .Zero, .Zero, whiteTexture.textureObjectID);
		}

		public static void SetModel(Vector3 position, Matrix3 basis) {
			model = Matrix4.Translation(position) * basis;
		}

		public static void SetView(Vector3 position, Matrix3 basis) {
			viewPosition = position;
			viewBasis = basis;
			
			view = basis * Matrix4.Translation(position);
			GL.glUniformMatrix4fv(uniformViewMatrixIndex, 1, GL.GL_FALSE, (float*)&view);

			var viewInv = basis.Transpose() * Matrix4.Translation(-position);
			GL.glUniformMatrix4fv(uniformViewInvMatrixIndex, 1, GL.GL_FALSE, (float*)&viewInv);
		}

		public static void SetProjection(Matrix4 projection) {
			Renderer.projection = projection;
			GL.glUniformMatrix4fv(uniformProjectionMatrixIndex, 1, GL.GL_FALSE, (float*)&Renderer.projection);
		}

		public static void SetTint(Color tint) {
			Renderer.tint = .((float)tint.r / 255, (float)tint.g / 255, (float)tint.b / 255);
			//GL.glUniform3fv(uniformTintIndex, 1, &this.tint[0]);
		}

		public static void SetSpecular(float amount) {
			GL.glUniform1f(uniformSpecularIndex, amount);
		}

		public static void BeginWireframe() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_LINE);
			GL.glUniform1f(uniformZdepthOffsetIndex, -0.2f); // Push the lines a little forward
			GL.glLineWidth(2);
		}

		public static void BeginSolid() {
			GL.glPolygonMode(GL.GL_FRONT_AND_BACK, GL.GL_FILL);
			GL.glUniform1f(uniformZdepthOffsetIndex, 0); // Reset depth offset
			GL.glLineWidth(1);
		}

		public static void BeginRetroShading() {
			GL.glUniform1f(uniformRetroShadingIndex, 1);
		}

		public static void BeginDefaultShading() {
			GL.glUniform1f(uniformRetroShadingIndex, 0);
		}

		public static void Draw() {
			GL.glBindVertexArray(vertexArrayObject);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[0]);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), null, GL.GL_STATIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector3), &positions);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[1]);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector3), null, GL.GL_STATIC_DRAW); 
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector3), &normals);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[2]);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Renderer.Color4), null, GL.GL_STATIC_DRAW);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Renderer.Color4), &colors);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, bufferID[3]);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, vertexCount * sizeof(Vector2), &uvs[0], GL.GL_STATIC_DRAW); 
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, vertexCount * sizeof(Vector2), &uvs);

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
			GL.glClearColor((float)clearColor.r / 255, (float)clearColor.g / 255, (float)clearColor.b / 255, (float)clearColor.a / 255);
			GL.glClear(GL.GL_COLOR_BUFFER_BIT | GL.GL_DEPTH_BUFFER_BIT);
			startDrawQueue = lastDrawQueue = &drawQueue[0];
			vertexCount = vertexOffset = 0;
		}

		public static void ClearDepth() {
		    GL.glClear(GL.GL_DEPTH_BUFFER_BIT);
		}

		public static void CheckForErrors() {
			if (!enableDebug) {
				return;
			}

			char8[] buffer = scope .[1024];
			uint32 severity = 0;
			uint32 source = 0;
			int32 messageSize = 0;
			uint32 mType = 0;
			uint32 id = 0;

			bool error = false;

			while (GL.glGetDebugMessageLog(1, 1024, &source, &mType, &id, &severity, &messageSize, &buffer[0]) > 0) {
				if (severity == GL.GL_DEBUG_SEVERITY_HIGH) {
					error = true;
				}

				String string = scope .(buffer, 0, 1024);
				Debug.WriteLine("OpenGL: {}", string);
			}

			if (error) {
				Debug.FatalError("Fatal OpenGL Error");
			}
		}
	}
}
