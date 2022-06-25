using System;
using System.Collections;

namespace SpyroScope {
	// Derived from Spyro: Ripto's Rage [80029170]
	class SkyboxRegion {
		Emulator.Address address;

		[Ordered]
		public struct RegionMetadata {
			public uint8[4] a;
			public uint8 b,c,d;
			public int8 behind; // sign does something, makes region go behind and enlarged
			public int16 offsetY, offsetZ;
			public uint8 vertexCount, colorCount;
			public int16 offsetX;
			public uint16 faceDataSize, faceDataSize2;
		}

		public RegionMetadata metadata;

		/// The offset that is applied to the rendering mesh
		public Vector3Int Offset {
			[Inline]
			get {
				return .(
					metadata.offsetX,
					-metadata.offsetY,
					-metadata.offsetZ
				);
			}
			[Inline]
			set {
				metadata.offsetX = (int16)value.x;
				metadata.offsetY = (int16)-value.y;
				metadata.offsetZ = (int16)-value.z;

				Emulator.active.WriteToRAM(address, &metadata, sizeof(RegionMetadata));
			}
		}

		public Mesh mesh ~ delete _;

		public this(Emulator.Address address) {
			this.address = address;
			
			Emulator.active.ReadFromRAM(address, &metadata, sizeof(RegionMetadata));
		}

		public void Reload() {
			GenerateMesh();
		}

		void GenerateMesh() {
			var dataStart = address + 0x14;

			List<Vector3> vertexList = scope .();
			List<Color> colorList = scope .();

			// Used for swapping around values
			uint32[3] vertexIndices = ?;
			uint32[3] colorIndices = ?;

			// Vertices
			uint32[] packedVertices = scope .[metadata.vertexCount];
			Emulator.active.ReadFromRAM(dataStart, packedVertices.Ptr, packedVertices.Count * 4);

			dataStart += packedVertices.Count * 4;

			// Colors
			Color4[] vertexColors = scope .[metadata.colorCount];
			Emulator.active.ReadFromRAM(dataStart, vertexColors.Ptr, vertexColors.Count * 4);

			dataStart += vertexColors.Count * 4;

			var faceData = dataStart;

			dataStart += metadata.faceDataSize2; // now a scanner
			let dataEnd = dataStart + metadata.faceDataSize;

			while (dataStart < dataEnd) {
				uint32 initialFace = ?;
				Emulator.active.ReadFromRAM(faceData, &initialFace, 4);
				uint16 faceExtended = ?;
				Emulator.active.ReadFromRAM(dataStart, &faceExtended, 2);
				faceData += 4;

				let triangles = initialFace & 0b111;
				
				vertexIndices[0] = initialFace >> 24 & 0xff;
				vertexIndices[1] = faceExtended & 0xff;
				vertexIndices[2] = faceExtended >> 8 & 0xff;
				
				colorIndices[0] = initialFace >> 3 & 0x7f;
				colorIndices[1] = initialFace >> 10 & 0x7f;
				colorIndices[2] = initialFace >> 17 & 0x7f;
				
				vertexList.Add(UnpackVertex(packedVertices[vertexIndices[0]]));
				vertexList.Add(UnpackVertex(packedVertices[vertexIndices[1]]));
				vertexList.Add(UnpackVertex(packedVertices[vertexIndices[2]]));
				
				colorList.Add(vertexColors[colorIndices[0]]);
				colorList.Add(vertexColors[colorIndices[1]]);
				colorList.Add(vertexColors[colorIndices[2]]);

				for (let t < triangles) {
					dataStart += 2;
					Emulator.active.ReadFromRAM(dataStart, &faceExtended, 2);

					vertexIndices[2] = faceExtended & 0xff;
					colorIndices[2] = faceExtended >> 8 & 0x7f;
					
					vertexList.Add(UnpackVertex(packedVertices[vertexIndices[0]]));
					vertexList.Add(UnpackVertex(packedVertices[vertexIndices[1]]));
					vertexList.Add(UnpackVertex(packedVertices[vertexIndices[2]]));
					
					colorList.Add(vertexColors[colorIndices[0]]);
					colorList.Add(vertexColors[colorIndices[1]]);
					colorList.Add(vertexColors[colorIndices[2]]);

					if (faceExtended >> 15 > 0) { // Start new fan? (rotate vertex index values)
						vertexIndices[1] = vertexIndices[0];
						colorIndices[1] = colorIndices[0];
					}

					vertexIndices[0] = vertexIndices[2];
					colorIndices[0] = colorIndices[2];
				}

				dataStart += 2;
			}

			Vector3[] v = new .[vertexList.Count];
			Vector3[] n = new .[vertexList.Count];
			Color4[] c = new .[vertexList.Count];

			for (let i < vertexList.Count) {
				v[i] = vertexList[i];
				n[i] = .(0,0,1);
				c[i] = colorList[i];
			}
			
			mesh = new .(v, n, c) .. MakeInstanced(1);
		}

		// Similar to terrain's vertex unpack
		public static Vector3Int UnpackVertex(uint32 packedVertex) {
			Vector3Int vertex = ?;

			vertex.x = (.)(packedVertex >> 21);
			vertex.y = (.)(packedVertex >> 10 & 0x7ff);
			vertex.z = (.)(packedVertex & 0x3ff);

			return vertex;
		}
	}
}
