using System;

namespace SpyroScope {
	[Ordered]
	struct Moby {
		public Emulator.Address dataPointer; // 0
		uint32 a; // 4
		uint32 b; // 8
		public VectorInt position; // 12
		uint32[7] c; // 24
		uint16 d; // 52
		public uint16 objectTypeID; // 54
		uint16 e; // 56
		public uint8 objectSubTypeID; // 58
		uint8 f; // 59
		public uint8 modelID; // 60
		uint8 g; // 61
		uint16 h; // 62
		uint32 i; // 64
		public VectorByte eulerRotation; // 68
		uint8 j; // 72
		public uint8 varientID; // 73
		uint8[3] k; // 74
		public bool draw; // 77
		public uint8 lodDistance; // 78
		uint8 l; // 79
		uint32 m;
		public Renderer.Color4 color;

		public bool HasModel { get { return objectTypeID < 0x300; } }

		public void Draw(Renderer renderer) {
			let basis = Matrix.Euler(
				-(float)eulerRotation.x / 0x80 * Math.PI_f,
				(float)eulerRotation.y / 0x80 * Math.PI_f,
				-(float)eulerRotation.z / 0x80 * Math.PI_f
			);
			DrawUtilities.Axis!(position, basis * .Scale(200,200,200), renderer);

			// Is object rendering in game?
			if (draw) {
				renderer.SetModel(position, basis * .Scale(60,60,60));
				renderer.SetTint(.(255,0,255));
			} else {
				renderer.SetModel(position, basis * .Scale(50,50,50));
				renderer.SetTint(.(0,255,255));
			}

			PrimitiveShape.cube.Draw();

			if (Emulator.rom == .RiptosRage) {
				switch (objectTypeID) {
					case 0x0078: { // Sparx
						SparxData sparx = ?;
						Emulator.ReadFromRAM(dataPointer, &sparx, sizeof(SparxData));
						sparx.Draw(renderer, this);
					}
					case 0x0400: { // Whirlwind
						WhirlwindData whirlwind = ?;
						Emulator.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(renderer, this);
					}
					case 0x01f0: {
						Emulator.Address pathArrayPointer = ?;
						Emulator.ReadFromRAM(dataPointer, &pathArrayPointer, 4);
						uint16 waypointCount = ?;
						Emulator.ReadFromRAM(pathArrayPointer, &waypointCount, 2);
						if (waypointCount > 0) {
							uint8[] dataBytes = scope .[4 * 4 * waypointCount];
							Emulator.ReadFromRAM(pathArrayPointer + 12, &dataBytes[0], 4 * 4 * waypointCount);
							for (int i < waypointCount) {
								let position = (VectorInt*)&dataBytes[4 * 4 * i];
			
								renderer.SetModel(*position, .Scale(500,500,50));
								renderer.SetTint(.(255,128,0));
								PrimitiveShape.cylinder.Draw();
							}
						}
					} 
				}
			} else if (Emulator.rom == .YearOfTheDragon) {
				switch (objectTypeID) {
					case 0x03ff: {
						WhirlwindData whirlwind = ?;
						Emulator.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(renderer, this);
					}
				}
			}
		}
	}
}
