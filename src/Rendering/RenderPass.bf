using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	abstract class RenderPass {
		public ShaderProgram shader;
		List<RenderJob> renderQueue = new .() ~ delete _;

		public RenderJob AddJob(Mesh mesh, Texture texture) {
			let index = renderQueue.FindIndex(scope (x) => x.mesh == mesh && x.texture == texture);
			if (index > -1) {
				return renderQueue[index];
			}
			let job = new RenderJob(mesh, texture);
			renderQueue.Add(job);

			return job;
		}

		public RenderJob AddJob(Mesh mesh) {
			return AddJob(mesh, Renderer.whiteTexture);
		}

		protected virtual void PreRender() {};
		protected virtual void PostRender() {};

		public void Render(bool clear = true, bool prepare = true) {
			if (prepare) PreRender();

			shader.Use();

			for (let job in renderQueue) {
				job.Execute();
			}

			if (clear) {
				Clear();
			}

			if (prepare) PostRender();
		}

		public void Clear() {
			ClearAndDeleteItems!(renderQueue);
		}
	}

	class OpaquePass : RenderPass {
		protected override void PreRender() {
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);

			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glDepthMask(GL.GL_TRUE);
		}
	}

	class TransparentPass : RenderPass {
		protected override void PreRender() {
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
			
			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glDepthMask(GL.GL_FALSE);
		}
	}

	class RetroDiffusePass : RenderPass {
		protected override void PreRender() {
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);

			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glDepthMask(GL.GL_TRUE);
		}
	}

	class RetroSpecularPass : RenderPass {
		protected override void PreRender() {
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			GL.glUniform1f(Renderer.uniformSpecularIndex, 1);
			
			GL.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);

			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glDepthMask(GL.GL_TRUE);
		}

		protected override void PostRender() {
			GL.glUniform1f(Renderer.uniformSpecularIndex, 0);
		}
	}

	class RetroTransparentPass : RenderPass {
		protected override void PreRender() {
			Renderer.SetView(Camera.position, Camera.basis);
			Renderer.SetProjection(WindowApp.viewerProjection);
			
			GL.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
			
			GL.glEnable(GL.GL_DEPTH_TEST);
			GL.glDepthMask(GL.GL_FALSE);
		}
	}
}
