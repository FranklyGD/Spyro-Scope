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
		public uint8 colorID;
		uint8[3] n; // 74
	}
}
