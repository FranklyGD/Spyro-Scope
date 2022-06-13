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

		const int maxPointBufferLength = 0x6000;
		static uint32 vertexArrayObject;
		static uint32 pointBufferID, instanceBufferID;

		[Ordered]
		struct Point {
			public Vector3 position;
			public Vector3 normal;
			public Color4 color;
			public Vector2 uv;
		}

		static List<Point> points = new .() ~ delete _;
		static List<DrawQueue> drawQueue = new .() ~ delete _;
		static DrawQueue* lastDrawQueue;

		public static ShaderProgram defaultProgram;
		public static ShaderProgram compareProgram;

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

		public static OpaquePass opaquePass = new .() ~ delete _;
		public static TransparentPass tranparentPass = new .() ~ delete _;
		public static RetroDiffusePass retroDiffusePass = new .() ~ delete _;
		public static RetroSpecularPass retroSpecularPass = new .() ~ delete _;
		public static RetroTransparentPass retroTranparentPass = new .() ~ delete _;

		public static void Init(SDL.Window* window) {
			lastDrawQueue = drawQueue.Ptr;

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

			Frame.Init();
			Terrain.collisionFrame = new Frame();
			Terrain.visualFrame = new Frame();

			// Create Default Texture
			var solidTextureData = Color(255,255,255);
			whiteTexture = new .(1, 1, GL.GL_SRGB, GL.GL_RGB, &solidTextureData);
			solidTextureData = Color(128,128,128);
			halfWhiteTexture = new .(1, 1, GL.GL_SRGB, GL.GL_RGB, &solidTextureData);

			// Create and use the shader program
			defaultProgram = new ShaderProgram("shaders/vertex.glsl", "shaders/fragment.glsl");
			compareProgram = new ShaderProgram("shaders/framePassVertex.glsl", "shaders/frameMergeFrag.glsl");

			compareProgram.Use();
			GL.glUniform1i(compareProgram.GetUniform("color0"), 0);
			GL.glUniform1i(compareProgram.GetUniform("color1"), 1);
			GL.glUniform1i(compareProgram.GetUniform("depth0"), 2);
			GL.glUniform1i(compareProgram.GetUniform("depth1"), 3);

			defaultProgram.Use();

			opaquePass.shader = defaultProgram;
			tranparentPass.shader = defaultProgram;
			retroDiffusePass.shader = defaultProgram;
			retroSpecularPass.shader = defaultProgram;
			retroTranparentPass.shader = defaultProgram;

			// Create Buffers/Arrays

			vertexArrayObject = 0;
			GL.glGenVertexArrays(1, &vertexArrayObject);
			GL.glBindVertexArray(vertexArrayObject);
			
			GL.glGenBuffers(1, &pointBufferID);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, pointBufferID);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, maxPointBufferLength * sizeof(Point), null, GL.GL_STATIC_DRAW);
			
			// Position Buffer
			positionAttributeIndex = defaultProgram.GetAttribute("vertexPosition");
			GL.glVertexAttribPointer(positionAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Point), (void*)0);
			GL.glEnableVertexAttribArray(positionAttributeIndex);

			// Normals Buffer
			normalAttributeIndex = defaultProgram.GetAttribute("vertexNormal");
			GL.glVertexAttribPointer(normalAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Point), (void*)12);
			GL.glEnableVertexAttribArray(normalAttributeIndex);

			// Color Buffer
			colorAttributeIndex = defaultProgram.GetAttribute("vertexColor");
			GL.glVertexAttribIPointer(colorAttributeIndex, 4, GL.GL_UNSIGNED_BYTE, sizeof(Point), (void*)(12+12));
			GL.glEnableVertexAttribArray(colorAttributeIndex);

			// UV Buffer
			uvAttributeIndex = defaultProgram.GetAttribute("vertexTextureMapping");
			GL.glVertexAttribPointer(uvAttributeIndex, 2, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Point), (void*)(12+12+4));
			GL.glEnableVertexAttribArray(uvAttributeIndex);
			
			GL.glGenBuffers(1, &instanceBufferID);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, instanceBufferID);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, sizeof(Matrix4) + sizeof(Vector3), null, GL.GL_STATIC_DRAW);
			
			// Model Instance Attribute
			instanceMatrixAttributeIndex = defaultProgram.GetAttribute("instanceModel");

			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+0, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4) + sizeof(Vector3), (void*)(4*0));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+1, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4) + sizeof(Vector3), (void*)(4*4));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+2, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4) + sizeof(Vector3), (void*)(4*8));
			GL.glVertexAttribPointer(instanceMatrixAttributeIndex+3, 4, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4) + sizeof(Vector3), (void*)(4*12));

			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+0);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+1);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+2);
			GL.glEnableVertexAttribArray(instanceMatrixAttributeIndex+3);

			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+0, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+1, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+2, 1);
			GL.glVertexAttribDivisor(instanceMatrixAttributeIndex+3, 1);
			
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, sizeof(Matrix4), &model);

			// Tint Instance Attribute
			instanceTintAttributeIndex = defaultProgram.GetAttribute("instanceTint");
			GL.glVertexAttribPointer(instanceTintAttributeIndex, 3, GL.GL_FLOAT, GL.GL_FALSE, sizeof(Matrix4) + sizeof(Vector3), (void*)(4*16));
			GL.glEnableVertexAttribArray(instanceTintAttributeIndex);
			GL.glVertexAttribDivisor(instanceTintAttributeIndex, 1);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 4*4*4, sizeof(Vector3), &tint);

			// Get Uniforms
			uniformViewMatrixIndex = defaultProgram.GetUniform("view");
			uniformViewInvMatrixIndex = defaultProgram.GetUniform("viewInv");
			uniformProjectionMatrixIndex = defaultProgram.GetUniform("projection");
			uniformSpecularIndex = defaultProgram.GetUniform("specularAmount");
			uniformZdepthOffsetIndex = defaultProgram.GetUniform("zdepthOffset");
			uniformRetroShadingIndex = defaultProgram.GetUniform("retroShading");

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
			GL.glDeleteBuffers(1, &pointBufferID);
			GL.glDeleteBuffers(1, &instanceBufferID);

			delete defaultProgram;
			delete compareProgram;

			delete Terrain.collisionFrame;
			delete Terrain.visualFrame;
		}

		public static void PushPoint(Vector3 position, Vector3 normal, Color4 color, Vector2 uv) {
			points.Add(Point{
				position = position,
				normal = normal,
				color = color,
				uv = uv,
			});
		}

		public static void Line(Vector3 p0, Vector3 p1,
			Color4 c0, Color4 c1) {	
			let normal = Vector3(0,0,1);

			PushPoint(p0, normal, c0, .Zero);
			PushPoint(p1, normal, c1, .Zero);

			if (lastDrawQueue != null && lastDrawQueue.type == GL.GL_LINES) {
				lastDrawQueue.count += 2;
			} else {
				drawQueue.Add(DrawQueue{
					type = GL.GL_LINES,
					count = 2,
					texture = (.)whiteTexture.textureObjectID,
				});
				lastDrawQueue = &drawQueue[drawQueue.Count - 1];
			}
		}

		public static void Triangle(Vector3 p0, Vector3 p1, Vector3 p2,
			Color4 c0, Color4 c1, Color4 c2,
			Vector2 uv0, Vector2 uv1, Vector2 uv2, uint textureObject) {

			let normal = Vector3.Cross(p1 - p0, p2 - p0);

			PushPoint(p0, normal, c0, uv0);
			PushPoint(p1, normal, c1, uv1);
			PushPoint(p2, normal, c2, uv2);

			if (lastDrawQueue != null && lastDrawQueue.type == GL.GL_TRIANGLES && lastDrawQueue.texture == textureObject) {
				lastDrawQueue.count += 3;
			} else {
				drawQueue.Add(DrawQueue{
					type = GL.GL_TRIANGLES,
					count = 3,
					texture = (.)textureObject,
				});
				lastDrawQueue = &drawQueue[drawQueue.Count - 1];
			}
		}

		public static void Triangle(Vector3 p0, Vector3 p1, Vector3 p2,
			Color4 c0, Color4 c1, Color4 c2) {
			Triangle(p0, p1, p2, c0, c1, c2, .Zero, .Zero, .Zero, whiteTexture.textureObjectID);
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
			Renderer.tint = tint.ToVector();
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

		public static void Draw() {
			OpenGL.GL.glBlendFunc(OpenGL.GL.GL_SRC_ALPHA, OpenGL.GL.GL_ONE_MINUS_SRC_ALPHA);

			GL.glBindVertexArray(vertexArrayObject);

			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, pointBufferID);
			GL.glBufferData(GL.GL_ARRAY_BUFFER, maxPointBufferLength * sizeof(Point), null, GL.GL_STATIC_DRAW);

			var pointCount = Math.Min(maxPointBufferLength, points.Count);
			GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, pointCount * sizeof(Point), points.Ptr);

			var dataStart = 0;
			var dataOffset = 0;
			for (let drawQueueItem in drawQueue) {
				GL.glBindTexture(GL.GL_TEXTURE_2D, drawQueueItem.texture);

				int remainingCount = drawQueueItem.count;
				while (remainingCount > maxPointBufferLength) {
					let effectiveLength = maxPointBufferLength - (maxPointBufferLength % (drawQueueItem.type == GL.GL_LINES ? 2 : 3));
					GL.glDrawArrays(drawQueueItem.type, 0, effectiveLength);
					
					dataOffset += effectiveLength;

					pointCount = Math.Min(effectiveLength, points.Count - dataOffset);
					GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, pointCount * sizeof(Point), points.Ptr + dataOffset);
					dataStart = dataOffset;

					remainingCount -= effectiveLength;
				}

				if (drawQueueItem.count + dataOffset - dataStart > maxPointBufferLength) {
					pointCount = Math.Min(maxPointBufferLength, points.Count - dataOffset);
					GL.glBufferSubData(GL.GL_ARRAY_BUFFER, 0, pointCount * sizeof(Point), points.Ptr + dataOffset);
					dataStart = dataOffset;
				}

				GL.glDrawArrays(drawQueueItem.type, dataOffset - dataStart, drawQueueItem.count);

				dataOffset += drawQueueItem.count;
			}

			points.Clear();
			drawQueue.Clear();
			lastDrawQueue = null;
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

			points.Clear();
			drawQueue.Clear();
			lastDrawQueue = null;
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
					
					String string = scope .(buffer.Ptr);
					Debug.WriteLine("OpenGL: {}", string);
				}
			}

			if (error) {
				Debug.FatalError("Fatal OpenGL Error");
			}
		}
	}
}
