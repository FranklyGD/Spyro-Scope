using System;
using System.Collections;
using System.Diagnostics;
using System.Threading;

namespace SpyroScope {
	class Emulator {
		public static Emulator active;
		public static List<Emulator> emulators = new .() ~ DeleteContainerAndItems!(_);

		public Windows.ProcessHandle processHandle;
		public Windows.HModule moduleHandle; // Also contains the base address directly
		
		int emulatorIndex = -1, versionIndex = -1;

		public StringView Name { get => ProcessFound ? EmulatorsConfig.emulators[emulatorIndex].label : ""; }
		public StringView Version { get => versionIndex > -1 ? EmulatorsConfig.emulators[emulatorIndex].versions[versionIndex].label : "Unknown"; }
		public uint MainModuleSize { get; private set; }
		public bool ProcessFound { get => emulatorIndex > -1; }
		public bool Supported { get => ProcessFound && versionIndex > -1; }

		public int RAMBaseAddress;
		public int VRAMBaseAddress;

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
		public SpyroROM rom;

		public enum SpyroInstallment {
			None,
			SpyroTheDragon,
			RiptosRage,
			YearOfTheDragon
		}
		public SpyroInstallment installment;

		public struct Address : uint32 {
			public override void ToString(String strBuffer) {
				strBuffer.AppendF("{:X8}", (uint32)this);
			}

			public bool IsNull { get => this == Null; }

			public const Address Null = 0;

			[Inline]
			public static int32 operator -(Self left, Self right) {
				return (.)left - (.)right;
			}
		}

		public struct Address<T> : Address {
			public override void ToString(String strBuffer) {
				base.ToString(strBuffer);
			}

			public void Read(T* buffer, Emulator emulator = active) {
				emulator.ReadFromRAM(this, buffer, sizeof(T));
			}

			public void ReadArray(T* buffer, int count, Emulator emulator = active) {
				emulator.ReadFromRAM(this, buffer, sizeof(T) * count);
			}

			public void Write(T* buffer, Emulator emulator = active) {
				emulator.WriteToRAM(this, buffer, sizeof(T));
			}

			public void WriteArray(T* buffer, int count, Emulator emulator = active) {
			    emulator.WriteToRAM(this, buffer, sizeof(T) * count);
			}

			public void GetAtIndex(T* buffer, int index, Emulator emulator = active) {
			    emulator.ReadFromRAM(this + index * sizeof(T), buffer, sizeof(T));
			}

			public void SetAtIndex(T* buffer, int index, Emulator emulator = active) {
			    emulator.WriteToRAM(this + index * sizeof(T), buffer, sizeof(T));
			}

			public void ReadRange(T* buffer, int start, int count, Emulator emulator = active) {
			    emulator.ReadFromRAM(this + start * sizeof(T), buffer, count * sizeof(T));
			}

			public void WriteRange(T* buffer, int start, int count, Emulator emulator = active) {
			    emulator.WriteToRAM(this + start * sizeof(T), buffer, count * sizeof(T));
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
		public Address[8] loadedPointers;
		public bool[8] changedPointers;
		public Address<Address>*[8] pointerSets = .(
			&sceneRegionsPointer,
			&farRegionsDeformPointer,
			&collisionDataPointer,
			&collisionFlagsPointer,
			&collisionDeformPointer,
			&textureDataPointer,
			&textureScrollersPointer,
			&textureSwappersPointer
		);

		public enum LoadingStatus {
			Idle,
			Loading,
			CutsceneDone,
			CutsceneIdle,
			Done
		}
		public LoadingStatus loadingStatus;

		// Begin Spyro games information
		
		public const Address<char8>[10] testAddresses = .((.)0x800103e7/*StD*/, 0, 0, (.)0x80066ea8/*RR*/, 0, 0, (.)0x8006c3b0, (.)0x8006c490/*YotD-1.1*/, 0, 0);
		public const String[11] gameNames = .(String.Empty, "Spyro the Dragon (NTSC-U)", "Spyro the Dragon (NTSC-J)", "Spyro the Dragon (PAL)", "Spyro: Ripto's Rage (NTSC-U)", "Spyro and Sparx: Tondemo Tours (NTSC-J)", "Spyro: Gateway to Glimmer (PAL)", "Spyro: Year of the Dragon (v1.0 NTSC-U)", "Spyro: Year of the Dragon (v1.1 NTSC-U)", "Spyro: Year of the Dragon (v1.0 PAL)", "Spyro: Year of the Dragon (v1.1 PAL)");

		public Address<int32> gameStateAddress, loadStateAddress;

		// Spyro
		public Address spyroAddress;

		public Address<Vector3Int> spyroPositionAddress;
		public Address<Vector3Int> spyroEulerAddress;
		public Address<MatrixInt> spyroBasisAddress;

		public Address<Vector3Int> spyroVelocityIntended, spyroVelocityPhysics;

		public Address<uint32> spyroStateAddress;
		//public const Address<Vector3Int>[4] spyroIntendedAirVelocityAddress = .(0, (.)0x80078b40/*StD*/, 0, 0); // Exclusive to Spyro the Dragon
		public const Address<uint32>[4] collisionRadius = .((.)0x8007036c, (.)0x8007044c, 0, 0); // Exclusive to Spyro: Year of the Dragon

		// Objects
		public Address<Address> mobyArrayPointer, mobyModelArrayPointer;

		// Camera
		public Address cameraAddress;
		public Address<Vector3Int> cameraPositionAddress;
		public Address<int16[3]> cameraEulerAddress;
		public Address<MatrixInt> cameraBasisAddress;

		// World
		public const Address<uint32>[11] currentWorldIdAddress = .(0, (.)0x80075964/*StD*/, 0, 0, (.)0x80066f54/*RR*/, 0, 0, (.)0x8006e58c, (.)0x8006c66c/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[4] currentSubWorldIdAddress = .((.)0x8006c5c8, (.)0x8006c6a8, (.)0, (.)0); // Exclusive to Spyro: Year of the Dragon.
		
		public Address<Renderer.Color4> clearColorAddress;
		public Address<Address> textureDataPointer, sceneRegionsPointer, collisionDataPointer, collisionFlagsPointer;
		public Address<Address> textureSwappersPointer, textureScrollersPointer, farRegionsDeformPointer, nearRegionsDeformPointer, collisionDeformPointer;

		// Exclusive to Spyro: Ripto's Rage
		public const Address<uint8>[3] spriteWidthArrayAddress = .((.)0x800634b8, 0, 0);
		public const Address<uint8>[3] spriteHeightArrayAddress = .((.)0x800634d0, 0, 0);
		public const Address<TextureSprite.SpriteFrame>[3] spriteFrameArrayAddress = .((.)0x8006351c, 0, 0);

		public const Address<uint16>[7] spyroFontAddress = .((.)0x800636a4/*RR*/, 0, 0, 0, (.)0x800667c8/*YotD-1.1*/, 0, 0); // Doesn't exist in Spyro the Dragon
		public const Address<Address<TextureQuad>>[4] spriteArrayPointer = .(0, (.)0x8006c868, 0, 0); // Exclusive to Spyro: Year of the Dragon

		public const Address<uint32>[11] deathPlaneHeightsAddresses = .(0, (.)0x8006e9a4/*StD*/, 0, 0, (.)0x80060234/*RR*/, 0, 0, (.)0x800676e8, (.)0x800677c8/*YotD-1.1*/, 0, 0);
		public const Address<uint32>[11] maxFreeflightHeightsAddresses = .(0, 0/*StD*/, 0, 0, (.)0x800601b4/*RR*/, 0, 0, (.)0x80067648, (.)0x80067728/*YotD-1.1*/, 0, 0);

		public Address<uint32> healthAddress;

		public Address<uint32> gameInputAddress;
		//public const Address<uint32>[11] gameInputSetAddress = .(0, 0/*StD*/, 0, 0, (.)0x8001291c/*RR*/, 0, 0, 0, (.)0x8003a7a0/*YotD-1.1*/, 0, 0);
		//public const uint32[11] gameInputValue = .(0, 0/*StD*/, 0, 0, 0xac2283a0/*RR*/, 0, 0, 0, 0xae220030/*YotD-1.1*/, 0, 0);

		public Address<uint32> spyroStateChangeAddress;
		public uint32 spyroStateChangeValue;

		// Game Values
		public int32 gameState, loadState;

		uint32 input;
		public uint32 Input {
			get => input;
			set {
				input = value;
				gameInputAddress.Write(&input, this);
			}
		}

		Vector3Int cameraPosition;
		public Vector3Int CameraPosition {
			get => cameraPosition;
			set {
				cameraPosition = value;
				cameraPositionAddress.Write(&cameraPosition, this);
			}
		}

		Vector3Int spyroPosition;
		/// Current location of Spyro
		public Vector3Int SpyroPosition {
			get => spyroPosition;
			set {
				spyroPosition = value;
				spyroPositionAddress.Write(&spyroPosition, this);
			}
		}

		Vector3Int spyroEulerRotation;
		/// Current rotation of Spyro
		public Vector3Int SpyroEulerRotation {
			get => spyroEulerRotation;
			set {
				spyroEulerRotation = value;
				spyroEulerAddress.Write(&spyroEulerRotation, this);
			}
		}

		uint32 spyroState;
		/// Current state of Spyro
		public uint32 SpyroState {
			get => spyroState;
			set {
				spyroState = value;
				spyroStateAddress.Write(&spyroState, this);
			}
		}

		Vector3Int spyroIntendedVelocity;
		/// The motion the game will test that will make Spyro move
		public Vector3Int SpyroIntendedVelocity {
			get => spyroIntendedVelocity;
			set {
				spyroIntendedVelocity = value;
				spyroVelocityIntended.Write(&spyroIntendedVelocity, this);
			}
		}

		Vector3Int spyroPhysicsVelocity;
		/// The net motion the game makes that will move Spyro
		public Vector3Int SpyroPhysicsVelocity {
			get => spyroPhysicsVelocity;
			set {
				spyroPhysicsVelocity = value;
				spyroVelocityPhysics.Write(&spyroPhysicsVelocity, this);
			}
		}

		public int16[3] cameraEulerRotation;
		public MatrixInt spyroBasis;
		public int32 collidingTriangle = -1;
		
		public Renderer.Color4[10][4] shinyColors;
		public uint32[] deathPlaneHeights ~ delete _;
		public uint32[] maxFreeflightHeights ~ delete _;

		public Address<Moby> objectArrayAddress;

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
		public Address<uint32> spyroUpdateCallAddress, cameraUpdateCallAddress, updateCallAddress;
		public uint32 spyroUpdateCallValue, cameraUpdateCallValue, updateCallValue;

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
		public bool stepperInjected;

		bool paused;
		public bool Paused {
			get {
				return paused;
			}

			set {
				if (value) {
					KillUpdate();
				} else {
					if (!Lockstep) {
						RestoreUpdate();
					}
				}

				paused = value;
			}
		}

		public enum UpdateMode {
			None,
			Normal,
			Manual,
		}

		public UpdateMode UpdateMode { get {
			uint32 value = ?;
			ReadFromRAM(updateCallAddress, &value, 4);
			switch (value) {
				case 0: return .None;
				case updateCallValue: return .Normal;
				default: return .Manual;
			}
		} }

		public bool InStep { get {
			uint32 v = ?;
			ReadFromRAM(stepperAddress + (8 * 4), &v, 4);
			return v > 0;
		} }

		public bool CameraMode { get {
			uint32 value = ?;
			ReadFromRAM(cameraUpdateCallAddress, &value, 4);
			return value != cameraUpdateCallValue;
		} }

		/*public bool InputMode { get {
			uint32 value = ?;
			ReadFromRAM(gameInputSetAddress[(int)rom], &value, 4);
			return value != gameInputValue[(int)rom];
		} }*/

		bool lockstep;
		public bool Lockstep {
			get {
				return lockstep;
			}
			private set {
				if (value) {
					InjectStepperLogic();
				}

				if (!paused) {
					if (value) {
						KillUpdate();
					} else {
						RestoreUpdate();
					}
				}

				lockstep = value;
			}
		}

		// Using lock-step method as the program will be
		// running much faster than the actual emulator speed
		// The emulator will not appear to slow down or lag
		Event<delegate void()> OnStep; 

		// Event Timestamps
		public DateTime lastSceneChanging;
		public DateTime lastSceneChange;

		this(Windows.ProcessHandle process, int emulator) {
			processHandle = process;

			Debug.WriteLine(scope String() .. AppendF("Emulator Process: {}", EmulatorsConfig.emulators[emulator].processName));

			moduleHandle = GetModule(processHandle, EmulatorsConfig.emulators[emulator].processName);

			let mainModuleSize = GetModuleSize(processHandle, moduleHandle);
			Debug.WriteLine(scope String() .. AppendF("Main Module Size: {:x} bytes", mainModuleSize));

			versionIndex = EmulatorsConfig.emulators[emulator].versions.FindIndex(scope (x) => x.moduleSize == mainModuleSize);
			Debug.WriteLine(scope String() .. AppendF("Emulator Version: {}", versionIndex > -1 ? EmulatorsConfig.emulators[emulator].versions[versionIndex].label : "Unknown"));

			emulatorIndex = emulator;

			if (active == null) {
				active = this;
			}

			emulators.Add(this);
		}

		public static void FindProcesses(List<Process> processes) {
			if (Process.GetProcesses(processes) case .Err) {
				Debug.FatalError("Failed to get process list");
			}

			processes.RemoveAll(scope (process) => {
				if (EmulatorsConfig.emulators.FindIndex(scope (x) => x.processName == process.ProcessName) > -1) {
					return false;
				}
				
				delete process;
				return true;
			});
		}

		public static Emulator BindEmulatorProcess(Process process) {
			// Try to open and access the process
			Windows.ProcessHandle processHandle = Windows.OpenProcess(Windows.PROCESS_ALL_ACCESS, false, process.Id);

			let emulatorIndex = EmulatorsConfig.emulators.FindIndex(scope (x) => x.processName == process.ProcessName);

			if (emulatorIndex > -1) {
				return new Emulator(processHandle, emulatorIndex);
			}

			return null;
		}

		public void FindGame() {
			SpyroROM newRom = .None;
			for (int i < 10) {
				let test = scope String();
				let testPtr = test.PrepareBuffer(5);
				ReadFromRAM(testAddresses[i], testPtr, 5);

				if (test.CompareTo("Spyro", true) == 0) {
					newRom = (.)(i + 1);
					break;
				}
			}

			switch (newRom) {
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

			if (newRom != .None && newRom != rom) {
				FetchStaticData();
			}

			rom = newRom;
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
		
		[CRepr]
		struct ModuleInfo {
			public void* baseOfDLL;
			public uint32 sizeOfImage;
			public void* entryPoint;
		}

		[Import("psapi.lib"),CLink, CallingConvention(.Stdcall)]
		static extern Windows.IntBool GetModuleInformation(Windows.ProcessHandle process, Windows.HModule module, ModuleInfo* moduleInfo, uint32 cb);

		static uint32 GetModuleSize(Windows.ProcessHandle process, Windows.HModule module) {
			ModuleInfo info = ?;
			GetModuleInformation(process, module, &info, sizeof(ModuleInfo));

			return info.sizeOfImage;
		}

		public void CheckProcessStatus() {
			int32 exitCode;
			if (Windows.GetExitCodeProcess(processHandle, out exitCode) && exitCode != 259 /*STILL_ACTIVE*/) {
				UnbindEmulatorProcess();
			}
		}

		public void FetchMainAddresses() {
			// Do this once since all emulators have one location for its RAM/VRAM

			if (RAMBaseAddress == 0) {
				FetchRAMBaseAddress();
			}

			if (VRAMBaseAddress == 0) {
				FetchVRAMBaseAddress();
			}

			// NOTE: Careful with getting VRAM once, since some emulators have multiple rendering engine that can be swapped out
		}

		public void CheckSources() {
			for (let i < 8) {
				Address newLoadedPointer = ?;
				let pointer = *pointerSets[i];

				pointer.Read(&newLoadedPointer, this);
				if (!newLoadedPointer.IsNull && loadedPointers[i] != newLoadedPointer) {
					loadedPointers[i] = newLoadedPointer;
					changedPointers[i] = true;

					if (loadingStatus == .Idle) {
						lastSceneChanging = .Now;
					}

					loadingStatus = .Loading;
				}
			}

			if (loadingStatus == .Loading) {
				if (loadState == -1) { // Loaded everything the game needs for a level
					loadingStatus = .Done;
	
					for (let i < 8) {
						changedPointers[i] = false;
					}
					VRAM.upToDate = false;
				} else if (
					installment == .SpyroTheDragon && (gameState == 13 || gameState == 14) ||
					installment != .SpyroTheDragon && (gameState == 6 || gameState == 11)
				) {
					loadingStatus = .CutsceneDone;

					for (let i < 8) {
						changedPointers[i] = false;
					}
					VRAM.upToDate = false;
				}
			}
		}

		public void UnbindEmulatorProcess() {
			if (Supported && rom != .None) {
				RestoreCameraUpdate();
				//RestoreInputRelay();
				RestoreUpdate();
				RestoreSpyroUpdate();
				RestoreSpyroStateChange();
			}

			processHandle.Close();
			processHandle = 0;
			moduleHandle = 0;

			for (let i < 8) {
				loadedPointers[i] = 0;
				changedPointers[i] = false;
			}
		}


		public static void UnbindAllEmulators() {
			for (let emulator in emulators) {
				emulator.UnbindEmulatorProcess();
				delete emulator;
			}

			emulators.Clear();
		}

		public void FetchRAMBaseAddress() {
			if (versionIndex == -1) {
				return;
			}

			let version = EmulatorsConfig.emulators[emulatorIndex].versions[versionIndex];
			let moduleHandle = GetModule(processHandle, version.ramModuleName);

			if (moduleHandle.IsInvalid) {
				return;
			}

			RAMBaseAddress = PointerOffsetsToAddress((.)moduleHandle, version.offsetsToRAM);
		}

		public void FetchVRAMBaseAddress() {
			if (versionIndex == -1) {
				return;
			}

			let version = EmulatorsConfig.emulators[emulatorIndex].versions[versionIndex];
			let moduleHandle = GetModule(processHandle, version.vramModuleName);

			if (moduleHandle.IsInvalid) {
				return;
			}

			VRAMBaseAddress = PointerOffsetsToAddress((.)moduleHandle, version.offsetsToVRAM);
		}

		int PointerOffsetsToAddress(int baseAddress, List<int> offsets) {
			var address = baseAddress;
			address += offsets[0];
			for (var i = 1; i < offsets.Count; i++) {
				Windows.ReadProcessMemory(processHandle, (.)address, &address, 4, null);
				if (address == 0) {
					return 0;
				}
				address += offsets[i];
			}
			return address;
		}

		[Inline]
		public void* RawAddressFromRAM(Address address) {
			return ((uint8*)null + RAMBaseAddress + ((uint32)address & 0x003fffff));
		}

		public void ReadFromRAM(Address address, void* buffer, int size) {
			let rawAddress = RawAddressFromRAM(address);
			Windows.ReadProcessMemory(processHandle, rawAddress, buffer, size, null);
		}

		public void WriteToRAM(Address address, void* buffer, int size) {
			if (loadingStatus == .Loading) {
				return; // Do not try change anything while loading
			}
			let rawAddress = RawAddressFromRAM(address);
			Windows.WriteProcessMemory(processHandle, rawAddress, buffer, size, null);
		}

		// Spyro
		void FetchStaticData() {
			FindAddressLocations();

			delete maxFreeflightHeights;
			delete deathPlaneHeights;

			switch (installment) {
				case .SpyroTheDragon: {
					ReadFromRAM((.)0x8006e44c, &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 35 worlds exist, but there is space for 36. (Probably due to short/int reasons.)
					deathPlaneHeights = new .[36];
					maxFreeflightHeights = new .[36];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 36, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 36, this);
				}

				case .RiptosRage: {
					ReadFromRAM((.)0x80064440, &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 28 worlds exists but there is space for 32 (probably a power of 2 related thing)
					deathPlaneHeights = new .[32];
					maxFreeflightHeights = new .[32];
					
					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 32, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 32, this);
				}

				case .YearOfTheDragon: {
					ReadFromRAM((.)0x80066a70, &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 37 worlds exist, but theres space for 40. (Probably due to short/int reasons.)
					// Also gets multipled by 4 due to sub worlds, there being a minimum of 4 in each homeworld.
					deathPlaneHeights = new .[40 * 4];
					maxFreeflightHeights = new .[40 * 4];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 40 * 4, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 40, this);
				}
				default : {}
			}
		}

		public void FetchImportantData() {
			// Load static address values
			gameStateAddress.Read(&gameState, this);
			loadStateAddress.Read(&loadState, this);

			gameInputAddress.Read(&input, this);

			spyroPositionAddress.Read(&spyroPosition, this);
			spyroEulerAddress.Read(&spyroEulerRotation, this);
			spyroBasisAddress.Read(&spyroBasis, this);
			spyroStateAddress.Read(&spyroState, this);
			spyroVelocityIntended.Read(&spyroIntendedVelocity, this);
			spyroVelocityPhysics.Read(&spyroPhysicsVelocity, this);

			cameraPositionAddress.Read(&cameraPosition, this);
			cameraEulerAddress.Read(&cameraEulerRotation, this);

			//ReadFromRAM((.)0x8006a28c, &collidingTriangle, 4);

			CheckSources();
			if (loadingStatus == .Done || loadingStatus == .CutsceneDone) {
				Thread.Sleep(500); // This is mainly needed for when emulators load snapshots/savestates
				// as there is a big delay when loading the large data at once
				
				loadingStatus = loadingStatus == .CutsceneDone ? .CutsceneIdle : .Idle;
				lastSceneChange = .Now;
			}

			if (!VRAM.upToDate && gameState != (installment == .SpyroTheDragon ? 2 : 4)) {
				VRAM.TakeSnapshot();
			}

			Emulator.Address<Moby> newObjectArrayAddress = ?;
			mobyArrayPointer.Read(&newObjectArrayAddress, this);
			if (objectArrayAddress != newObjectArrayAddress) {
				Moby.allocated.Clear();
			}
			objectArrayAddress = newObjectArrayAddress;

			if (Lockstep && !InStep && !Paused) {
				OnStep();
				Step();
			}
		}

		void FindAddressLocations() {
			// Spyro & Camera Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroCamSignature = scope .();
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.sw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.lw);
			spyroCamSignature.AddInstruction(.sub);
			spyroCamSignature.AddInstruction(.sub);
			spyroCamSignature.AddInstruction(.sub);
			spyroCamSignature.AddInstruction(.lw, 0x0);
			spyroCamSignature.AddInstruction(.lw, 0x4);
			spyroCamSignature.AddInstruction(.lw, 0x8);
			spyroCamSignature.AddInstruction(.lw, 0xc);
			spyroCamSignature.AddInstruction(.lw, 0x10);
			spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0);
			spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1);
			spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2);
			spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3);
			spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);
			
			int32[2] loadAddress = ?;
			MemorySignature.Reg spyroRegister;
			Emulator.Address loadSignatureLocation;
			MemorySignature.Reg cameraRegister;

			Emulator.Address signatureLocation = spyroCamSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroCamSignature.Clear();
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.lw);
				spyroCamSignature.AddInstruction(.sub);
				spyroCamSignature.AddInstruction(.sub);
				spyroCamSignature.AddInstruction(.sub);
				spyroCamSignature.AddInstruction(.lw, 0x0);
				spyroCamSignature.AddInstruction(.lw, 0x4);
				spyroCamSignature.AddInstruction(.lw, 0x8);
				spyroCamSignature.AddInstruction(.lw, 0xc);
				spyroCamSignature.AddInstruction(.lw, 0x10);
				spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0);
				spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1);
				spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2);
				spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3);
				spyroCamSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);

				signatureLocation = spyroCamSignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 4);
				spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				active.ReadFromRAM(signatureLocation + 4*3, &loadAddress, 4);
				cameraRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

				MemorySignature cameraSignature = scope .();
				cameraSignature.AddInstruction(.lui, .wild, cameraRegister, -1);
				cameraSignature.AddInstruction(.addiu, cameraRegister, cameraRegister, -1);
				MemorySignature spyroSignature = scope .();
				spyroSignature.AddInstruction(.lui, .wild, spyroRegister, -1);
				spyroSignature.AddInstruction(.addiu, spyroRegister, spyroRegister, -1);

				loadSignatureLocation = cameraSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				cameraAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				loadSignatureLocation = spyroSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				spyroAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation + 4*6, &loadAddress, 4);
				spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				active.ReadFromRAM(signatureLocation + 4*9, &loadAddress, 4);
				cameraRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				
				MemorySignature cameraSignature = scope .();
				cameraSignature.AddInstruction(.lui, .wild, cameraRegister, -1);
				cameraSignature.AddInstruction(.addiu, cameraRegister, cameraRegister, -1);
				MemorySignature spyroSignature = scope .();
				spyroSignature.AddInstruction(.lui, .wild, spyroRegister, -1);
				spyroSignature.AddInstruction(.addiu, spyroRegister, spyroRegister, -1);

				loadSignatureLocation = cameraSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				cameraAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				loadSignatureLocation = spyroSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				spyroAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			spyroPositionAddress = (.)spyroAddress;

			MemorySignature cameraPositionSignature = scope .();
			cameraPositionSignature.AddInstruction(.lui); // Camera Struct
			cameraPositionSignature.AddInstruction(.addiu);
			cameraPositionSignature.AddInstruction(.lw); // Camera Basis
			cameraPositionSignature.AddInstruction(.lw);
			cameraPositionSignature.AddInstruction(.lw);
			cameraPositionSignature.AddInstruction(.lw);
			cameraPositionSignature.AddInstruction(.lw);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)5);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)6);
			cameraPositionSignature.AddInstruction(.cop2, (.)0b00110, .zero, (MemorySignature.Reg)7);
			cameraPositionSignature.AddInstruction(.lw); // Camera Position
			cameraPositionSignature.AddInstruction(.lw);
			cameraPositionSignature.AddInstruction(.lw);

			signatureLocation = cameraPositionSignature.Find(active);
			active.ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
			cameraBasisAddress = (.)(cameraAddress + (loadAddress[0] & 0x0000ffff));
			active.ReadFromRAM(signatureLocation + 4*15, &loadAddress, 4);
			cameraPositionAddress = (.)(cameraAddress + (loadAddress[0] & 0x0000ffff));

			// Camera Euler Signature
			// Spyro 1 Attempt
			MemorySignature cameraEulerSignature = scope .();
			cameraEulerSignature.AddInstruction(.lui);
			cameraEulerSignature.AddInstruction(.addiu);
			cameraEulerSignature.AddInstruction(.lh);
			cameraEulerSignature.AddInstruction(.lui);
			cameraEulerSignature.AddInstruction(.lw);
			cameraEulerSignature.AddWildcard<int32>(); // lui/ori
			cameraEulerSignature.AddInstruction(.sh);
			cameraEulerSignature.AddInstruction(.jal);

			signatureLocation = cameraEulerSignature.Find(active);
			if (!signatureLocation.IsNull) {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				cameraEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				cameraEulerAddress -= 2;
			} else {
				// Spyro 2/3 Attempt
				cameraEulerSignature.Clear();
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.lhu);
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.lhu);
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.lhu);
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.sh);
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.sh);
				cameraEulerSignature.AddInstruction(.lui);
				cameraEulerSignature.AddInstruction(.sh);

				signatureLocation = cameraEulerSignature.Find(active);
				active.ReadFromRAM(signatureLocation + 4*6, &loadAddress, 8);
				cameraEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro Euler Signature
			// Spyro 1 Attempt
			MemorySignature spyroEulerSignature = scope .();
			spyroEulerSignature.AddInstruction(.lui);
			spyroEulerSignature.AddInstruction(.lw);
			spyroEulerSignature.AddInstruction(.addu);
			spyroEulerSignature.AddInstruction(.andi);
			spyroEulerSignature.AddInstruction(.sw);
			spyroEulerSignature.AddInstruction(.sra, .wild, .wild, 4);

			signatureLocation = spyroEulerSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				spyroEulerSignature.Clear();
				spyroEulerSignature.AddInstruction(.lui);
				spyroEulerSignature.AddInstruction(.lw);
				spyroEulerSignature.AddInstruction(.sra);
				spyroEulerSignature.AddInstruction(.sb);
				spyroEulerSignature.AddInstruction(.lui);
				spyroEulerSignature.AddInstruction(.lw);
				spyroEulerSignature.AddInstruction(.sra);
				spyroEulerSignature.AddInstruction(.sb);
				spyroEulerSignature.AddInstruction(.sra);
				
				signatureLocation = spyroEulerSignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroEulerAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro Basis Signature
			MemorySignature spyroBasisSignature = scope .();
			spyroBasisSignature.AddInstruction(.lw);
			spyroBasisSignature.AddInstruction(.lw);
			spyroBasisSignature.AddInstruction(.lw);
			spyroBasisSignature.AddInstruction(.lw);
			spyroBasisSignature.AddInstruction(.lw);
			spyroBasisSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)0);
			spyroBasisSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)1);
			spyroBasisSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)2);
			spyroBasisSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)3);
			spyroBasisSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)4);

			signatureLocation = (.)0x80000000;
			while (signatureLocation < (.)0x80200000) {
				signatureLocation = spyroBasisSignature.Find(active, signatureLocation + 4);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);
				int spyroBasisOffset = loadAddress[0] & 0x0000ffff;

				MemorySignature spyroSignature2 = scope .();
				spyroSignature2.AddInstruction(.lui, .wild, spyroRegister, -1);
				spyroSignature2.AddInstruction(.addiu, spyroRegister, spyroRegister, -1);

				loadSignatureLocation = spyroSignature2.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				if (spyroAddress == (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1])) {
					spyroBasisAddress = (.)spyroAddress + spyroBasisOffset;
					break;
				}
			}

			// Spyro Velocity Signature
			MemorySignature spyroVelSignature = scope .();
			spyroVelSignature.AddInstruction(.lui);
			spyroVelSignature.AddInstruction(.addiu);
			spyroVelSignature.AddInstruction(.lui);
			spyroVelSignature.AddInstruction(.lw);
			spyroVelSignature.AddInstruction(.sll, .zero, .zero);
			spyroVelSignature.AddInstruction(.sll);
			spyroVelSignature.AddInstruction(.subu);

			signatureLocation = spyroVelSignature.Find(active);
			if (signatureLocation.IsNull) {
				MemorySignature spyVelPhySignature = scope .();
				spyVelPhySignature.AddInstruction(.lui);
				spyVelPhySignature.AddInstruction(.lw);
				spyVelPhySignature.AddInstruction(.lui);
				spyVelPhySignature.AddInstruction(.lw);
				spyVelPhySignature.AddInstruction(.sw);
				spyVelPhySignature.AddInstruction(.jal);

				signatureLocation = spyVelPhySignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityIntended = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

				MemorySignature spyVelIntSignature = scope .();
				spyVelIntSignature.AddInstruction(.lui);
				spyVelIntSignature.AddInstruction(.addiu);
				spyVelIntSignature.AddInstruction(.jal);
				spyVelIntSignature.AddInstruction(.sll);
				spyVelIntSignature.AddInstruction(.lui);
				spyVelIntSignature.AddInstruction(.lw);
				spyVelIntSignature.AddInstruction(.addiu, .zero, .wild, -1);
				spyVelIntSignature.AddInstruction(.lui);
				spyVelIntSignature.AddInstruction(.sw);

				signatureLocation = spyVelIntSignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityPhysics = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				spyroVelocityIntended = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				active.ReadFromRAM(signatureLocation + 4*2, &loadAddress, 8);
				spyroVelocityPhysics = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Spyro State Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroStateSignature = scope .();
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sb, .wild, .zero, -1);
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sb, .wild, .zero, -1);
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sw, .wild, .zero, -1);
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sw);
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sw, .wild, .zero, -1);
			spyroStateSignature.AddInstruction(.lui);
			spyroStateSignature.AddInstruction(.sw);
			spyroStateSignature.AddInstruction(.lw);
			spyroStateSignature.AddInstruction(.lw);
			spyroStateSignature.AddInstruction(.lw);

			signatureLocation = spyroStateSignature.Find(active);

			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroStateSignature.Clear();
				spyroStateSignature.AddInstruction(.lui);
				spyroStateSignature.AddInstruction(.lw);
				spyroStateSignature.AddInstruction(.lui);
				spyroStateSignature.AddInstruction(.sw);
				spyroStateSignature.AddInstruction(.lui);
				spyroStateSignature.AddInstruction(.lw);
				spyroStateSignature.AddInstruction(.lui);
				spyroStateSignature.AddInstruction(.sw);
				spyroStateSignature.AddInstruction(.lui);
				spyroStateSignature.AddInstruction(.sw);
				
				spyroStateChangeAddress = (.)spyroStateSignature.Find(active) + 4*2;
				active.ReadFromRAM(spyroStateChangeAddress, &loadAddress, 8);
				spyroStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				spyroStateChangeAddress = (.)signatureLocation + 4*6;
				active.ReadFromRAM(spyroStateChangeAddress, &loadAddress, 8);
				spyroStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Mobys (Objects) Signature
			MemorySignature mobyArraySignature = scope .();
			mobyArraySignature.AddInstruction(.lui);
			mobyArraySignature.AddInstruction(.lw);
			mobyArraySignature.AddInstruction(.sll);
			mobyArraySignature.AddInstruction(.subu);
			mobyArraySignature.AddInstruction(.sll);
			mobyArraySignature.AddInstruction(.subu);
			mobyArraySignature.AddInstruction(.sll);
			mobyArraySignature.AddInstruction(.addu);
			mobyArraySignature.AddInstruction(.sll);
			mobyArraySignature.AddInstruction(.addu);
			mobyArraySignature.AddInstruction(.sll);
			mobyArraySignature.AddInstruction(.subu);
			mobyArraySignature.AddInstruction(.sll);

			signatureLocation = mobyArraySignature.Find(active);
			active.ReadFromRAM(signatureLocation, &loadAddress, 8);
			mobyArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			
			// Moby Models Signature
			// Spyro 1 Attempt
			MemorySignature mobyModelArraySignature = scope .();
			mobyModelArraySignature.AddInstruction(.lui);
			mobyModelArraySignature.AddInstruction(.lw);
			mobyModelArraySignature.AddInstruction(.sll);
			mobyModelArraySignature.AddInstruction(.addu);
			mobyModelArraySignature.AddInstruction(.lui);
			mobyModelArraySignature.AddInstruction(.lbu);
			
			signatureLocation = mobyModelArraySignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				mobyModelArraySignature.Clear();
				mobyModelArraySignature.AddInstruction(.lui);
				mobyModelArraySignature.AddInstruction(.sw);
				mobyModelArraySignature.AddInstruction(.lui);
				mobyModelArraySignature.AddInstruction(.lw);
				mobyModelArraySignature.AddInstruction(.addiu);
				mobyModelArraySignature.AddInstruction(.lui);
				mobyModelArraySignature.AddInstruction(.sw);
				mobyModelArraySignature.AddInstruction(.lw);
				
				signatureLocation = mobyModelArraySignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				mobyModelArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				mobyModelArrayPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Background Clear Color Signature
			MemorySignature clearColorSignature = scope .();
			clearColorSignature.AddInstruction(.sll, .wild, .wild, 0x4);
			clearColorSignature.AddInstruction(.andi, .wild, .wild, 0xff0);
			clearColorSignature.AddInstruction(.srl, .wild, .wild, 0x4);
			clearColorSignature.AddInstruction(.andi, .wild, .wild, 0xff0);
			clearColorSignature.AddInstruction(.srl, .wild, .wild, 0xc);
			clearColorSignature.AddInstruction(.andi, .wild, .wild, 0xff0);
			clearColorSignature.AddInstruction(.lw);
			clearColorSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)21);
			clearColorSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)22);
			clearColorSignature.AddInstruction(.cop2, (.)0b00110, .wild, (MemorySignature.Reg)23);

			signatureLocation = clearColorSignature.Find(active);
			active.ReadFromRAM(signatureLocation, &loadAddress, 4);
			MemorySignature.Reg colorRegister = (.)((loadAddress[0] & 0x001f0000) >> 16);

			MemorySignature clearColorLoadSignature = scope .();
			clearColorLoadSignature.AddInstruction(.lui, .wild, colorRegister, -1);
			clearColorLoadSignature.AddInstruction(.addiu, colorRegister, colorRegister, -1);

			signatureLocation = clearColorLoadSignature.FindReverse(active, signatureLocation);
			active.ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
			clearColorAddress = (.)((int32)loadAddress[0] & 0x0000ffff);
			active.ReadFromRAM(signatureLocation, &loadAddress, 8);
			clearColorAddress += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			// Terrain Collision Signature
			MemorySignature terrainCollisionSignature = scope .();
			terrainCollisionSignature.AddInstruction(.lui);
			terrainCollisionSignature.AddInstruction(.addiu);
			terrainCollisionSignature.AddInstruction(.lw);
			terrainCollisionSignature.AddInstruction(.sll);
			terrainCollisionSignature.AddInstruction(.sll);
			terrainCollisionSignature.AddInstruction(.add);
			terrainCollisionSignature.AddInstruction(.lw);

			signatureLocation = terrainCollisionSignature.Find(active);
			active.ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
			collisionDataPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
			active.ReadFromRAM(signatureLocation, &loadAddress, 8);
			collisionDataPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			// Terrain Flags Signature
			MemorySignature terrainFlagsSignature = scope .();
			terrainFlagsSignature.AddInstruction(.andi, 0x3f);
			terrainFlagsSignature.AddInstruction(.addiu, .zero, .wild, 0x3f);
			terrainFlagsSignature.AddInstruction(.beq);
			terrainFlagsSignature.AddInstruction(.sll);
			terrainFlagsSignature.AddInstruction(.lui);
			terrainFlagsSignature.AddInstruction(.lw);
			
			signatureLocation = terrainFlagsSignature.Find(active);
			active.ReadFromRAM(signatureLocation + 4*4, &loadAddress, 8);
			collisionFlagsPointer = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);

			// Terrain Animations Signature
			MemorySignature loadMainSignature = scope .();
			loadMainSignature.AddInstruction(.lui);
			loadMainSignature.AddInstruction(.addiu);
			loadMainSignature.AddInstruction(.lw);

			MemorySignature terrainGeometryAnimationsSignature = scope .();
			terrainGeometryAnimationsSignature.AddInstruction(.lw);
			terrainGeometryAnimationsSignature.AddInstruction(.lw);
			terrainGeometryAnimationsSignature.AddInstruction(.sll);
			terrainGeometryAnimationsSignature.AddInstruction(.add);
			terrainGeometryAnimationsSignature.AddInstruction(.beq);
			terrainGeometryAnimationsSignature.AddInstruction(.lw);

			Address*[3] terrainGeometryAnimationAddresses = .(
				&textureSwappersPointer,
				&textureScrollersPointer,
				&collisionDeformPointer
			);

			signatureLocation = (.)0x80000000;
			for (let i < 3) {
				let addr = terrainGeometryAnimationAddresses[i];

				signatureLocation = terrainGeometryAnimationsSignature.Find(active, signatureLocation + 4);
				
				active.ReadFromRAM(signatureLocation, &loadAddress, 4);
				*addr = (.)((int32)loadAddress[0] & 0x0000ffff);
				MemorySignature.Reg animsRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

				if (i == 0) {
					loadSignatureLocation = loadMainSignature.Find(active, signatureLocation);
					active.ReadFromRAM(loadSignatureLocation + 4*2, &loadAddress, 4);
					textureDataPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
					active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					textureDataPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				}

				MemorySignature loadSignature = scope .();
				loadSignature.AddInstruction(.lui, .wild, animsRegister, -1);
				loadSignature.AddInstruction(.addiu, animsRegister, animsRegister, -1);

				loadSignatureLocation = loadSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				*addr += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			MemorySignature terrainTextureAnimationsSignature = scope .();
			terrainTextureAnimationsSignature.AddInstruction(.lw);
			terrainTextureAnimationsSignature.AddInstruction(.lw);
			terrainTextureAnimationsSignature.AddInstruction(.addi);
			terrainTextureAnimationsSignature.AddInstruction(.sll);
			terrainTextureAnimationsSignature.AddInstruction(.add);
			terrainTextureAnimationsSignature.AddInstruction(.beq);
			terrainTextureAnimationsSignature.AddInstruction(.addi);

			Address*[3] terrainTextureAnimationAddresses = .(
				&farRegionsDeformPointer,
				null,
				&nearRegionsDeformPointer
			);

			for (let i < 3) {
				let addr = terrainTextureAnimationAddresses[i];

				signatureLocation = terrainTextureAnimationsSignature.Find(active, signatureLocation + 4);
				
				if (addr != null) {
					active.ReadFromRAM(signatureLocation, &loadAddress, 4);
					*addr = (.)((int32)loadAddress[0] & 0x0000ffff);
					MemorySignature.Reg animsRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

					if (i == 0) {
						loadSignatureLocation = loadMainSignature.Find(active, signatureLocation);
						active.ReadFromRAM(loadSignatureLocation + 4*2, &loadAddress, 4);
						sceneRegionsPointer = (.)((int32)loadAddress[0] & 0x0000ffff);
						active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
						sceneRegionsPointer += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
					}

					MemorySignature loadSignature = scope .();
					loadSignature.AddInstruction(.lui, .wild, animsRegister, -1);
					loadSignature.AddInstruction(.addiu, animsRegister, animsRegister, -1);

					loadSignatureLocation = loadSignature.FindReverse(active, signatureLocation);
					active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
					*addr += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
				}
			}

			// Health
			// Spyro 2/3 Attempt
			MemorySignature healthSignature = scope .();
			healthSignature.AddInstruction(.addiu, .zero, .wild, (uint16)-1);
			healthSignature.AddInstruction(.lui);
			healthSignature.AddInstruction(.lw);
			healthSignature.AddInstruction(.sll);
			healthSignature.AddWildcard<int32>();
			healthSignature.AddInstruction(.addiu);
			healthSignature.AddInstruction(.lui);
			healthSignature.AddInstruction(.sw);

			signatureLocation = healthSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				healthSignature.Clear();
				healthSignature.AddInstruction(.bne);
				healthSignature.AddInstruction(.sll);
				healthSignature.AddInstruction(.lw);
				healthSignature.AddInstruction(.sll);
				healthSignature.AddInstruction(.addiu, .wild, .wild, (uint16)-1);
				healthSignature.AddInstruction(.sw);

				signatureLocation = healthSignature.Find(active);
				active.ReadFromRAM(signatureLocation + 4*2, &loadAddress, 4);
				MemorySignature.Reg healthRegister = (.)((loadAddress[0] & 0x03e00000) >> 21);

				MemorySignature loadSignature = scope .();
				loadSignature.AddInstruction(.lui, .wild, healthRegister, -1);
				loadSignature.AddInstruction(.addiu, healthRegister, healthRegister, -1);

				loadSignatureLocation = loadSignature.FindReverse(active, signatureLocation);
				active.ReadFromRAM(loadSignatureLocation, &loadAddress, 8);
				healthAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(loadSignatureLocation + 4*1, &loadAddress, 8);
				healthAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Load State Signature
			// Spyro 2/3 Attempt
			MemorySignature loadStateSignature = scope .();
			loadStateSignature.AddInstruction(.sw);
			loadStateSignature.AddInstruction(.jal);
			loadStateSignature.AddInstruction(.sw);
			loadStateSignature.AddWildcard<uint32>();
			loadStateSignature.AddInstruction(.sll);
			loadStateSignature.AddInstruction(.lui);
			loadStateSignature.AddInstruction(.lw);
			loadStateSignature.AddInstruction(.sll);

			signatureLocation = loadStateSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				loadStateSignature.Clear();
				loadStateSignature.AddInstruction(.lui);
				loadStateSignature.AddInstruction(.sw);
				loadStateSignature.AddInstruction(.lui);
				loadStateSignature.AddInstruction(.sw);
				loadStateSignature.AddInstruction(.addiu, .wild, .wild, 1);
				loadStateSignature.AddInstruction(.lui);
				loadStateSignature.AddInstruction(.sw);
	
				signatureLocation = loadStateSignature.Find(active);
				active.ReadFromRAM(signatureLocation + 4*5, &loadAddress, 8);
				loadStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation + 4*5, &loadAddress, 8);
				loadStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Game State Signature
			// Spyro 1 Attempt
			MemorySignature gameStateSignature = scope .(); ////
			gameStateSignature.AddInstruction(.lui);
			gameStateSignature.AddInstruction(.lw);
			gameStateSignature.AddInstruction(.sll);
			gameStateSignature.AddInstruction(.beq, .wild, .zero, -1);
			gameStateSignature.AddInstruction(.addiu, .zero, .wild, 1);
			gameStateSignature.AddInstruction(.beq);

			signatureLocation = gameStateSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				gameStateSignature.Clear();
				gameStateSignature.AddInstruction(.jal);
				gameStateSignature.AddInstruction(.sll);
				gameStateSignature.AddInstruction(.jal);
				gameStateSignature.AddInstruction(.sll);
				gameStateSignature.AddInstruction(.lui);
				gameStateSignature.AddInstruction(.lw);
				gameStateSignature.AddInstruction(.sll);
				gameStateSignature.AddInstruction(.sltiu);
				gameStateSignature.AddInstruction(.beq);
				gameStateSignature.AddInstruction(.sll);
				gameStateSignature.AddInstruction(.lui);
				gameStateSignature.AddInstruction(.addu);
				gameStateSignature.AddInstruction(.lw);
				gameStateSignature.AddInstruction(.sll);
				
				signatureLocation = gameStateSignature.Find(active);
				active.ReadFromRAM(signatureLocation + 4*4, &loadAddress, 8);
				gameStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameStateAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			// Update Spyro Call Signature
			// Spyro 2/3 Attempt
			MemorySignature spyroUpdateCallSignature = scope .();
			spyroUpdateCallSignature.AddInstruction(.andi, 0x8);
			spyroUpdateCallSignature.AddInstruction(.beq);
			spyroUpdateCallSignature.AddInstruction(.andi, 0x20);
			spyroUpdateCallSignature.AddInstruction(.jal);
			spyroUpdateCallSignature.AddInstruction(.sll);
			spyroUpdateCallSignature.AddInstruction(.andi, 0x20);

			signatureLocation = spyroUpdateCallSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				spyroUpdateCallSignature.Clear();

				MemorySignature spyroUpdateSignature = scope .();
				spyroUpdateSignature.AddInstruction(.lui);
				spyroUpdateSignature.AddInstruction(.lw);
				spyroUpdateSignature.AddInstruction(.addiu);
				spyroUpdateSignature.AddInstruction(.sw);
				spyroUpdateSignature.AddInstruction(.sw);
				spyroUpdateSignature.AddInstruction(.andi);
				spyroUpdateSignature.AddInstruction(.beq);
				spyroUpdateSignature.AddInstruction(.sw);
				spyroUpdateSignature.AddInstruction(.lui);
				spyroUpdateSignature.AddInstruction(.lw);
				spyroUpdateSignature.AddInstruction(.sll);

				// Find start of update function
				signatureLocation = spyroUpdateSignature.Find(active);
				spyroUpdateCallValue = ((uint32)MemorySignature.Op.jal << 26) | (((.)signatureLocation >> 2) & 0x03ffffff);

				spyroUpdateCallSignature.AddPart(spyroUpdateCallValue);

				// Find the third occurrence
				signatureLocation = (.)0x80000000;
				for (let i < 3) {
					signatureLocation = spyroUpdateCallSignature.Find(active, signatureLocation + 4);
				}

				spyroUpdateCallAddress = (.)signatureLocation;
			} else {
				spyroUpdateCallAddress = (.)signatureLocation + 4*3;
				spyroUpdateCallAddress.Read(&spyroUpdateCallValue);
			}

			// Update Camera Call Signature
			// Spyro 2/3 Attempt
			MemorySignature cameraUpdateCallSignature = scope .();
			cameraUpdateCallSignature.AddInstruction(.andi, 0x10);
			cameraUpdateCallSignature.AddInstruction(.beq);
			cameraUpdateCallSignature.AddInstruction(.andi, 0x40);
			cameraUpdateCallSignature.AddInstruction(.jal);
			cameraUpdateCallSignature.AddInstruction(.sll);
			cameraUpdateCallSignature.AddInstruction(.andi, 0x40);
			
			signatureLocation = cameraUpdateCallSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 1 Attempt
				cameraUpdateCallSignature.Clear();
				cameraUpdateCallSignature.AddInstruction(.bne);
				cameraUpdateCallSignature.AddInstruction(.sll);
				cameraUpdateCallSignature.AddInstruction(.jal);
				cameraUpdateCallSignature.AddInstruction(.sll);
				cameraUpdateCallSignature.AddInstruction(.j);
				cameraUpdateCallSignature.AddInstruction(.sll);
				cameraUpdateCallSignature.AddInstruction(.jal);
				cameraUpdateCallSignature.AddInstruction(.sll);
				cameraUpdateCallSignature.AddInstruction(.lui);
				cameraUpdateCallSignature.AddInstruction(.lw);
				
				signatureLocation = cameraUpdateCallSignature.Find(active);
				cameraUpdateCallAddress = (.)signatureLocation + 4*6;
				cameraUpdateCallAddress.Read(&cameraUpdateCallValue);
			} else {
				cameraUpdateCallAddress = (.)signatureLocation + 4*2;
				cameraUpdateCallAddress.Read(&cameraUpdateCallValue);
			}

			// Main Update Call Signature
			// Spyro 1 Attempt
			MemorySignature updateCallSignature = scope .();
			updateCallSignature.AddInstruction(.sb);
			updateCallSignature.AddInstruction(.jal);
			updateCallSignature.AddInstruction(.sll);
			updateCallSignature.AddInstruction(.lw);
			updateCallSignature.AddInstruction(.sb);
			updateCallSignature.AddInstruction(.sw);
			
			signatureLocation = updateCallSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				updateCallSignature.Clear();
				updateCallSignature.AddInstruction(.jal);
				updateCallSignature.AddInstruction(.sll);
				updateCallSignature.AddInstruction(.jal);
				updateCallSignature.AddInstruction(.sll);
				updateCallSignature.AddInstruction(.j);
				updateCallSignature.AddInstruction(.sll);
				
				signatureLocation = updateCallSignature.Find(active);
				updateCallAddress = (.)signatureLocation;
				updateCallAddress.Read(&updateCallValue);
			} else {
				updateCallAddress = (.)signatureLocation + 4*1;
				updateCallAddress.Read(&updateCallValue);
			}

			// Game Input Signature
			// Spyro 1 Attempt
			MemorySignature gameInputSignature = scope .();
			gameInputSignature.AddInstruction(.lui);
			gameInputSignature.AddInstruction(.lw);
			gameInputSignature.AddInstruction(.sll);
			gameInputSignature.AddInstruction(.andi, 0x10);
			gameInputSignature.AddInstruction(.beq);
			gameInputSignature.AddInstruction(.lui);
			
			signatureLocation = gameInputSignature.Find(active);
			if (signatureLocation.IsNull) {
				// Spyro 2/3 Attempt
				gameInputSignature.Clear();
				gameInputSignature.AddInstruction(.lui);
				gameInputSignature.AddInstruction(.lw);
				gameInputSignature.AddInstruction(.sll);
				gameInputSignature.AddInstruction(.andi, 0x10);
				gameInputSignature.AddInstruction(.bne);
				
				signatureLocation = gameInputSignature.Find(active);
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameInputAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			} else {
				active.ReadFromRAM(signatureLocation, &loadAddress, 8);
				gameInputAddress = (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}
		}

		// Spyro Update
		public void KillSpyroUpdate() {
			uint32 v = 0;
			spyroUpdateCallAddress.Write(&v, this);
		}

		public void RestoreSpyroUpdate() {
			spyroUpdateCallAddress.Write(&spyroUpdateCallValue, this);
		}

		public void KillSpyroStateChange() {
			uint32 v = 0;
			spyroStateChangeAddress.Write(&v, this);
		}

		public void RestoreSpyroStateChange() {
			spyroStateChangeAddress.Write(&spyroStateChangeValue, this);
		}

		// Main Update
		public void KillUpdate() {
			// If stepper code injection exists, jump to that code instead of nop'ing it out
			// since the code will not cause one from of the game loop to occur by default
			uint32 v = stepperInjected ? 0x0C002400 : 0;
			updateCallAddress.Write(&v, this);
		}

		public void RestoreUpdate() {
			updateCallAddress.Write(&updateCallValue, this);
		}

		// Camera
		public void KillCameraUpdate() {
			uint32 v = 0;
			cameraUpdateCallAddress.Write(&v, this);
		}

		public void RestoreCameraUpdate() {
			cameraUpdateCallAddress.Write(&cameraUpdateCallValue, this);
		}

		// Input
		/*public void KillInputRelay() {
			uint32 v = 0;
			gameInputSetAddress[(int)rom].Write(&v, this);

			// Beyond the point of this function being called
			// input should be written into RAM from the program

			// Currently it still receives input elsewhere
			// even after this is called
		}*/

		/*public void RestoreInputRelay() {
			uint32 v = gameInputValue[(int)rom];
			gameInputSetAddress[(int)rom].Write(&v, this);
		}*/

		// Logic
		public void InjectStepperLogic() {
			WriteToRAM(stepperAddress, &stepperLogic[0], 4 * stepperLogic.Count);
			uint32 v = 0x0C002400; // (stepperAddress & 0x0fffffff) >> 2;
			updateCallAddress.Write(&v, this);
			stepperInjected = true;
		}

		public void Step() {
			if (!stepperInjected) {
				InjectStepperLogic();
			}
			KillUpdate();
			WriteToRAM(stepperAddress + (8 * 4), &updateCallValue, 4);
		}

		public void AddStepListener(delegate void() listener) {
			OnStep.Add(listener);
			Lockstep = true;
		}

		public void RemoveStepListener(delegate void() listener) {
			OnStep.Remove(listener);
			Lockstep = OnStep.HasListeners;
		}
	}
}
