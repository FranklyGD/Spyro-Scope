using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;

namespace SpyroScope {
	static struct Emulator {
		static Windows.ProcessHandle processHandle;
		static Windows.HModule moduleHandle; // Also contains the base address directly

		public enum EmulatorType {
			None,
			NocashPSX,
			Bizhawk,
			ePSXe
		}
		public static EmulatorType emulator;
		static uint emulatorRAMBaseAddress;
		
		public const String[4] emulatorNames = .(String.Empty, "Nocash PSX", "Bizhawk", "ePSXe");

		public enum SpyroROM {
			None,
			SpyroTheDragon_NTSC_U,
			SpyroTheDragon_NTSC_J,
			SpyroTheDragon_PAL,
			RiptosRage_NTSC_U,
			RiptosRage_NTSC_J,
			RiptosRage_PAL,
			YearOfTheDragon_1_0_NTSC_U,
			YearOfTheDragon_1_1_NTSC_U,
			YearOfTheDragon_1_0_PAL,
			YearOfTheDragon_1_1_PAL
		}
		public static SpyroROM rom;

		public struct Address : uint32 {
			public override void ToString(String strBuffer) {
				strBuffer.AppendF("{:X8}", (uint32)this);
			}

			public bool IsNull { get {
				return this == 0;
			} }
		}
		public struct Address<T> : Address {
			public override void ToString(String strBuffer) {
				base.ToString(strBuffer);
			}

			public void Read(T* buffer) {
				ReadFromRAM(this, buffer, sizeof(T));
			}

			public void ReadArray(T* buffer, int count) {
				ReadFromRAM(this, buffer, sizeof(T) * count);
			}

			public void Write(T* buffer) {
				WriteToRAM(this, buffer, sizeof(T));
			}
		}

		// Begin Spyro games information

		public const Address<char8>[10] testAddresses = .(0/*StD*/, 0, 0, (.)0x80066ea8/*RR*/, 0, 0, (.)0x8006c3b0, (.)0x8006c490/*YotD-1.1*/, 0, 0); //!!
		public const String[11] gameNames = .(String.Empty, "Spyro the Dragon (NTSC-U)", "Spyro the Dragon (NTSC-J)", "Spyro the Dragon (PAL)", "Spyro: Ripto's Rage (NTSC-U)", "Spyro and Sparx: Tondemo Tours (NTSC-J)", "Spyro: Gateway to Glimmer (PAL)", "Spyro: Year of the Dragon (v1.0 NTSC-U)", "Spyro: Year of the Dragon (v1.1 NTSC-U)", "Spyro: Year of the Dragon (v1.0 PAL)", "Spyro: Year of the Dragon (v1.1 PAL)");

		public const Address<uint32>[11] gameStateAddresses = .(0, 0/*StD*/, 0, 0, (.)0x800681c8/*RR*/, 0, 0, (.)0x8006e344, (.)0x8006e424/*YotD-1.1*/, 0, 0); //Added both 1.1 and 1.0 since master and dev-frank branch does not include it.

		public const Address<VectorInt>[11] spyroPositionAddresses = .(0, 0/*StD*/, 0, 0, (.)0x80069ff0/*RR*/, 0, 0, (.)0x80070328, (.)0x80070408/*YotD-1.1*/, 0, 0); //!!
		public const Address<MatrixInt>[11] spyroMatrixAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8006a020/*RR*/, 0, 0, (.)0x80070358, (.)0x80070438/*YotD-1.1*/, 0, 0); //!!
		public const Address<VectorInt>[11] spyroIntendedVelocityAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8006a084/*RR*/, 0, 0, (.)0x800703B4, (.)0x80070494/*YotD-1.1*/, 0, 0); //!!
		public const Address<VectorInt>[11] spyroPhysicsVelocityAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8006a090/*RR*/, 0, 0, (.)0x800703c0, (.)0x800704a0/*YotD-1.1*/, 0, 0); //!!

		public const Address<Address>[11] objectArrayPointers = .(0, 0/*StD*/, 0, 0, (.)0x80066f14/*RR*/, 0, 0, (.)0x8006c550, (.)0x8006c630/*YotD-1.1*/, 0, 0); //!!
		public const Address<Address>[11] modelPointers = .(0, 0/*StD*/, 0, 0, (.)0x80068c94/*RR*/, 0, 0, (.)0x8006ee2c, (.)0x8006ef0c/*YotD-1.1*/, 0, 0); //!!

		public const Address<VectorInt>[11] cameraPositionAddress = .(0, 0/*StD*/, 0, 0, (.)0x80067eac/*RR*/, 0, 0, (.)0x8006e020, (.)0x8006e100/*YotD-1.1*/, 0, 0); //!!
		public const Address<int16[3]>[11] cameraEulerRotationAddress = .(0, 0/*StD*/, 0, 0, (.)0x80067ec8/*RR*/, 0, 0, (.)0x8006e03c, (.)0x8006e11c/*YotD-1.1*/, 0, 0); //!!
		public const Address<MatrixInt>[11] cameraMatrixAddress = .(0, 0/*StD*/, 0, 0, (.)0x80067e98/*RR*/, 0, 0, (.)0x8006e00c, (.)0x8006e0ec/*YotD-1.1*/, 0, 0); //!!

		public const Address<uint32>[11] currentWorldIdAddress = .(0, 0/*StD*/, 0, 0, (.)0x80066f54/*RR*/, 0, 0, (.)0x8006e58c, (.)0x8006c66c/*YotD-1.1*/, 0, 0); //!!
		public const Address<uint32>[4] currentSubWorldIdAddress = .((.)0x8006c5c8, (.)0x8006c6a8, (.)0, (.)0); // Exclusive to Spyro: Year of the Dragon //!!

		public const Address<Address>[11] collisionDataPointers = .(0, 0/*StD*/, 0, 0, (.)0x800673fc/*RR*/, 0, 0, (.)0x8006d070, (.)0x8006d150/*YotD-1.1*/, 0, 0); //!!
		public const Address<Address>[11] collisionFlagsArrayPointers = .(0, 0/*StD*/, 0, 0, (.)0x800673e8/*RR*/, 0, 0, (.)0x8006d05c, (.)0x8006d13c/*YotD-1.1*/, 0, 0); //!!
		public const Address<Address>[11] collisionModifyingDataPointers = .(0, 0/*StD*/, 0, 0, (.)0x80068208/*RR*/, 0, 0, (.)0x8006e384, (.)0x8006e464/*YotD-1.1*/, 0, 0); //!!
		
		public const Address<uint32>[11] deathPlaneHeightsAddresses = .(0, 0/*StD*/, 0, 0, (.)0x80060234/*RR*/, 0, 0, (.)0x800676e8, (.)0x800677c8/*YotD-1.1*/, 0, 0); //!!
		public const Address<uint32>[11] maxFreeflightHeightsAddresses = .(0, 0/*StD*/, 0, 0, (.)0x800601b4/*RR*/, 0, 0, (.)0x80067648, (.)0x80067728/*YotD-1.1*/, 0, 0); //!!

		public const Address<uint32>[11] healthAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8006A248/*RR*/, 0, 0, (.)0x800705a8, (.)0x80070688/*YotD-1.1*/, 0, 0); //!!

		public const Address<uint32>[11] gameInputAddress = .(0, 0/*StD*/, 0, 0, (.)0x8001291c/*RR*/, 0, 0, 0, (.)0x8003a7a0/*YotD-1.1*/, 0, 0); //Added 1.1 since master and dev-frank branch does not include it. **
		public const uint32[11] gameInputValue = .(0, 0/*StD*/, 0, 0, 0xac2283a0/*RR*/, 0, 0, 0, 0xae220030/*YotD-1.1*/, 0, 0); // **Address also may be wrong so, look at in future reference!!

		// Game Values
		public static uint32 gameState;

		public static VectorInt cameraPosition, spyroPosition;
		public static VectorInt spyroIntendedVelocity, spyroPhysicsVelocity;
		public static int16[3] cameraEulerRotation;
		public static MatrixInt cameraBasisInv, spyroBasis;
		public static int32 collidingTriangle = -1;

		public static uint32[] deathPlaneHeights ~ delete _;
		public static uint32[] maxFreeflightHeights ~ delete _;
		
		public static Address collisionDataAddress;
		public static Address collisionModifyingPointerArrayAddress;
		public static List<PackedTriangle> collisionTriangles = new .() ~ delete _;
		public static uint32 specialTerrainTriangleCount;
		public static List<uint8> collisionFlagsIndices = new .() ~ delete _;
		public static List<Address> collisionFlagPointerArray = new .() ~ delete _;

		// Game Constants
		public static (String label, Renderer.Color color)[11] collisionTypes = .(
			("Sink", 		.(255, 255, 64)),
			("Hot", 		.(255, 64, 64)),
			("Road", 		.(64, 64, 64)),
			("Trigger", 	.(255, 64, 255)),
			("Ice", 		.(64, 255, 255)),
			("Barrier", 	.(128, 128, 255)),
			("Portal", 		.(64, 255, 64)),
			("Electric", 	.(64, 64, 255)),
			("Ladder", 		.(128, 92, 64)),
			("Ramp", 		.(128, 255, 64)),
			("Slip", 		.(64, 64, 128))
		);
		
		// Function Overrides
		public const Address<uint32>[11] spyroUpdateAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8001b0c4/*RR*/, 0, 0, (.)0x800552f4, (.)0x80055384/*YotD-1.1*/, 0, 0); //!!
		public const uint32[11] spyroUpdateJumpValue = .(0, 0/*StD*/, 0, 0, 0x0c00a81f/*RR*/, 0, 0, 0x0c00fa0f, 0x0c00fa18/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] cameraUpdateAddresses = .(0, 0/*StD*/, 0, 0, (.)0x8001b110/*RR*/, 0, 0, (.)0x80055340, (.)0x800553d0/*YotD-1.1*/, 0, 0); //!!
		public const uint32[11] cameraUpdateJumpValue = .(0, 0/*StD*/, 0, 0, 0x0c00761f/*RR*/, 0, 0, 0x0c004813, 0x0c004818/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] updateAddresses = .(0, 0/*StD*/, 0, 0, (.)0x80011af4/*RR*/, 0, 0, (.)0x80012024, (.)0x80012038/*YotD-1.1*/, 0, 0); //!!
		public const uint32[11] updateJumpValue = .(0, 0/*StD*/, 0, 0, 0x0c006c50/*RR*/, 0, 0, 0x0c015500, 0x0c015524/*YotD-1.1*/, 0, 0);

		// Code Injections
		public const Address<uint32> stepperAddress = (.)0x80009000;
		public static uint32[] stepperLogic = new .(
			0x27bdfff8, // addiu sp, -0x8
			0xafbf0000, // sw ra, 0x0($sp)
			0x3c028001, // lui v0, 0x8000
			0x24429000, // addiu v0, 0x9000
			0xafa20004, // sw v0, 0x4($sp)
			0x8c430020, // lw v1, 0x9020(v0)
			0x00000000, // _nop
			0x10600003, // beq v1, z0, 0x3
			0x00000000, // _nop
			0x00000000, // jal ??? [set externally]
			0x00000000, // _nop
			0x8fa20004, // lw v0, 0x4($sp)
			0x00000000, // _nop
			0xac400020, // sw v1, 0x9020(v0)
			0x8fbf0000, // lw ra, 0x0($sp)
			0x27bd0008, // addiu sp, 0x8
			0x03e00008, // jr ra
			0x00000000, // _nop
		) ~ delete _;
		public static bool stepperInjected;

		public static bool PausedMode { get {
			uint32 value = ?;
			ReadFromRAM(updateAddresses[(int)rom], &value, 4);
			return value != updateJumpValue[(int)rom];
		} }

		public static bool CameraMode { get {
			uint32 value = ?;
			ReadFromRAM(cameraUpdateAddresses[(int)rom], &value, 4);
			return value != cameraUpdateJumpValue[(int)rom];
		} }

		public static bool InputMode { get {
			uint32 value = ?;
			ReadFromRAM(gameInputAddress[(int)rom], &value, 4);
			return value != gameInputValue[(int)rom];
		} }

		// Events
		public static Action OnSceneChanged;

		public static void FindEmulator() {
			processHandle.Close();
			processHandle = 0;
			moduleHandle = 0;

			emulator = .None;
			rom = .None;

			let activeProcesses = scope List<Process>();
			if (Process.GetProcesses(activeProcesses) == .Err) {
				Debug.FatalError("Failed to get process list");
			}

			for (let process in activeProcesses) {
				switch (process.ProcessName) {
					case "NO$PSX.EXE":
						emulator = .NocashPSX;
					case "EmuHawk.exe":
						emulator = .Bizhawk;
					case "ePSXe.exe":
						emulator = .ePSXe;
				}

				if (emulator != .None) {
					processHandle = Windows.OpenProcess(Windows.PROCESS_ALL_ACCESS, false, process.Id);
					break;
				}
			}
			DeleteAndClearItems!(activeProcesses);

			switch (emulator) {
				case .NocashPSX:
					moduleHandle = GetModule(processHandle, "NO$PSX.EXE");
				case .ePSXe:
					moduleHandle = GetModule(processHandle, "ePSXe.exe");
				case .Bizhawk:
					moduleHandle = GetModule(processHandle, "octoshock.dll");
				default:
					return;
			}

			if (moduleHandle.IsInvalid) {
				processHandle.Close();
				processHandle = 0;
				moduleHandle = 0;

				emulator = .None;
				rom = .None;
			}
		}

		public static void FindGame() {
			FetchRAMBaseAddress();
			
			for (int i < 10) {
				let test = scope String();
				let testPtr = test.PrepareBuffer(5);
				ReadFromRAM(testAddresses[i], testPtr, 5);

				if (test.CompareTo("Spyro", true) == 0) {
					rom = (.)(i + 1);
					break;
				}
			}

			if (rom != .None) {
				FetchStaticData();
			}
		}
		
		[Import("psapi.lib"),CLink, CallingConvention(.Stdcall)]
		static extern Windows.IntBool EnumProcessModules(Windows.ProcessHandle process, Windows.HModule* module, uint16 size, uint32* sizeNeeded);
		[Import("psapi.lib"),CLink, CallingConvention(.Stdcall)]
		static extern Windows.IntBool GetModuleFileNameExA(Windows.ProcessHandle process, Windows.HModule module, char8* buffer, uint32 size);

		static Windows.HModule GetModule(Windows.ProcessHandle process, String moduleName) {
			Windows.HModule[512] modules = ?;
			uint32 sizeNeeded = ?;

			if (EnumProcessModules(process, &modules[0], sizeof(Windows.HModule[512]), &sizeNeeded)) {
				for (let i < sizeNeeded / sizeof(Windows.HModule)) {
					let module = modules[i];
				    String modName = scope .();
					let ptr = modName.PrepareBuffer(1024);
				    if (GetModuleFileNameExA(process, module, ptr, 1024) && modName.Contains(moduleName)) {
				  		return module;
				    }
				}
			}

			return 0;
		}

		public static void CheckEmulatorStatus() {
			int32 exitCode;
			if (Windows.GetExitCodeProcess(processHandle, out exitCode) && exitCode != 259 /*STILL_ACTIVE*/) {
				emulator = .None;
				rom = .None;
			}
		}

		public static void UnbindFromEmulator() {
			if (emulator != .None) {
				RestoreCameraUpdate();
				RestoreInputRelay();
				RestoreUpdate();
			}
		}

		public static void FetchRAMBaseAddress() {
			switch (emulator) {
				case .NocashPSX : {
					// uint8* pointer = (uint8*)(void*)(moduleHandle + 0x00091E10)
					// No need to use module base address since its always loaded at 0x00400000
					uint8* pointer = (uint8*)(void*)0x00491E10;
					Windows.ReadProcessMemory(processHandle, pointer, &pointer, 4, null);
					pointer -= 0x1fc;
					Windows.ReadProcessMemory(processHandle, pointer, &emulatorRAMBaseAddress, 4, null);
				}
				case .Bizhawk : {
					// Static address
					emulatorRAMBaseAddress = (.)moduleHandle + 0x0030DF90;
				}
				case .ePSXe : {
					// Static address
					emulatorRAMBaseAddress = (.)moduleHandle + 0x00A82020;
				}

				case .None: {
					// Can't do much if you don't have an emulator to work with
				}
			}
		}

		[Inline]
		public static void* RawAddressFromRAM(Address address) {
			return ((uint8*)null + emulatorRAMBaseAddress + ((uint32)address & 0x003fffff));
		}

		public static void ReadFromRAM(Address address, void* buffer, int size) {
			let rawAddress = RawAddressFromRAM(address);
			Windows.ReadProcessMemory(processHandle, rawAddress, buffer, size, null);
		}

		public static void WriteToRAM(Address address, void* buffer, int size) {
			let rawAddress = RawAddressFromRAM(address);
			Windows.WriteProcessMemory(processHandle, rawAddress, buffer, size, null);
		}

		// Spyro
		static void FetchStaticData() {
			delete Emulator.maxFreeflightHeights;
			delete Emulator.deathPlaneHeights;

			switch (Emulator.rom) {
				case .RiptosRage_NTSC_U: {
					// 28 worlds exists but there is space for 32 (probably a power of 2 related thing)
					Emulator.deathPlaneHeights = new .[32];
					Emulator.maxFreeflightHeights = new .[32];
					
					deathPlaneHeightsAddresses[(int)rom].ReadArray(&Emulator.deathPlaneHeights[0], 32);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&Emulator.maxFreeflightHeights[0], 32);
				}
			case .YearOfTheDragon_1_1_NTSC_U: {
				Emulator.deathPlaneHeights = new .[40 * 4];
				Emulator.maxFreeflightHeights = new .[40 * 4];

				deathPlaneHeightsAddresses[(int)rom].ReadArray(&Emulator.deathPlaneHeights[0], 40 * 4);
				maxFreeflightHeightsAddresses[(int)rom].ReadArray(&Emulator.maxFreeflightHeights[0], 40);
			}
				default : {}
			}
		}

		public static void FetchImportantObjects() {
			gameStateAddresses[(int)rom].Read(&gameState);
			spyroPositionAddresses[(int)rom].Read(&spyroPosition);
			spyroMatrixAddresses[(int)rom].Read(&spyroBasis);
			spyroIntendedVelocityAddresses[(int)rom].Read(&spyroIntendedVelocity);
			spyroPhysicsVelocityAddresses[(int)rom].Read(&spyroPhysicsVelocity);

			cameraPositionAddress[(int)rom].Read(&cameraPosition);
			cameraMatrixAddress[(int)rom].Read(&cameraBasisInv);
			cameraEulerRotationAddress[(int)rom].Read(&cameraEulerRotation);

			//ReadFromRAM((.)0x8006a28c, &collidingTriangle, 4);

			Address newCollisionDataAddress = ?;
			collisionDataPointers[(int)rom].Read(&newCollisionDataAddress);
			if (newCollisionDataAddress != 0 && newCollisionDataAddress != collisionDataAddress) {
				Thread.Sleep(500); // This is mainly needed for when emulators load snapshots/savestates
				// as there is a big delay when loading the large data at once

				uint32 triangleCount = ?;
				ReadFromRAM(newCollisionDataAddress, &triangleCount, 4);

				if (triangleCount > 0x10000) {
					return;
				}
				collisionDataAddress = newCollisionDataAddress;

				ReadFromRAM(collisionDataAddress + 4, &specialTerrainTriangleCount, 4);

				collisionTriangles.Clear();
				let ptrTriangles = collisionTriangles.GrowUnitialized(triangleCount);
				Address collisionTriangleArray = ?;
				ReadFromRAM(collisionDataAddress + 20, &collisionTriangleArray, 4);
				ReadFromRAM(collisionTriangleArray, ptrTriangles, sizeof(PackedTriangle) * triangleCount);
				
				Address collisionFlagArray = ?;

				collisionFlagsIndices.Clear();
				let ptrFlagIndices = collisionFlagsIndices.GrowUnitialized(triangleCount);
				ReadFromRAM(collisionDataAddress + 24, &collisionFlagArray, 4);
				ReadFromRAM(collisionFlagArray, ptrFlagIndices, 1 * triangleCount);

				collisionFlagPointerArray.Clear();
				let ptrFlags = collisionFlagPointerArray.GrowUnitialized(0x3f);
				ReadFromRAM(collisionFlagsArrayPointers[(uint)rom], &collisionFlagArray, 4);
				ReadFromRAM(collisionFlagArray, ptrFlags, 4 * 0x3f);

				OnSceneChanged();
			}
		}

		public static void SetSpyroPosition(VectorInt* position) {
			spyroPositionAddresses[(int)rom].Write(position);
		}

		public static void KillSpyroUpdate() {
			uint32 v = 0;
			spyroUpdateAddresses[(int)rom].Write(&v);
		}

		public static void RestoreSpyroUpdate() {
			uint32 v = spyroUpdateJumpValue[(int)rom];
			spyroUpdateAddresses[(int)rom].Write(&v);
		}

		// Main Update
		public static void KillUpdate() {
			uint32 v = stepperInjected ? 0x0C002400 : 0;
			updateAddresses[(int)rom].Write(&v);
		}

		public static void RestoreUpdate() {
			uint32 v = updateJumpValue[(int)rom];
			updateAddresses[(int)rom].Write(&v);
		}

		// Camera
		public static void KillCameraUpdate() {
			uint32 v = 0;
			cameraUpdateAddresses[(int)rom].Write(&v);
		}

		public static void RestoreCameraUpdate() {
			uint32 v = cameraUpdateJumpValue[(int)rom];
			cameraUpdateAddresses[(int)rom].Write(&v);
		}

		public static void SetCameraPosition(VectorInt* position) {
			cameraPositionAddress[(int)rom].Write(position);
		}

		// Input
		public static void KillInputRelay() {
			uint32 v = 0;
			gameInputAddress[(int)rom].Write(&v);

			// Beyond the point of this function being called
			// input should be written into RAM from the program

			// Currently it still receives input elsewhere
			// even after this is called
		}

		public static void RestoreInputRelay() {
			uint32 v = gameInputValue[(int)rom];
			gameInputAddress[(int)rom].Write(&v);
		}

		// Logic
		public static void InjectStepperLogic() {
			WriteToRAM(stepperAddress, &stepperLogic[0], 4 * stepperLogic.Count);
			uint32 v = 0x0C002400; // (stepperAddress & 0x0fffffff) >> 2;
			updateAddresses[(int)rom].Write(&v);
			stepperInjected = true;
		}

		public static void Step() {
			if (!stepperInjected) {
				InjectStepperLogic();
			}
			KillUpdate();
			uint32 v = updateJumpValue[(int)rom];
			WriteToRAM(stepperAddress + (8 * 4), &v, 4);
		}
	}
}
