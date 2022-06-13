using FreeType;
using OpenGL;
using System;
using System.Collections;

namespace SpyroScope {
	class FTFont : Font {
		public readonly uint16 penLine;
		public readonly Texture atlas ~ delete _;

		struct Character {
			public FT.Vector size;
			public FT.Vector bearing;
			public uint32 advance;
			public Vector2 atlasPosition;
			public Vector2 atlasPosition2;
		}
		Dictionary<char8, Character> characters = new .() ~ delete _;

		public this(String file, int height) {
			this.height = height;

			FT.Face fontFace = ?;
			if (FT.NewFace(file, 0, &fontFace)) {
				return;
			}

			FT.SetPixelSizes(fontFace, 0, (.)height);

			GL.glPixelStorei(GL.GL_UNPACK_ALIGNMENT, 1);

			int area = 0;

			for (var c = ' '; c < (char8)128; c++) {
				if (FT.LoadCharacter(fontFace, (.)c, .Render)) {
					continue;
				}

				Character character = ?;
				character.size.x = (.)fontFace.glyph.bitmap.width;
				character.size.y = (.)fontFace.glyph.bitmap.rows;
				character.bearing.x = fontFace.glyph.bitmapLeft;
				character.bearing.y = fontFace.glyph.bitmapTop;
				character.advance = (.)fontFace.glyph.advance.x;

				characters[c] = character;
				area += character.size.x * character.size.y;
			}

			var i = 0;
			let atlasCharacters = scope char8[characters.Count];
			for	(let pair in characters) {
				atlasCharacters[i++] = pair.key;
			}

			Array.Sort(atlasCharacters, scope (x,y) => {
				let t1 = characters[x].size.y <=> characters[y].size.y;
				if (t1 == 0) {
					let t2 = characters[x].size.x <=> characters[y].size.x;
					if (t2 == 0) {
						return x <=> y;
					}
					return t2;
				}
				return t1;
			});
			let textureSize = (int)Math.Pow(2, Math.Ceiling(Math.Log(Math.Sqrt(area), 2)));

			let blank = new uint8[textureSize * textureSize];
			atlas = new .(textureSize, textureSize, GL.GL_RED, GL.GL_RED, &blank[0]);
			delete blank;

			atlas.Bind();

			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MIN_FILTER, GL.GL_LINEAR);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_MAG_FILTER, GL.GL_LINEAR);

			Renderer.CheckForErrors();

			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_SWIZZLE_R, GL.GL_ONE);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_SWIZZLE_G, GL.GL_ONE);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_SWIZZLE_B, GL.GL_ONE);
			GL.glTexParameteri(GL.GL_TEXTURE_2D, GL.GL_TEXTURE_SWIZZLE_A, GL.GL_RED);

			int32 tallestInRow = 0;
			int32 offsetX = 0;
			int32 offsetY = 0;
			for (let c in atlasCharacters) {
				let character = &characters[c];
				FT.LoadCharacter(fontFace, c, .Render);

				if (offsetX + character.size.x > textureSize) {
					offsetX = 0;
					offsetY += tallestInRow;
					tallestInRow = 0;
				}

				GL.glTexSubImage2D(GL.GL_TEXTURE_2D,
					0, offsetX, offsetY,
					character.size.x, character.size.y,
					GL.GL_RED, GL.GL_UNSIGNED_BYTE, fontFace.glyph.bitmap.buffer
				);

				character.atlasPosition.x = (float)offsetX / textureSize;
				character.atlasPosition.y = (float)offsetY / textureSize;
				character.atlasPosition2.x = (float)(offsetX + character.size.x) / textureSize;
				character.atlasPosition2.y = (float)(offsetY + character.size.y) / textureSize;

				tallestInRow = Math.Max(tallestInRow, character.size.y);
				offsetX += character.size.x;
			}
			
			penLine = (.)Math.Ceiling(((float)fontFace.ascender / fontFace.height) * height);
			FT.DoneFace(fontFace);
			this.height = height;

			Texture.Unbind();
		}

		public float Print(StringView text, Vector2 position, float scale, Color4 color) {
			var position;
			position.y += penLine;

			for (let i < text.Length) {
				let c = text[i];
				let character = characters[c];

				if (c != ' ') {
					let x = position.x + character.bearing.x * scale;
					let y = position.y + (character.size.y - character.bearing.y) * scale;
	
					let width = character.size.x * scale;
					let height = character.size.y * scale;
	
					DrawUtilities.Rect(y - height, y, x, x + width,
						character.atlasPosition.y, character.atlasPosition2.y, character.atlasPosition.x, character.atlasPosition2.x,
						atlas, color);
				}

				position.x += (character.advance >> 6) * scale;
			}

			return position.x;
		}

		public override float Print(StringView text, Vector2 position, Color4 color) {
			return Print(text, position, 1, color);
		}

		public float CalculateWidth(StringView text) {
			if (text.Length == 0) {
				return 0;
			}

			float width = 0;
			for (let i < text.Length) {
				let c = text[i];
				let character = characters[c];

				width += character.advance >> 6;
			}

			return width;
		}

		public int NearestTextIndex(StringView text, float targetWidth) {
			float width = 0, closest = Math.Abs(targetWidth);
			for (let i < text.Length) {
				let c = text[i];
				let character = characters[c];
				
				width += character.advance >> 6;
				let distance = Math.Abs(width - targetWidth);
				if (distance > closest) {
					return i;
				}
				
				closest = distance;
			}

			return text.Length;
		}
	}
}
