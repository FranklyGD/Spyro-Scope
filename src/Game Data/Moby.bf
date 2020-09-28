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
		public uint8 updateState; // 72
		public uint8 varientID; // 73
		uint8[3] k; // 74
		public bool draw; // 77
		public uint8 lodDistance; // 78
		uint8 l; // 79
		public uint8 heldGemValue; // 80
		uint8 m; // 81
		uint8 n; // 82
		uint8 o; // 83
		public Renderer.Color4 color;

		// Derived from Spyro: Ripto's Rage [8001d068]
		public bool HasModel { get { return objectTypeID < 0x300; } }
		// Derived from Spyro: Year of the Dragon [80030410]
		public bool IsActive { get { return updateState < 0x80; } }

		public void DrawOriginAxis() {
			let basis = Matrix.Euler(
				-(float)eulerRotation.x / 0x80 * Math.PI_f,
				(float)eulerRotation.y / 0x80 * Math.PI_f,
				-(float)eulerRotation.z / 0x80 * Math.PI_f
			);
			DrawUtilities.Axis(position, basis * .Scale(200,200,200));

			// Is object rendering in game?
			if (draw) {
				Renderer.SetModel(position, basis * .Scale(60,60,60));
				Renderer.SetTint(.(255,0,255));
			} else {
				Renderer.SetModel(position, basis * .Scale(50,50,50));
				Renderer.SetTint(IsActive ? .(0,255,255) : .(32,32,32));
			}

			PrimitiveShape.cube.QueueInstance();
		}

		public void DrawData() {
			// This is incomplete and possible inefficient
			// to work with when adding new entries
			if (Emulator.rom == .RiptosRage) {
				switch (objectTypeID) {
					case 0x0078: { // Sparx
						SparxData sparx = ?;
						Emulator.ReadFromRAM(dataPointer, &sparx, sizeof(SparxData));
						sparx.Draw(this);
					}
					case 0x01f0: { // Glimmer Blue Dino
						DrawPath(dataPointer);
					}
					case 0x0189: { // Shady Oasis NPC
						uint32 pathCount = ?;
						Emulator.ReadFromRAM(dataPointer + 0x38, &pathCount, 4);

						for (let p < pathCount) {
							DrawPath(dataPointer + 0x5c + p * 4);
						}
					}
					case 0x019f: { // Fish
						DrawPath(dataPointer + 0x4);
					}
					case 0x01bc: { // Hunter
						DrawPath(dataPointer + 0x38);
					}
					case 0x0400: { // Whirlwind
						WhirlwindData whirlwind = ?;
						Emulator.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(this);
					}
				}
			} else if (Emulator.rom == .YearOfTheDragon) {
				switch (objectTypeID) {
					case 0x0078: { // Sparx
						SparxData sparx = ?;
						Emulator.ReadFromRAM(dataPointer, &sparx, sizeof(SparxData));
						sparx.Draw(this);
					}
					case 0x03ff: { // Whirlwind
						WhirlwindData whirlwind = ?;
						Emulator.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(this);
					}
				}
			}
		}

		void DrawPath(Emulator.Address pathAddress) {
			Emulator.Address pathArrayPointer = ?;
			Emulator.ReadFromRAM(pathAddress, &pathArrayPointer, 4);
			uint16 waypointCount = ?;
			Emulator.ReadFromRAM(pathArrayPointer, &waypointCount, 2);
			if (waypointCount > 256) {
				return; // There shouldn't be this many waypoints
			}
			if (waypointCount > 0) {
				uint8[] dataBytes = scope .[4 * 4 * waypointCount];
				Emulator.ReadFromRAM(pathArrayPointer + 12, &dataBytes[0], 4 * 4 * waypointCount);
				for (let i < waypointCount) {
					let position = (VectorInt*)&dataBytes[4 * 4 * i];

					Renderer.SetModel(*position, .Scale(500,500,50));
					Renderer.SetTint(.(255,128,0));
					PrimitiveShape.cylinder.QueueInstance();
					
					if (i == 0) {
						Renderer.SetModel(*position, .Scale(400,400,100));
						Renderer.SetTint(.(0,255,0));
						PrimitiveShape.cylinder.QueueInstance();
					}

					if (i < waypointCount - 1) {
						let nextPosition = (VectorInt*)&dataBytes[4 * 4 * (i + 1)];
						let direction = *nextPosition - *position;
						let normalizedDirection = direction.ToVector().Normalized();

						DrawUtilities.Arrow(*position + normalizedDirection * 400, normalizedDirection * (direction.Length() - 800), 125, .(255,128,0));
					}
				}
			}
		}
	}
}
