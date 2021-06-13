using System;
using System.IO;

namespace SpyroScope {
	static class Image {
		[Ordered, Packed]
		struct TGAHeader {
			public uint8 idLength, colorMapType, imageType;
			public uint16 colorMapStart, colorMapSize;
			public uint8 colorMapDepth;
			public uint16 xOffset, yOffset, width, height;
			public uint8 depth, descriptor;
		}

		public static void SaveTGA(uint16* pixels, uint16 width, uint16 height, StringView path) {
			FileStream file = new .();
			file.Create(path);

			// Write header
			/*let header = TGAHeader() {
				imageType = 2,
				width = width,
				height = height,
				depth = 16, // Hard coded
				descriptor = 0x21
			};*/

			let header = TGAHeader() {
				imageType = 2,
				width = width,
				height = height,
				depth = 32, // Hard coded
				descriptor = 0x24
			};

			file.Write(header);

			// Write pixels
			/*let dataSize = (int)width * height;
			uint16[] data = new .[dataSize];
			for (let i < dataSize) {
				let pixel = pixels[i];

				let r = (pixel & 0x001f) << 10;
				let g = (pixel & 0x03e0);
				let b = (pixel & 0x7c00) >> 10;
				let a = (pixel & 0x8000);

				data[i] = a | r | g | b;
			}

			file.Write(Span<uint16>(data));*/

			let dataSize = (int)width * height;
			uint32[] data = new .[dataSize];
			for (let i < dataSize) {
				uint8* npixel = (uint8*)&data[i];
				let pixel = pixels[i];
				
				npixel[0] = (uint8)((float)(pixel & 0x7c00) / 0x7c00 * 255);
				npixel[1] = (uint8)((float)(pixel & 0x03e0) / 0x03e0 * 255);
				npixel[2] = (uint8)((float)(pixel & 0x001f) / 0x001f * 255);
				npixel[3] = (uint8)((float)(pixel & 0x8000) / 0x8000 * 255);
			}
			
			file.Write(Span<uint32>(data));

			delete data;
			delete file;
		}
	}
}
