using System;
using System.Diagnostics;

namespace SpyroScope {
	class PEParser {
		/// Find an exported symbol and return its RVA (Relative Virtual Address)
		public static uint32 FindExportRVA(Windows.ProcessHandle process, Windows.HModule moduleHandle, StringView symbolName, out bool is64Bit) {
			is64Bit = false;

			// Read DOS header (offset 0) and PE header offset (offset 0x3C)
			uint16 dosMagic = ?;
			int32 peOffset = ?;

			if (!Windows.ReadProcessMemory(process, (void*)(int)moduleHandle, &dosMagic, 2, null) || dosMagic != 0x5A4D) {
				Debug.WriteLine("Invalid DOS header");
				return 0;
			}

			if (!Windows.ReadProcessMemory(process, (uint8*)(void*)(int)moduleHandle + 0x3C, &peOffset, 4, null)) {
				Debug.WriteLine("Failed to read PE offset");
				return 0;
			}

			// Read PE signature
			uint32 peSignature = ?;
			void* peHeaderPtr = (void*)((int)moduleHandle + peOffset);

			if (!Windows.ReadProcessMemory(process, peHeaderPtr, &peSignature, 4, null) || peSignature != 0x00004550) {
				Debug.WriteLine("Invalid PE signature");
				return 0;
			}

			// Read magic number from optional header (PE signature + FILE_HEADER = 24 bytes)
			uint16 magic = ?;
			if (!Windows.ReadProcessMemory(process, (uint8*)peHeaderPtr + 24, &magic, 2, null)) {
				Debug.WriteLine("Failed to read header magic");
				return 0;
			}

			// Get export directory location based on architecture
			// 32-bit: DataDirectory[0] at offset 120 (24 + 96)
			// 64-bit: DataDirectory[0] at offset 136 (24 + 112)
			uint32 exportRVA = ?;
			uint32 exportSize = ?;

			if (magic == 0x10b) {
				// 32-bit
				if (!Windows.ReadProcessMemory(process, (uint8*)peHeaderPtr + 120, &exportRVA, 4, null)) {
					Debug.WriteLine("Failed to read export directory RVA");
					return 0;
				}
				if (!Windows.ReadProcessMemory(process, (uint8*)peHeaderPtr + 124, &exportSize, 4, null)) {
					Debug.WriteLine("Failed to read export directory size");
					return 0;
				}
			} else if (magic == 0x20b) {
				// 64-bit
				is64Bit = true;
				if (!Windows.ReadProcessMemory(process, (uint8*)peHeaderPtr + 136, &exportRVA, 4, null)) {
					Debug.WriteLine("Failed to read export directory RVA");
					return 0;
				}
				if (!Windows.ReadProcessMemory(process, (uint8*)peHeaderPtr + 140, &exportSize, 4, null)) {
					Debug.WriteLine("Failed to read export directory size");
					return 0;
				}
			} else {
				Debug.WriteLine("Failed");
				return 0;
			}

			if (exportSize == 0) {
				Debug.WriteLine("No exports");
				return 0;
			}

			// Read export directory fields we need
			void* exportDirPtr = (void*)((int)moduleHandle + exportRVA);
			uint32 numberOfFunctions = ?;
			uint32 numberOfNames = ?;
			uint32 addressOfFunctions = ?;
			uint32 addressOfNames = ?;
			uint32 addressOfNameOrdinals = ?;

			if (!Windows.ReadProcessMemory(process, (uint8*)exportDirPtr + 20, &numberOfFunctions, 4, null) ||
				!Windows.ReadProcessMemory(process, (uint8*)exportDirPtr + 24, &numberOfNames, 4, null) ||
				!Windows.ReadProcessMemory(process, (uint8*)exportDirPtr + 28, &addressOfFunctions, 4, null) ||
				!Windows.ReadProcessMemory(process, (uint8*)exportDirPtr + 32, &addressOfNames, 4, null) ||
				!Windows.ReadProcessMemory(process, (uint8*)exportDirPtr + 36, &addressOfNameOrdinals, 4, null)) {
				Debug.WriteLine("Failed to read export directory");
				return 0;
			}

			// Read the export tables
			uint32[] functionRVAs = scope uint32[numberOfFunctions];
			uint32[] nameRVAs = scope uint32[numberOfNames];
			uint16[] nameOrdinals = scope uint16[numberOfNames];

			void* functionsPtr = (void*)((int)moduleHandle + addressOfFunctions);
			void* namesPtr = (void*)((int)moduleHandle + addressOfNames);
			void* ordinalsPtr = (void*)((int)moduleHandle + addressOfNameOrdinals);

			if (!Windows.ReadProcessMemory(process, functionsPtr, &functionRVAs[0], (.)numberOfFunctions * 4, null) ||
				!Windows.ReadProcessMemory(process, namesPtr, &nameRVAs[0], (.)numberOfNames * 4, null) ||
				!Windows.ReadProcessMemory(process, ordinalsPtr, &nameOrdinals[0], (.)numberOfNames * 2, null)) {
				Debug.WriteLine("Failed to read export tables");
				return 0;
			}

			// Search for the symbol by name
			for (int i = 0; i < numberOfNames; i++) {
				char8[256] nameBuffer = ?;
				void* namePtr = (void*)((int)moduleHandle + nameRVAs[i]);

				if (!Windows.ReadProcessMemory(process, namePtr, &nameBuffer[0], 256, null)) {
					continue;
				}

				nameBuffer[255] = 0; // Ensure null termination

				String exportName = scope String();
				exportName.Append(&nameBuffer[0]);

				if (exportName == symbolName) {
					uint16 ordinal = nameOrdinals[i];
					if (ordinal < numberOfFunctions) {
						uint32 rva = functionRVAs[ordinal];
						Debug.WriteLine($"Found '{symbolName}' at RVA: 0x{rva:X}");
						return rva;
					}
				}
			}

			Debug.WriteLine($"Export '{symbolName}' not found");
			return 0;
		}
	}
}
