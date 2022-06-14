using OpenGL;
using System.Collections;

namespace SpyroScope {
	class Frame {
		public static Self current;
		public static List<Self> frames = new .() ~ delete _;

		uint32 frameObjectId, renderObjectId;
		public Texture targetColorTexture { get; private set; }

		public static float[24] deviceQuad = .(
		    -1.0f, -1.0f,  0.0f, 0.0f,
		    -1.0f,  1.0f,  0.0f, 1.0f,
		     1.0f, -1.0f,  1.0f, 0.0f,
			
			1.0f, -1.0f,  1.0f, 0.0f,
		    -1.0f,  1.0f,  0.0f, 1.0f,
		     1.0f,  1.0f,  1.0f, 1.0f
		);

		public static uint32 quadVertexArray, quadVertexBuffer;

		static ShaderProgram immediateProgram ~ delete _;

		public static void Init() {
			GL.glGenVertexArrays(1, &quadVertexArray);
			GL.glBindVertexArray(quadVertexArray);

			GL.glGenBuffers(1, &quadVertexBuffer);
			GL.glBindBuffer(GL.GL_ARRAY_BUFFER, quadVertexBuffer);
    		GL.glBufferData(GL.GL_ARRAY_BUFFER, 24*4, &deviceQuad, GL.GL_STATIC_DRAW);

			immediateProgram = new ShaderProgram("shaders/framePassVertex.glsl", "shaders/framePassFrag.glsl");

			let positionAttribute = immediateProgram.GetAttribute("position");
			GL.glEnableVertexAttribArray(positionAttribute);
			GL.glVertexAttribPointer(positionAttribute, 2, GL.GL_FLOAT, GL.GL_FALSE, 4*4, (void*)0);

			let textureCoordsAttribute = immediateProgram.GetAttribute("textureCoords");
			GL.glEnableVertexAttribArray(textureCoordsAttribute);
    		GL.glVertexAttribPointer(textureCoordsAttribute, 2, GL.GL_FLOAT, GL.GL_FALSE, 4*4, (void*)(2*4));
			
			GL.glBindVertexArray(0);
		}

		public this () {
			GL.glGenFramebuffers(1, &frameObjectId);
			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, frameObjectId);

			Generate(WindowApp.width, WindowApp.height);

			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, 0);
			frames.Add(this);
		}

		public ~this () {
			GL.glDeleteFramebuffers(1, &frameObjectId);
			GL.glDeleteRenderbuffers(1, &renderObjectId);

			delete targetColorTexture;
			frames.Remove(this);
		}

		public void Bind() {
			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, frameObjectId);
			current = this;
		}

		public static void BindMainFrame() {
			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, 0);
			current = null;
		}

		void Generate(int width, int height) {
			delete targetColorTexture;

			targetColorTexture = new .(width, height, GL.GL_RGB16F, GL.GL_RGB, null);

			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, frameObjectId);
			GL.glFramebufferTexture2D(GL.GL_FRAMEBUFFER, GL.GL_COLOR_ATTACHMENT0, GL.GL_TEXTURE_2D, targetColorTexture.textureObjectID, 0);

			GL.glGenRenderbuffers(1, &renderObjectId);
			GL.glBindRenderbuffer(GL.GL_RENDERBUFFER, renderObjectId);
			GL.glRenderbufferStorage(GL.GL_RENDERBUFFER, GL.GL_DEPTH24_STENCIL8, width, height);

			GL.glFramebufferRenderbuffer(GL.GL_FRAMEBUFFER, GL.GL_DEPTH_STENCIL_ATTACHMENT, GL.GL_RENDERBUFFER, renderObjectId);

			GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, 0);
		}

		public void ResizeToWindow() {
			Generate(WindowApp.width, WindowApp.height);
		}

		public static void ResizeAllToWindow() {
			for (let frame in frames) {
				frame.ResizeToWindow();
			}
		}

		public void Render() {
			let previous = ShaderProgram.current;
			immediateProgram.Use();

			targetColorTexture.Bind();
			RenderFullQuad();
			
			previous.Use();
		}

		public static void RenderFullQuad() {
			GL.glBindVertexArray(quadVertexArray);

			GL.glDisable(GL.GL_DEPTH_TEST);
			GL.glDrawArrays(GL.GL_TRIANGLES, 0, 6);

			GL.glBindVertexArray(0);
		}
	}
}
