using OpenGL;
using SDL2;
using System;
using System.Collections;

namespace SpyroScope {
	class TextureSprite {
		public int start;
		public uint8 width, height;

		[Ordered]
		public struct SpriteFrame {
			public uint8 x, y, clutX, clutY;

			public bool GetTransparency() {
				return (clutX & 0b10000000) > 0;
			}
		}
		public SpriteFrame[] frames ~ delete _;

		public this(uint8 id, int start, int count) {
			this.start = start;

			let i = (int)Emulator.rom - 4;
			Emulator.spriteWidthArrayAddress[i].GetAtIndex(&width, id);
			Emulator.spriteHeightArrayAddress[i].GetAtIndex(&height, id);
			
			frames = new .[count];
			Emulator.spriteFrameArrayAddress[i].ReadRange(&frames[0], start, count);
		}

		public int Decode(int frameIndex) {
			let frame = frames[frameIndex];

			return VRAM.Decode(0x18, frame.x, frame.y, width, height, 4, (frame.clutX & 3) + ((int)frame.clutY << 6) + 0x4020);
		}

		public void Export() {
			for (let i < frames.Count) {
				let frame = frames[i];

				VRAM.Export(scope String() .. AppendF("S{}", start), frame.x, frame.y, width, height, 4, 0x18);
			}
		}
	}
}
