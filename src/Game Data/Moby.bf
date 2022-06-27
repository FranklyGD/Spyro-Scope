using System;
using System.Collections;
using System.IO;

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
		public uint8 size; // 79
		public uint8 heldGemValue; // 80
		uint8 m; // 81
		uint8 n; // 82
		uint8 o; // 83
		public Color4 color;

		// Derived from Spyro: Ripto's Rage [8001d068]
		public bool HasModel { [Inline] get => objectTypeID < 0x300; }
		// Derived from Spyro: Year of the Dragon [80030410]
		public bool IsActive { [Inline] get => updateState > -1; }
		
		public bool IsNull { [Inline] get => dataPointer.IsNull; }

		public bool IsTerminator { [Inline] get => IsNull || updateState == -1; }

		public static List<Moby> allocated = new .() ~ delete _;
		
		static Dictionary<uint16, MobyModelSet> modelSets = new .() ~ delete _;

		public float scale { get { return Emulator.active.installment == .SpyroTheDragon || size == 0 ? 1 : (float)0x20 / size; } }

		public Matrix3 basis { get { return .Euler(
			-(float)eulerRotation.x / 0x80 * Math.PI_f,
			(float)eulerRotation.y / 0x80 * Math.PI_f,
			-(float)eulerRotation.z / 0x80 * Math.PI_f
		) * scale; } }

		public void Draw() {
			if (HasModel) {
				if (modelSets.ContainsKey(objectTypeID)) {
					modelSets[objectTypeID].QueueInstance(modelID, .Transform(position, basis), IsActive ? .(1,1,1) : .(0.125f,0.125f,0.125f), Emulator.active.shinyColors[color.r % 10][1]);
				} else {
					Emulator.Address modelSetAddress = ?;
					Emulator.active.mobyModelArrayPointer.GetAtIndex(&modelSetAddress, objectTypeID);

					if (!modelSetAddress.IsNull) {
						modelSets.Add(objectTypeID, new .(modelSetAddress));
					}
				}
			}
		}

		public void DrawOriginAxis() {
			let basis = basis;
			DrawUtilities.Axis(position, basis * .Scale(200));

			// Is object rendering in game?
			Vector3 tint;
			float scale;

			if (draw) {
				scale = 60;
				tint = .(1,0,1);
			} else {
				scale = 50;
				tint = IsActive ? .(0,1,1) : .(0.125f,0.125f,0.125f);
			}

			Matrix4 matrix = .Transform(position, basis * .Scale(scale));

			Renderer.opaquePass.AddJob(PrimitiveShape.cube) .. AddInstance(matrix, tint);
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
						Emulator.active.mobyArrayPointer.Read(&objPointer);
						Emulator.active.ReadFromRAM(objPointer + objectIndex * sizeof(Moby), &linkedMoby, sizeof(Moby));

						Renderer.Line(position, linkedMoby.position, .(255,255,255), .(255,255,255));
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
				let job = Renderer.opaquePass.AddJob(PrimitiveShape.cylinder);

				uint8[] dataBytes = scope .[4 * 4 * waypointCount];
				Emulator.active.ReadFromRAM(pathArrayPointer + 12, &dataBytes[0], 4 * 4 * waypointCount);
				for (let i < waypointCount) {
					let position = *(Vector3Int*)&dataBytes[4 * 4 * i];

					job.AddInstance(.Transform(position, .Scale(500,500,50)), Vector3(1,0.5f,0));
					
					if (i == 0) {
						job.AddInstance(.Transform(position, .Scale(400,400,100)), Vector3(0,1,0));
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

		public static void ClearModels() {
			for (let modelSet in modelSets.Values) {
				delete modelSet;
			}
			modelSets.Clear();
		}

		public void ExportObjectModel() {
			if (!HasModel) return;

			let modelSet = Moby.modelSets[objectTypeID];
			if (modelSet.texturedModels.Count == 0) return;

			let dialog = new SaveFileDialog();
			dialog.FileName = "model";
			dialog.SetFilter("Polygon (*.ply)|*.ply|All files (*.*)|*.*");
			dialog.OverwritePrompt = true;
			dialog.CheckFileExists = true;
			dialog.AddExtension = true;
			dialog.DefaultExt = "ply";

			switch (dialog.ShowDialog()) {
				case .Ok(let val):
					if (val == .OK) {
						modelSet.Export(dialog.FileNames[0], modelID, scale);
					}
				case .Err:
			}

			delete dialog;
		}
	}
}
