using OpenGL;
using SDL2;
using System;

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

			Emulator.ReadFromRAM((.)0x800634b8 + id, &width, 1);
			Emulator.ReadFromRAM((.)0x800634d0 + id, &height, 1);
			
			frames = new .[count];
			Emulator.ReadFromRAM((.)0x8006351c + start * sizeof(SpriteFrame), &frames[0], sizeof(SpriteFrame) * count);
		}

		public void Decode() {
			for (let frameIndex < frames.Count) {
				let frame = frames[frameIndex];

				VRAM.Decode(0x18, frame.x, frame.y, width, height, 4, (frame.clutX & 3) + ((int)frame.clutY << 6) + 0x4020);
			}
		}

		public void Export() {
			for (let i < frames.Count) {
				let frame = frames[i];

				VRAM.Export(scope String() .. AppendF("S{}", start), frame.x, frame.y, width, height, 4, 0x18);
			}
		}
	}
}
