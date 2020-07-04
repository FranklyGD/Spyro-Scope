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
			NoCashPSX,
			Bizhawk,
			ePSXe
		}
		public static EmulatorType emulator;
		static uint emulatorRAMBaseAddress;

		public enum SpyroROM {
			None,
			SpyroTheDragon,
			RiptosRage,
			YearOfTheDragon
		}
		public static SpyroROM rom;

		public typealias Address = uint32;

		// Begin Spyro games information

		public const Address[3] testAddresses = .(0, 0x80066ea8, 0x8006c490);
		public const String[4] gameNames = .(String.Empty, "Spyro the Dragon", "Spyro: Ripto's Rage", "Spyro: Year of the Dragon");

		public const Address[4] spyroPositionPointers = .(0, 0, 0x80069ff0, 0x80070408);
		public const Address[4] spyroMatrixPointers = .(0, 0, 0x8006a020, 0x80070438);
		public const Address[4] spyroIntendedVelocityPointers = .(0, 0, 0x8006a084, 0x80070494);
		public const Address[4] spyroPhysicsVelocityPointers = .(0, 0, 0x8006a090, 0x800704a0);

		public const Address[4] objectArrayPointers = .(0, 0, 0x80066f14, 0x8006c630);
		public const Address[4] modelPointers = .(0, 0, 0x80068c94, 0x8006ef0c);

		public const Address[4] cameraPositionAddress = .(0, 0, 0x80067eac, 0x8006e100);
		public const Address[4] cameraEulerRotationAddress = .(0, 0, 0x80067ec8, 0x8006e11c);
		public const Address[4] cameraMatrixAddress = .(0, 0, 0x80067e98, 0x8006e0ec);

		public const Address[4] collisionDataPointer = .(0, 0, 0x800673fc, 0x8006d150);
		public const Address[4] collisionFlagsArrayPointer = .(0, 0, 0x800673e8, 0x8006d13c);
		public const Address[4] collisionModifyingDataPointer = .(0, 0, 0x80068208, 0x8006e464);

		public const Address[4] healthAddress = .(0, 0, 0x8006A248, 0x80070688);

		// Game Values
		public static VectorInt cameraPosition, spyroPosition;
		public static VectorInt spyroIntendedVelocity, spyroPhysicsVelocity;
		public static uint16[3] cameraEulerRotation;
		public static MatrixInt cameraBasisInv, spyroBasis;
		public static int32 collidingTriangle = -1;
		
		public static Emulator.Address collisionDataAddress;
		public static Emulator.Address collisionModifyingPointerArrayAddress;
		public static List<PackedTriangle> collisionTriangles = new .() ~ delete _;
		public static uint32 specialTerrainTriangleCount;
		public static List<uint8> collisionFlagsIndices = new .() ~ delete _;
		public static List<uint32> collisionFlagPointerArray = new .() ~ delete _;

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
		public const Address[4] cameraUpdateAddresses = .(0, 0, 0x8001b110, 0x800553d0);		  
		public const Address[4] cameraUpdateJumpValue = .(0, 0, 0x0c00761f, 0x0c004818);
		public const Address[4] updateAddresses = .(0, 0, 0x80011af4, 0x80012038);
		public const Address[4] updateJumpValue = .(0, 0, 0x0c006c50, 0x0c015524);

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

		// Events
		public static Action OnSceneChanged;

		public static void BindToEmulator() {
			let activeProcesses = scope List<Process>();
			if (Process.GetProcesses(activeProcesses) == .Err) {
				Debug.FatalError("Failed to get process list");
			}

			Console.WriteLine("Detecting Emulator...");
			for (let process in activeProcesses) {
				switch (process.ProcessName) {
					case "NO$PSX.EXE":
						emulator = .NoCashPSX;
					case "EmuHawk.exe":
						emulator = .Bizhawk;
					case "ePSXe.exe":
						emulator = .ePSXe;
				}

				if (emulator != .None) {
					Console.WriteLine("{} was detected!", process.ProcessName);
					processHandle = Windows.OpenProcess(Windows.PROCESS_ALL_ACCESS, false, process.Id);
					break;
				}
			}
			DeleteAndClearItems!(activeProcesses);

			switch (emulator) {
				case .NoCashPSX:
					moduleHandle = GetModule(processHandle, "NO$PSX.EXE");
				case .ePSXe:
					moduleHandle = GetModule(processHandle, "ePSXe.exe");
				case .Bizhawk:
					moduleHandle = GetModule(processHandle, "octoshock.dll");
				default:
					Console.WriteLine("A supported emulator was not detected. Closing after 10 seconds...");
					Thread.Sleep(10000);
					return;
			}

			FetchRAMBaseAddress();
			
			Console.WriteLine("Detecting Game...");
			for (int i < 3) {
				let test = scope String();
				let testPtr = test.PrepareBuffer(5);
				ReadFromRAM(testAddresses[i], testPtr, 5);

				if (test == "Spyro") {
					rom = (.)(i + 1);
					break;
				}
			}

			if (rom == .None) {
				Console.WriteLine("Game cannot be detected. Closing after 10 seconds...");	
				Thread.Sleep(10000);
				return;
			} else {
				Console.WriteLine("{} was detected!", gameNames[(int)rom]);
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
				Console.WriteLine("Emulator was closed!");
				emulator = .None;
				Thread.Sleep(3000);
			}
		}

		public static void UnbindToEmulator() {
			if (emulator != .None) {
				RestoreCameraUpdate();
				RestoreUpdate();
			}
		}

		public static void FetchRAMBaseAddress() {
			switch (emulator) {
				case .NoCashPSX : {
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
			return ((uint8*)null + emulatorRAMBaseAddress + (address & 0x003fffff));
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

		public static void FetchImportantObjects() {
			ReadFromRAM(spyroPositionPointers[(int)rom], &spyroPosition, sizeof(VectorInt));
			ReadFromRAM(spyroMatrixPointers[(int)rom], &spyroBasis, sizeof(MatrixInt));
			ReadFromRAM(spyroIntendedVelocityPointers[(int)rom], &spyroIntendedVelocity, sizeof(VectorInt));
			ReadFromRAM(spyroPhysicsVelocityPointers[(int)rom], &spyroPhysicsVelocity, sizeof(VectorInt));

			ReadFromRAM(cameraPositionAddress[(int)rom], &cameraPosition, sizeof(VectorInt));
			ReadFromRAM(cameraMatrixAddress[(int)rom], &cameraBasisInv, sizeof(MatrixInt));
			ReadFromRAM(cameraEulerRotationAddress[(int)rom], &cameraEulerRotation, 6);

			//ReadFromRAM(0x8006a28c, &collidingTriangle, 4);

			let collisionDataAddressOld = collisionDataAddress;
			Emulator.ReadFromRAM(Emulator.collisionDataPointer[(int)Emulator.rom], &collisionDataAddress, 4);
			if (collisionDataAddress != 0 && collisionDataAddressOld != collisionDataAddress) {
				uint32 triangleCount = ?;
				Emulator.ReadFromRAM(collisionDataAddress, &triangleCount, 4);
				Emulator.ReadFromRAM(collisionDataAddress + 4, &specialTerrainTriangleCount, 4);

				collisionTriangles.Clear();
				let ptrTriangles = collisionTriangles.GrowUnitialized(triangleCount);
				Emulator.Address collisionTriangleArray = ?;
				Emulator.ReadFromRAM(collisionDataAddress + 20, &collisionTriangleArray, 4);
				Emulator.ReadFromRAM(collisionTriangleArray, ptrTriangles, sizeof(PackedTriangle) * triangleCount);
				
				Emulator.Address collisionFlagArray = ?;

				collisionFlagsIndices.Clear();
				let ptrFlagIndices = collisionFlagsIndices.GrowUnitialized(triangleCount);
				Emulator.ReadFromRAM(collisionDataAddress + 24, &collisionFlagArray, 4);
				Emulator.ReadFromRAM(collisionFlagArray, ptrFlagIndices, 1 * triangleCount);

				collisionFlagPointerArray.Clear();
				let ptrFlags = collisionFlagPointerArray.GrowUnitialized(0x3f);
				Emulator.ReadFromRAM(collisionFlagsArrayPointer[(uint)rom], &collisionFlagArray, 4);
				Emulator.ReadFromRAM(collisionFlagArray, ptrFlags, 4 * 0x3f);

				OnSceneChanged();
			}
		}

		// Main Update
		public static void KillUpdate() {
			uint32 v = 0;
			WriteToRAM(updateAddresses[(int)rom], &v, 4);
		}

		public static void RestoreUpdate() {
			uint32 v = updateJumpValue[(int)rom];
			WriteToRAM(updateAddresses[(int)rom], &v, 4);
		}

		// Camera
		public static void KillCameraUpdate() {
			uint32 v = 0;
			WriteToRAM(cameraUpdateAddresses[(int)rom], &v, 4);
		}

		public static void RestoreCameraUpdate() {
			uint32 v = cameraUpdateJumpValue[(int)rom];
			WriteToRAM(cameraUpdateAddresses[(int)rom], &v, 4);
		}

		public static void GetCameraPosition(VectorInt* position) {
			ReadFromRAM(cameraPositionAddress[(int)rom], position, sizeof(VectorInt));
		}

		public static void MoveCameraTo(VectorInt* position) {
			WriteToRAM(cameraPositionAddress[(int)rom], position, sizeof(VectorInt));
		}
	}
}
