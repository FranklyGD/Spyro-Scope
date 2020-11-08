using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;

namespace SpyroScope {
	static struct Emulator {
		static Windows.ProcessHandle processHandle;
		static Windows.HModule moduleHandle; // Also contains the base address directly
		
		public const String[5] emulatorNames = .(String.Empty, "Nocash PSX", "Bizhawk", "ePSXe", "Mednafen");
		public enum EmulatorType {
			None,
			NocashPSX,
			Bizhawk,
			ePSXe,
			Mednafen
		}
		public static EmulatorType emulator;
		static uint emulatorRAMBaseAddress;
		static uint emulatorVRAMBaseAddress;
		static public uint16[] vramSnapshot ~ delete _;
		

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

		public enum SpyroInstallment {
			None,
			SpyroTheDragon,
			RiptosRage,
			YearOfTheDragon
		}
		public static SpyroInstallment installment;

		public struct Address : uint32 {
			public override void ToString(String strBuffer) {
				strBuffer.AppendF("{:X8}", (uint32)this);
			}

			public bool IsNull { get => this == 0; }
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

		public const String[8] pointerLabels = .(
			"Terrain Mesh",
			"Terrain Deform",
			"Terrain Collision",
			"Terrain Collision Flags",
			"Terrain Collision Deform",
			"Textures",
			"Texture Scrollers",
			"Texture Swappers"
		);
		public static Address[8] loadedPointers;
		public static bool[8] changedPointers;
		public const Address<Address>[8][11] pointerSets = .(
			sceneRegionPointers,
			sceneRegionDeformPointers,
			collisionDataPointers,
			collisionFlagsArrayPointers,
			collisionDeformDataPointers,
			textureDataPointers,
			textureScrollerPointers,
			textureSwapperPointers
		);

		public enum LoadingStatus {
			Idle,
			Loading,
			Done
		}
		public static LoadingStatus loadingStatus;

		// Begin Spyro games information
		
		public const Address<char8>[10] testAddresses = .((.)0x800103e7/*StD*/, 0, 0, (.)0x80066ea8/*RR*/, 0, 0, (.)0x8006c3b0, (.)0x8006c490/*YotD-1.1*/, 0, 0);
		public const String[11] gameNames = .(String.Empty, "Spyro the Dragon (NTSC-U)", "Spyro the Dragon (NTSC-J)", "Spyro the Dragon (PAL)", "Spyro: Ripto's Rage (NTSC-U)", "Spyro and Sparx: Tondemo Tours (NTSC-J)", "Spyro: Gateway to Glimmer (PAL)", "Spyro: Year of the Dragon (v1.0 NTSC-U)", "Spyro: Year of the Dragon (v1.1 NTSC-U)", "Spyro: Year of the Dragon (v1.0 PAL)", "Spyro: Year of the Dragon (v1.1 PAL)");

		public const Address<int32>[11] gameStateAddresses = .(0, (.)0x800757d8/*StD*/, 0, 0, (.)0x800681c8/*RR*/, 0, 0, (.)0x8006e344, (.)0x8006e424/*YotD-1.1*/, 0, 0);
		public const Address<int32>[11] loadStateAddresses = .(0, (.)0x80075864/*StD*/, 0, 0, (.)0x80066eec/*RR*/, 0, 0, 0, (.)0x8006c5f8/*YotD-1.1*/, 0, 0);

		public const Address<VectorInt>[11] spyroPositionAddresses = .(0, (.)0x80078a58/*StD*/, 0, 0, (.)0x80069ff0/*RR*/, 0, 0, (.)0x80070328, (.)0x80070408/*YotD-1.1*/, 0, 0);
		public const Address<MatrixInt>[11] spyroMatrixAddresses = .(0, (.)0x80078a8c/*StD*/, 0, 0, (.)0x8006a020/*RR*/, 0, 0, (.)0x80070358, (.)0x80070438/*YotD-1.1*/, 0, 0);
		public const Address<VectorInt>[11] spyroIntendedVelocityAddresses = .(0, (.)0x80078b4c/*StD*/, 0, 0, (.)0x8006a084/*RR*/, 0, 0, (.)0x800703B4, (.)0x80070494/*YotD-1.1*/, 0, 0);
		public const Address<VectorInt>[11] spyroPhysicsVelocityAddresses = .(0, (.)0x80078b64/*StD*/, 0, 0, (.)0x8006a090/*RR*/, 0, 0, (.)0x800703c0, (.)0x800704a0/*YotD-1.1*/, 0, 0);

		public const Address<Address>[11] objectArrayPointers = .(0, (.)0x80075828/*StD*/, 0, 0, (.)0x80066f14/*RR*/, 0, 0, (.)0x8006c550, (.)0x8006c630/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] modelPointers = .(0, 0/*StD*/, 0, 0, (.)0x80068c94/*RR*/, 0, 0, (.)0x8006ee2c, (.)0x8006ef0c/*YotD-1.1*/, 0, 0); //!!

		public const Address<VectorInt>[11] cameraPositionAddress = .(0, (.)0x80076df8/*StD*/, 0, 0, (.)0x80067eac/*RR*/, 0, 0, (.)0x8006e020, (.)0x8006e100/*YotD-1.1*/, 0, 0);
		public const Address<int16[3]>[11] cameraEulerRotationAddress = .(0, (.)0x80076e1c/*StD*/, 0, 0, (.)0x80067ec8/*RR*/, 0, 0, (.)0x8006e03c, (.)0x8006e11c/*YotD-1.1*/, 0, 0);
		public const Address<MatrixInt>[11] cameraMatrixAddress = .(0, (.)0x80076de4/*StD*/, 0, 0, (.)0x80067e98/*RR*/, 0, 0, (.)0x8006e00c, (.)0x8006e0ec/*YotD-1.1*/, 0, 0);

		public const Address<uint32>[11] currentWorldIdAddress = .(0, (.)0x80075964/*StD*/, 0, 0, (.)0x80066f54/*RR*/, 0, 0, (.)0x8006e58c, (.)0x8006c66c/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[4] currentSubWorldIdAddress = .((.)0x8006c5c8, (.)0x8006c6a8, (.)0, (.)0); // Exclusive to Spyro: Year of the Dragon.

		public const Address<Address>[11] collisionDataPointers = .(0, (.)0x800785d4/*StD*/, 0, 0, (.)0x800673fc/*RR*/, 0, 0, (.)0x8006d070, (.)0x8006d150/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] collisionFlagsArrayPointers = .(0, (.)0x800785b8/*StD*/, 0, 0, (.)0x800673e8/*RR*/, 0, 0, (.)0x8006d05c, (.)0x8006d13c/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] collisionDeformDataPointers = .(0, (.)0x800785a4/*StD*/, 0, 0, (.)0x80068208/*RR*/, 0, 0, (.)0x8006e384, (.)0x8006e464/*YotD-1.1*/, 0, 0);

		public const Address<Address>[11] sceneRegionPointers = .(0, (.)0x800785a8/*StD*/, 0, 0, (.)0x800673d4/*RR*/, 0, 0, 0, (.)0x8006d128/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] sceneRegionDeformPointers = .(0, (.)0x80078584/*StD*/, 0, 0, (.)0x800681f8/*RR*/, 0, 0, 0, (.)0x8006e454/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] warpingRegionPointers = .(0, 0/*StD*/, 0, 0, (.)0x800673f0/*RR*/, 0, 0, 0, (.)0x8006d144/*YotD-1.1*/, 0, 0);
		
		public const Address<Address>[11] textureDataPointers = .(0, (.)0x800785c4/*StD*/, 0, 0, (.)0x800673f4/*RR*/, 0, 0, 0, (.)0x8006d148/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] textureScrollerPointers = .(0, (.)0x8007856c/*StD*/, 0, 0, (.)0x800681e0/*RR*/, 0, 0, 0, (.)0x8006e43c/*YotD-1.1*/, 0, 0);
		public const Address<Address>[11] textureSwapperPointers = .(0, (.)0x80078564/*StD*/, 0, 0, (.)0x800681d8/*RR*/, 0, 0, 0, (.)0x8006e434/*YotD-1.1*/, 0, 0);

		public const Address<uint32>[11] deathPlaneHeightsAddresses = .(0, (.)0x8006e9a4/*StD*/, 0, 0, (.)0x80060234/*RR*/, 0, 0, (.)0x800676e8, (.)0x800677c8/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] maxFreeflightHeightsAddresses = .(0, 0/*StD*/, 0, 0, (.)0x800601b4/*RR*/, 0, 0, (.)0x80067648, (.)0x80067728/*YotD-1.1*/, 0, 0);

		public const Address<uint32>[11] healthAddresses = .(0, (.)0x80078bbc/*StD*/, 0, 0, (.)0x8006A248/*RR*/, 0, 0, (.)0x800705a8, (.)0x80070688/*YotD-1.1*/, 0, 0);

		public const Address<uint32>[11] gameInputAddress = .(0, 0/*StD*/, 0, 0, (.)0x8001291c/*RR*/, 0, 0, 0, (.)0x8003a7a0/*YotD-1.1*/, 0, 0);
		public const uint32[11] gameInputValue = .(0, 0/*StD*/, 0, 0, 0xac2283a0/*RR*/, 0, 0, 0, 0xae220030/*YotD-1.1*/, 0, 0);

		// Game Values
		public static int32 gameState, loadState;

		public static VectorInt cameraPosition, spyroPosition;
		public static VectorInt spyroIntendedVelocity, spyroPhysicsVelocity;
		public static int16[3] cameraEulerRotation;
		public static MatrixInt cameraBasisInv, spyroBasis;
		public static int32 collidingTriangle = -1;

		public static uint32[] deathPlaneHeights ~ delete _;
		public static uint32[] maxFreeflightHeights ~ delete _;

		public static Address collisionDataAddress;
		public static Address collisionDeformPointerArrayAddress;

		// Game Constants
		public static (String label, Renderer.Color color)[11] collisionTypes = .(
			("Sink", 		.(255, 255, 64)),
			("Hot", 		.(255, 64, 64)),
			("Supercharge", .(64, 64, 64)),
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
		public const Address<uint32>[11] spyroUpdateAddresses = .(0, (.)0x80033ad8/*StD*/, 0, 0, (.)0x8001b0c4/*RR*/, 0, 0, (.)0x800552f4, (.)0x80055384/*YotD-1.1*/, 0, 0);
		public const uint32[11] spyroUpdateJumpValue = .(0, 0x0c012880/*StD*/, 0, 0, 0x0c00a81f/*RR*/, 0, 0, 0x0c00fa0f, 0x0c00fa18/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] cameraUpdateAddresses = .(0, (.)0x80037cfc/*StD*/, 0, 0, (.)0x8001b110/*RR*/, 0, 0, (.)0x80055340, (.)0x800553d0/*YotD-1.1*/, 0, 0);
		public const uint32[11] cameraUpdateJumpValue = .(0, 0x0c00d7ed/*StD*/, 0, 0, 0x0c00761f/*RR*/, 0, 0, 0x0c004813, 0x0c004818/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] updateAddresses = .(0, (.)0x80012230/*StD*/, 0, 0, (.)0x80011af4/*RR*/, 0, 0, (.)0x80012024, (.)0x80012038/*YotD-1.1*/, 0, 0);
		public const uint32[11] updateJumpValue = .(0, 0x0c00ce17/*StD*/, 0, 0, 0x0c006c50/*RR*/, 0, 0, 0x0c015500, 0x0c015524/*YotD-1.1*/, 0, 0);

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
		public static Action OnSceneChanging;

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
					case "mednafen.exe":
						emulator = .Mednafen;
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
				case .Mednafen:
					moduleHandle = GetModule(processHandle, "mednafen.exe");
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

			switch (rom) {
				case .SpyroTheDragon_NTSC_U,
					 .SpyroTheDragon_NTSC_J,
					 .SpyroTheDragon_PAL:
					installment = .SpyroTheDragon;

				case .RiptosRage_NTSC_U,
					 .RiptosRage_NTSC_J,
					 .RiptosRage_PAL:
					installment = .RiptosRage;

				case .YearOfTheDragon_1_0_NTSC_U,
					 .YearOfTheDragon_1_0_PAL,
					 .YearOfTheDragon_1_1_NTSC_U,
					 .YearOfTheDragon_1_1_PAL:
					installment = .YearOfTheDragon;

				default:
					installment = .None;
			}

			if (rom != .None) {
				FetchVRAMBaseAddress();
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

				for (let i < 8) {
					loadedPointers[i] = 0;
					changedPointers[i] = false;
				}
			}
		}

		public static void CheckSources() {
			for (let i < 8) {
				Address newLoadedPointer = ?;
				var pointerSet = pointerSets[i];
				let pointer = pointerSet[(int)Emulator.rom];

				pointer.Read(&newLoadedPointer);
				if (!newLoadedPointer.IsNull && loadedPointers[i] != newLoadedPointer) {
					loadedPointers[i] = newLoadedPointer;
					changedPointers[i] = true;

					if (loadingStatus == .Idle) {
						OnSceneChanging?.Invoke();
					}

					loadingStatus = .Loading;
				}
			}

			if (loadingStatus == .Loading && loadState == -1) {
				loadingStatus = .Done;

				for (let i < 8) {
					changedPointers[i] = false;
				}
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
				case .Mednafen : {
					// Static address
					emulatorRAMBaseAddress = (.)moduleHandle + 0x025BC280;
				}

				case .None: {
					// Can't do much if you don't have an emulator to work with
				}
			}
		}

		public static void FetchVRAMBaseAddress() {
			switch (emulator) {
				case .NocashPSX : {
					// uint8* pointer = (uint8*)(void*)(moduleHandle + 0x00092784)
					// No need to use module base address since its always loaded at 0x00400000
					uint8* pointer = (uint8*)(void*)0x00492784;
					Windows.ReadProcessMemory(processHandle, pointer, &emulatorVRAMBaseAddress, 4, null);
				}
				case .Bizhawk : {
					// Static address
					emulatorVRAMBaseAddress = (.)moduleHandle + 0x005280D0;
				}
				case .ePSXe : {
					// Plugin address
					let gpuModuleHandle = GetModule(processHandle, "gpuPeteOpenGL2.dll");
					emulatorVRAMBaseAddress = (.)gpuModuleHandle + 0x00051F80;
					// NOTE: According to Cheat Engine this should work, however...
					// the module is not being listed and therefore cannot be found
				}
				case .Mednafen : {
					// Static address
					emulatorVRAMBaseAddress = (.)moduleHandle + 0x027d0eb8;
				}
				default : // Well this is awkward...
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
			if (loadingStatus == .Loading) {
				return; // Do not try change anything while loading
			}
			let rawAddress = RawAddressFromRAM(address);
			Windows.WriteProcessMemory(processHandle, rawAddress, buffer, size, null);
		}

		// Spyro
		static void FetchStaticData() {
			delete maxFreeflightHeights;
			delete deathPlaneHeights;

			switch (Emulator.installment) {

				case .SpyroTheDragon: {
					// 35 worlds exist, but there is space for 36. (Probably due to short/int reasons.)
					Emulator.deathPlaneHeights = new .[36];
					Emulator.maxFreeflightHeights = new .[36];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&Emulator.deathPlaneHeights[0], 36);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&Emulator.maxFreeflightHeights[0], 36);
				}

				case .RiptosRage: {
					// 28 worlds exists but there is space for 32 (probably a power of 2 related thing)
					deathPlaneHeights = new .[32];
					maxFreeflightHeights = new .[32];
					
					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 32);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 32);
				}

				case .YearOfTheDragon: {
					// 37 worlds exist, but theres space for 40. (Probably due to short/int reasons.)
					// Also gets multipled by 4 due to sub worlds, there being a minimum of 4 in each homeworld.
					Emulator.deathPlaneHeights = new .[40 * 4];
					Emulator.maxFreeflightHeights = new .[40 * 4];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&Emulator.deathPlaneHeights[0], 40 * 4);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&Emulator.maxFreeflightHeights[0], 40);
				}
				default : {}
			}
		}

		public static void TakeVRAMSnapshot() {
			delete vramSnapshot;
			vramSnapshot = new .[1024 * 512];
			Windows.ReadProcessMemory(processHandle, (void*)emulatorVRAMBaseAddress, &vramSnapshot[0], 1024 * 512 * 2, null);
		}

		public static void FetchImportantData() {
			gameStateAddresses[(int)rom].Read(&gameState);
			loadStateAddresses[(int)rom].Read(&loadState);
			spyroPositionAddresses[(int)rom].Read(&spyroPosition);
			spyroMatrixAddresses[(int)rom].Read(&spyroBasis);
			spyroIntendedVelocityAddresses[(int)rom].Read(&spyroIntendedVelocity);
			spyroPhysicsVelocityAddresses[(int)rom].Read(&spyroPhysicsVelocity);

			cameraPositionAddress[(int)rom].Read(&cameraPosition);
			cameraMatrixAddress[(int)rom].Read(&cameraBasisInv);
			cameraEulerRotationAddress[(int)rom].Read(&cameraEulerRotation);

			//ReadFromRAM((.)0x8006a28c, &collidingTriangle, 4);

			CheckSources();
			if (loadingStatus == .Done) {
				Thread.Sleep(500); // This is mainly needed for when emulators load snapshots/savestates
				// as there is a big delay when loading the large data at once

				loadingStatus = .Idle;
				OnSceneChanged?.Invoke();
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
