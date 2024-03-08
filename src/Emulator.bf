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

		/// Uses the essential address locations to generate a unique value 
		/// that will determine what ROM is currently loaded in emulator
		public int32 romChecksum;

		/// A four byte value that is likely to change
		/// when a new ROM gets loaded into the emulator
		public uint32 romTester;

		/// The address to load and use against the test value
		public Address<uint32>[7] romTesterAddresses;

		public enum SpyroInstallment {
			None = 0,
			SpyroTheDragon = 1,
			RiptosRage = 2,
			YearOfTheDragon = 3
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

		public const String[9] pointerLabels = .(
			"Terrain Mesh",
			"Terrain Deform",
			"Terrain Warp",
			"Terrain Collision",
			"Terrain Collision Flags",
			"Terrain Collision Deform",
			"Textures",
			"Texture Scrollers",
			"Texture Swappers"
		);
		public Address[9] loadedPointers;
		public bool[9] changedPointers;
		public Address<Address>*[9] pointerSets = .(
			&sceneRegionsPointer,
			&farRegionsDeformPointer,
			&regionsWarpPointer,
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
		
		public const Address<char8>[10] testAddresses = .((.)0x800103e7/*StD*/, 0, 0, (.)0x80066ea8/*RR*/, 0, (.)0x8006c500/*GtG*/, (.)0x8006c3b0, (.)0x8006c490/*YotD-1.1*/, 0, 0);
		public const String[11] gameNames = .(String.Empty, "Spyro the Dragon (NTSC-U)", "Spyro the Dragon (NTSC-J)", "Spyro the Dragon (PAL)", "Spyro: Ripto's Rage (NTSC-U)", "Spyro and Sparx: Tondemo Tours (NTSC-J)", "Spyro: Gateway to Glimmer (PAL)", "Spyro: Year of the Dragon (v1.0 NTSC-U)", "Spyro: Year of the Dragon (v1.1 NTSC-U)", "Spyro: Year of the Dragon (v1.0 PAL)", "Spyro: Year of the Dragon (v1.1 PAL)");

		public Address<int32> gameStateAddress, loadStateAddress;

		// Spyro
		public Address spyroAddress;

		public Address<Vector3Int> spyroPositionAddress;
		public Address<Vector3Int> spyroEulerAddress;
		public Address<MatrixInt> spyroBasisAddress;

		public Address<Vector3Int> spyroVelocityIntended, spyroVelocityPhysics;

		public Address<uint32> spyroStateAddress;
		public Address<AnimationState> spyroAnimStateAddress;
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
		public const Address<uint32>[11] currentWorldIdAddress = .(0, (.)0x80075964/*StD*/, 0, 0, (.)0x80066f54/*RR*/, 0, 0, (.)0x8006e58c, (.)0x8006c66c/*YotD-1.1*/, 0, 0); ////
		public const Address<uint32>[4] currentSubWorldIdAddress = .((.)0x8006c5c8, (.)0x8006c6a8, (.)0, (.)0); // Exclusive to Spyro: Year of the Dragon. ////

		public Address<uint8> frameClockAddress;
		public Address<Color4> clearColorAddress;
		public Address<Address> textureDataPointer, sceneRegionsPointer, collisionDataPointer, collisionFlagsPointer;
		public Address<Address> textureSwappersPointer, textureScrollersPointer, farRegionsDeformPointer, nearRegionsDeformPointer, collisionDeformPointer, regionsWarpPointer;
		public Address<uint8> regionsRenderingArrayAddress;
		public Address<Address> skyboxRegionsPointer;

		// Exclusive to Spyro: Ripto's Rage
		public const Address<uint8>[3] spriteWidthArrayAddress = .((.)0x800634b8, 0, (.)0x80067ce0);
		public const Address<uint8>[3] spriteHeightArrayAddress = .((.)0x800634d0, 0, (.)0x80067cf8);
		public const Address<TextureSprite.SpriteFrame>[3] spriteFrameArrayAddress = .((.)0x8006351c, 0, (.)0x80067db8);

		public const Address<uint16>[7] spyroFontAddress = .((.)0x800636a4/*RR*/, 0, (.)0x80067f40/*GtG*/, 0, (.)0x800667c8/*YotD-1.1*/, 0, 0); // Doesn't exist in Spyro the Dragon
		public const Address<Address<TextureQuad>>[4] spriteArrayPointer = .(0, (.)0x8006c868, 0, 0); // Exclusive to Spyro: Year of the Dragon

		public const Address<uint32>[11] deathPlaneHeightsAddresses = .(0, (.)0x8006e9a4/*StD*/, 0, 0, (.)0x80060234/*RR*/, 0, (.)0x80064680/*GtG*/, (.)0x800676e8, (.)0x800677c8/*YotD-1.1*/, 0, 0); ////
		public const Address<uint32>[11] maxFreeflightHeightsAddresses = .(0, 0/*StD*/, 0, 0, (.)0x800601b4/*RR*/, 0, (.)0x80064600/*GtG*/, (.)0x80067648, (.)0x80067728/*YotD-1.1*/, 0, 0); ////

		public Address<uint32> healthAddress;

		public Address<uint32> gameInputAddress;
		//public const Address<uint32>[11] gameInputAddress = .(0, (.)0x800773c0/*StD*/, 0, 0, (.)0x800683a0/*RR*/, 0, (.)0x8006f568/*GtG*/, 0, (.)0x8006e618/*YotD-1.1*/, 0, 0);
		//public const Address<uint32>[11] gameInputSetAddress = .(0, 0/*StD*/, 0, 0, (.)0x8001291c/*RR*/, 0, (.)0x80014998/*GtG*/, 0, (.)0x8003a7a0/*YotD-1.1*/, 0, 0);

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

		MatrixInt spyroBasis;
		/// Current rotation of Spyro
		public MatrixInt SpyroBasis {
			get => spyroBasis;
			set {
				spyroBasis = value;
				spyroBasisAddress.Write(&spyroBasis, this);
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

		AnimationState[2] spyroAnimState;
		/// Current animation state of Spyro's head
		public AnimationState SpyroHeadAnimState {
			get => spyroAnimState[0];
			set {
				spyroAnimState[0] = value;
				spyroAnimStateAddress.SetAtIndex(&spyroAnimState[0], 0, this);
			}
		}

		/// Current animation state of Spyro's body
		public AnimationState SpyroBodyAnimState {
			get => spyroAnimState[1];
			set {
				spyroAnimState[1] = value;
				spyroAnimStateAddress.SetAtIndex(&spyroAnimState[1], 1, this);
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
		public int32 collidingTriangle = -1;
		
		public Color4[10][4] shinyColors;
		public uint32[] deathPlaneHeights ~ delete _;
		public uint32[] maxFreeflightHeights ~ delete _;

		public Address<Moby> objectArrayAddress;

		// Game Constants
		public static (String label, Color color)[11] collisionTypes = .(
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

			Debug.WriteLine($"Emulator Process: {EmulatorsConfig.emulators[emulator].processName}");

			moduleHandle = GetModule(processHandle, EmulatorsConfig.emulators[emulator].processName);

			MainModuleSize = GetModuleSize(processHandle, moduleHandle);
			Debug.WriteLine($"Main Module Size: {MainModuleSize:x} bytes");

			versionIndex = EmulatorsConfig.emulators[emulator].versions.FindIndex(scope (x) => x.moduleSize == MainModuleSize);
			Debug.WriteLine($"Emulator Version: {(versionIndex > -1 ? EmulatorsConfig.emulators[emulator].versions[versionIndex].label : "Unknown")}");

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
			FindAddressLocations();

			int32 newRomChecksum = 0;
			if (
				!collisionDataPointer.IsNull &&
				!sceneRegionsPointer.IsNull &&
				!mobyArrayPointer.IsNull &&
				!mobyModelArrayPointer.IsNull &&
				!textureDataPointer.IsNull &&
				!loadStateAddress.IsNull &&
				!gameStateAddress.IsNull
			) {
				newRomChecksum = 
					(.)collisionDataPointer +
					(.)sceneRegionsPointer +
					(.)mobyArrayPointer +
					(.)mobyModelArrayPointer +
					(.)textureDataPointer +
					(.)loadStateAddress +
					(.)gameStateAddress;
				newRomChecksum &= 0x0fffffff;
			}

			if (newRomChecksum != 0 && newRomChecksum != romChecksum) {
				FetchStaticData();
			}

			romChecksum = newRomChecksum;
		}

		public void TestGame() {
			int32 checksum = 0;
			int32[2] loadAddress = ?;
			for (let i < 4) {
				ReadFromRAM(romTesterAddresses[i], &loadAddress, 8);
				checksum += ((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1];
			}

			for (var i = 4; i < 7; i++) {
				ReadFromRAM(romTesterAddresses[i] + 4*2, &loadAddress, 4);
				checksum += (.)((int32)loadAddress[0] & 0x0000ffff);
				ReadFromRAM(romTesterAddresses[i], &loadAddress, 8);
				checksum += (.)(((loadAddress[0] & 0x0000ffff) << 16) + (int32)(int16)loadAddress[1]);
			}

			checksum &= 0x0fffffff;

			if (checksum != romChecksum) {
				// Clear the value so that the viewer state
				// can handle this to go back to setup mode
				romChecksum = 0;
			}
		}
		
		public void GetGameName(String name) {
			String entry;
			if (ROMsConfig.roms.TryGetValue(Emulator.active.romChecksum, out entry)) {
				name.Append(entry);
			} else {
				name.AppendF($"Unidentified Spyro [{Emulator.active.romChecksum:x}]");
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
			for (let i < 9) {
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
					VRAM.MakeOutdated();
				} else if (
					installment == .SpyroTheDragon && (gameState == 13 || gameState == 14) ||
					installment != .SpyroTheDragon && (gameState == 6 || gameState == 11)
				) {
					loadingStatus = .CutsceneDone;

					for (let i < 9) {
						changedPointers[i] = false;
					}
					VRAM.MakeOutdated();
				}
			}
		}

		public void UnbindEmulatorProcess() {
			if (Supported && romChecksum != 0) {
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
			/*delete maxFreeflightHeights;
			delete deathPlaneHeights;

			switch (installment) {
				case .SpyroTheDragon: {
					ReadFromRAM(shinyColorsAddresses[(int)rom], &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 35 worlds exist, but there is space for 36. (Probably due to short/int reasons.)
					deathPlaneHeights = new .[36];
					maxFreeflightHeights = new .[36];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 36, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 36, this);
				}

				case .RiptosRage: {
					ReadFromRAM(shinyColorsAddresses[(int)rom], &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 28 worlds exists but there is space for 32 (probably a power of 2 related thing)
					deathPlaneHeights = new .[32];
					maxFreeflightHeights = new .[32];
					
					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 32, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 32, this);
				}

				case .YearOfTheDragon: {
					ReadFromRAM(shinyColorsAddresses[(int)rom], &shinyColors, sizeof(Renderer.Color4[10][4]));

					// 37 worlds exist, but theres space for 40. (Probably due to short/int reasons.)
					// Also gets multipled by 4 due to sub worlds, there being a minimum of 4 in each homeworld.
					deathPlaneHeights = new .[40 * 4];
					maxFreeflightHeights = new .[40 * 4];

					deathPlaneHeightsAddresses[(int)rom].ReadArray(&deathPlaneHeights[0], 40 * 4, this);
					maxFreeflightHeightsAddresses[(int)rom].ReadArray(&maxFreeflightHeights[0], 40, this);
				}
				default : {}
			}*/
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
			spyroAnimStateAddress.ReadArray(&spyroAnimState, 2, this);
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
