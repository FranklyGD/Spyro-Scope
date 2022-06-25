using System;

namespace SpyroScope {
	// Why call it a box when it is a sphere?
	// A hemisphere to be more specific!

	static class Skybox {
		public static uint32 RegionCount {
			[Inline]
			get {
				uint32 value = ?;
				Emulator.active.ReadFromRAM(Emulator.active.skyboxRegionsPointer - 4, &value, 4);
				return value;
			}
			[Inline]
			set {
				var value ;
				Emulator.active.WriteToRAM(Emulator.active.skyboxRegionsPointer - 4, &value, 4);
			}
		}

		/// All the regions that make up the skybox
		public static SkyboxRegion[] regions;

		public static void Reload() {
			// Locate scene region data and amount that are present in RAM
			Emulator.Address<Emulator.Address> skyboxDataRegionArrayAddress = ?;
			Emulator.active.skyboxRegionsPointer.Read(&skyboxDataRegionArrayAddress);
			let sceneRegionCount = RegionCount;

			// Remove any existing parsed data
			DeleteContainerAndItems!(regions);

			// Parse all terrain regions
			regions = new .[sceneRegionCount];

			Emulator.Address[] sceneDataRegionAddresses = new .[sceneRegionCount];
			skyboxDataRegionArrayAddress.ReadArray(sceneDataRegionAddresses.Ptr, sceneRegionCount);
			for (let regionIndex < sceneRegionCount) {
				regions[regionIndex] = new .(sceneDataRegionAddresses[regionIndex]) .. Reload();
			}
			delete sceneDataRegionAddresses;
		}
		
		public static void Dispose() {
			DeleteContainerAndItems!(regions);
			regions = null;
		}

		static void Draw() {
			for (let i < RegionCount) {
				let visualMesh = regions[i];
				let matrix = Matrix4.Transform(visualMesh.Offset, .Identity);

				Renderer.tranparentPass.AddJob(visualMesh.mesh, Renderer.whiteTexture) .. AddInstance(matrix, .(1,1,1));
			}
		}

		public static void Render() {
			Draw();

			// Temporarily move the camera to origin
			let temp = Camera.position;
			Camera.position = Vector3.Zero;

			// Temporarily disable face culling since we only ever see on one side
			// and the vertex winding does not matter
			OpenGL.GL.glDisable(OpenGL.GL.GL_CULL_FACE);

			Renderer.tranparentPass.Render();

			// Restore
			OpenGL.GL.glEnable(OpenGL.GL.GL_CULL_FACE);
			Camera.position = temp;

			// Remove depth information
			Renderer.ClearDepth();
		}
	}
}
