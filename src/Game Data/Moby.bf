using System;
using System.Collections;

namespace SpyroScope {
	[Ordered]
	struct Moby {
		public Emulator.Address dataPointer; // 0
		uint32 a; // 4
		uint32 b; // 8
		public Vector3Int position; // 12
		uint32[7] c; // 24
		uint16 d; // 52
		public uint16 objectTypeID; // 54
		uint16 e; // 56
		public uint8 objectSubTypeID; // 58
		uint8 f; // 59
		public uint8 modelID; // 60
		public uint8 nextModelID; // 61
		public uint8 keyframe; // 62
		public uint8 nextKeyframe; // 63
		uint8 i; // 64
		public bool animating; // 65
		uint16 j; // 66
		public Vector3Byte eulerRotation; // 68
		public int8 updateState; // 72
		public uint8 variantID; // 73
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
		public bool HasModel { get => objectTypeID < 0x300; }
		// Derived from Spyro: Year of the Dragon [80030410]
		public bool IsActive { get => updateState > -1; }
		// Only on Spyro the Dragon
		public bool IsTerminator { get => updateState == -1; }

		public bool IsNull { get => dataPointer.IsNull; }

		public static List<Moby> allocated = new .() ~ delete _;

		public Matrix3 basis { get { return .Euler(
			-(float)eulerRotation.x / 0x80 * Math.PI_f,
			(float)eulerRotation.y / 0x80 * Math.PI_f,
			-(float)eulerRotation.z / 0x80 * Math.PI_f
		); } }

		public void DrawOriginAxis() {
			let basis = basis;
			DrawUtilities.Axis(position, basis * .Scale(200));

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
			if (Emulator.active.installment == .RiptosRage) {
				switch (objectTypeID) {
					case 0x0078: { // Sparx
						SparxData sparx = ?;
						Emulator.active.ReadFromRAM(dataPointer, &sparx, sizeof(SparxData));
						sparx.Draw(this);
					}
					case 0x01f0: { // Glimmer Blue Dino
						DrawPath(dataPointer);
					}
					case 0x0189: { // Shady Oasis NPC
						uint32 pathCount = ?;
						Emulator.active.ReadFromRAM(dataPointer + 0x38, &pathCount, 4);

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
						Emulator.active.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(this);
					}
				}
			} else if (Emulator.active.installment == .YearOfTheDragon) {
				switch (objectTypeID) {
					case 0x0078: { // Sparx
						SparxData sparx = ?;
						Emulator.active.ReadFromRAM(dataPointer, &sparx, sizeof(SparxData));
						sparx.Draw(this);
					}
					case 0x03f3: { // ???
						int32 objectIndex = ?;
						Emulator.active.ReadFromRAM(dataPointer, &objectIndex, 4);

						Moby linkedMoby = ?;
						Emulator.Address<Moby> objPointer = ?;
						Emulator.objectArrayPointers[(int)Emulator.active.rom].Read(&objPointer);
						Emulator.active.ReadFromRAM(objPointer + objectIndex * sizeof(Moby), &linkedMoby, sizeof(Moby));

						Renderer.DrawLine(position, linkedMoby.position, .(255,255,255), .(255,255,255));
					}
					case 0x03ff: { // Whirlwind
						WhirlwindData whirlwind = ?;
						Emulator.active.ReadFromRAM(dataPointer, &whirlwind, sizeof(WhirlwindData));
						whirlwind.Draw(this);
					}
				}
			}
		}

		void DrawPath(Emulator.Address pathAddress) {
			Emulator.Address pathArrayPointer = ?;
			Emulator.active.ReadFromRAM(pathAddress, &pathArrayPointer, 4);
			uint16 waypointCount = ?;
			Emulator.active.ReadFromRAM(pathArrayPointer, &waypointCount, 2);
			if (waypointCount > 256) {
				return; // There shouldn't be this many waypoints
			}
			if (waypointCount > 0) {
				uint8[] dataBytes = scope .[4 * 4 * waypointCount];
				Emulator.active.ReadFromRAM(pathArrayPointer + 12, &dataBytes[0], 4 * 4 * waypointCount);
				for (let i < waypointCount) {
					let position = *(Vector3Int*)&dataBytes[4 * 4 * i];

					Renderer.SetModel(position, .Scale(500,500,50));
					Renderer.SetTint(.(255,128,0));
					PrimitiveShape.cylinder.QueueInstance();
					
					if (i == 0) {
						Renderer.SetModel(position, .Scale(400,400,100));
						Renderer.SetTint(.(0,255,0));
						PrimitiveShape.cylinder.QueueInstance();
					}

					if (i < waypointCount - 1) {
						let nextPosition = (Vector3)*(Vector3Int*)&dataBytes[4 * 4 * (i + 1)];
						let direction = nextPosition - position;
						let normalizedDirection = direction.Normalized();

						DrawUtilities.Arrow(position + normalizedDirection * 400, normalizedDirection * (direction.Length() - 800), 125, .(255,128,0));
					}
				}
			}
		}

		[Inline]
		public static Emulator.Address<Moby> GetAddress(int index) {
			return Emulator.active.objectArrayAddress + index * sizeof(Moby);
		}
	}
}
