using OpenGL;
using System;
using System.Diagnostics;

namespace SpyroScope {
	class Shader {
		public static Self current;

		public uint shaderProgramID { get; private set; } ~ GL.glDeleteProgram(_);

		public this(StringView sourceVertexShader, StringView sourceFragmentShader) {
			let vertexShader = CompileShader(sourceVertexShader, GL.GL_VERTEX_SHADER);
			let fragmentShader = CompileShader(sourceFragmentShader, GL.GL_FRAGMENT_SHADER);

			shaderProgramID = GL.glCreateProgram(); // New empty program

			GL.glAttachShader(shaderProgramID, vertexShader);
			GL.glAttachShader(shaderProgramID, fragmentShader);

			GL.glLinkProgram(shaderProgramID);
			
			GL.glDeleteShader(vertexShader);
			GL.glDeleteShader(fragmentShader);

			int32 status = GL.GL_FALSE;
			GL.glGetProgramiv(shaderProgramID, GL.GL_LINK_STATUS, &status);
			Debug.Assert(status == GL.GL_TRUE, "Program link failed");
		}

		static uint CompileShader(StringView sourcePath, uint shaderType) {
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

		public uint GetAttribute(String attributeName) {
			let index = GL.glGetAttribLocation(shaderProgramID, attributeName.Ptr);

			Debug.Assert(index >= 0, "Attribute not found");

			return (uint)index;
		}

		public int GetUniform(String uniformName) {
			let index = GL.glGetUniformLocation(shaderProgramID, uniformName.Ptr);

			Debug.Assert(index >= 0, "Uniform not found");

			return index;
		}

		public void Use() {
			GL.glUseProgram(shaderProgramID);
			current = this;
		}
	}
}
