using System.Collections;

namespace SpyroScope {
	static class ViewerSelection {
		public static int currentObjIndex = -1;
		public static int hoveredObjIndex = -1;
		public static int currentAnimGroupIndex = -1;
		public static int hoveredAnimGroupIndex = -1;
		public static List<(float distance, int index)> hoveredObjects = new .() ~ delete _;
		static List<(float distance, int index)> lastHoveredObjects = new .() ~ delete _;
		public static int currentRegionIndex = -1;
		static int hoveredRegionIndex = -1;
		public static bool currentRegionTransparent;
		static bool hoveredRegionTransparent;
		public static int currentTriangleIndex = -1;
		static int hoveredTriangleIndex = -1;

		public static void Init() {
			Selection.selectionTests.Add(new .(=> MeshTest, => MeshClearTest, => MeshSelect, => MeshUnselect));
			Selection.selectionTests.Add(new .(=> MobyTest, => MobyClearTest, => MobySelect, => MobyUnselect));
			Selection.selectionTests.Add(new .(=> TerrainDeformHoverTest, => TerrainDeformClearTest, => TerrainDeformSelect, => TerrainDeformUnselect));
		}

		static bool MeshTest(ref float distance) {
			let origin = Camera.ScreenPointToOrigin(WindowApp.mousePosition);
			let ray = Camera.ScreenPointToRay(WindowApp.mousePosition);

			if (ViewerState.terrain == null) {
				return false;
			}

			if (ViewerState.terrain.renderMode == .Collision) {
				if (GMath.RayMeshIntersect(origin, ray, ViewerState.terrain.collision.mesh, ref distance, ref currentTriangleIndex)) {
					ViewerState.cursor3DPosition = origin + ray * distance;
					return true;
				}
			} else {
				for (let i < ViewerState.terrain.visualMeshes.Count) {
					let visualMesh = ViewerState.terrain.visualMeshes[i];
					let transform = Vector(1f/16, 1f/16, 1f/visualMesh.verticalScale);

					let metadata = visualMesh.metadata;
					let transformedOrigin = (origin - .((int)metadata.offsetX * 16, (int)metadata.offsetY * 16, (int)metadata.offsetZ * 16)) * transform;
					let transformedRay = ray * transform;

					if (ViewerState.terrain.renderMode == .Near) {
						if (GMath.RayMeshIntersect(transformedOrigin, transformedRay, visualMesh.nearMesh, ref distance, ref hoveredTriangleIndex)) {
							hoveredRegionIndex = i;
							hoveredRegionTransparent = false;
						}
						if (GMath.RayMeshIntersect(transformedOrigin, transformedRay, visualMesh.nearMeshTransparent, ref distance, ref hoveredTriangleIndex)) {
							hoveredRegionIndex = i;
							hoveredRegionTransparent = true;
						}
					} else {
						if (GMath.RayMeshIntersect(transformedOrigin, transformedRay, visualMesh.farMesh, ref distance, ref hoveredTriangleIndex)) {
							hoveredRegionIndex = i;
							hoveredRegionTransparent = false;
						}
					}
				}

				if (hoveredRegionIndex > -1) {
					ViewerState.cursor3DPosition = origin + ray * distance;
					return true;
				}
			}

			return false;
		}

		static void MeshClearTest() {
			hoveredRegionIndex = hoveredTriangleIndex = -1;
			hoveredRegionTransparent = false;
			hoveredTriangleIndex = -1;
			ViewerState.cursor3DPosition = .Zero;
		}

		static void MeshSelect() {
			currentRegionIndex = hoveredRegionIndex;
			currentRegionTransparent = hoveredRegionTransparent;
			currentTriangleIndex = hoveredTriangleIndex;
		}

		static void MeshUnselect() {
			currentRegionIndex = currentTriangleIndex = -1;
			currentRegionTransparent = false;
		}

		static bool MobyTest(ref float distance) {
			hoveredObjects.Clear();
			for (int objectIndex = 0; objectIndex < ViewerState.objectList.Count; objectIndex++) {
				let (address, object) = ViewerState.objectList[objectIndex];

				if (!object.IsActive && ViewerState.hideInactive) {
					continue;
				}

				let screenPosition = Camera.SceneToScreen(object.position);

				if (screenPosition.z == 0) {
					continue;
				}

				let selectSize = Camera.SceneSizeToScreenSize(200, screenPosition.z);
				if (WindowApp.mousePosition.x < screenPosition.x + selectSize && WindowApp.mousePosition.x > screenPosition.x - selectSize &&
					WindowApp.mousePosition.y < screenPosition.y + selectSize && WindowApp.mousePosition.y > screenPosition.y - selectSize) {


					if (screenPosition.z < distance) {
						hoveredObjects.Add((screenPosition.z, objectIndex));
					}
				}
			}
			hoveredObjects.Sort(scope (x,y) => x.distance <=> y.distance);


			// Make sure that all the objects under the cursor are the same
			int overlapIndex = -1;
			if (hoveredObjects.Count > 0) {
				if (hoveredObjects.Count == lastHoveredObjects.Count) {
					for	(let i < hoveredObjects.Count) {
						if (hoveredObjects[i].index != lastHoveredObjects[i].index) {
							hoveredObjects.CopyTo(lastHoveredObjects); //
							break;
						}
						if (hoveredObjects[i].index == currentObjIndex) {
							overlapIndex = i;
						}
					}
				} else {
					hoveredObjects.CopyTo(lastHoveredObjects); //
				}
			} else {
				return false;
			}

			overlapIndex++;
			overlapIndex %= hoveredObjects.Count;
			distance = hoveredObjects[overlapIndex].distance;
			hoveredObjIndex = hoveredObjects[overlapIndex].index;

			return true;
		}

		static void MobyClearTest() {
			hoveredObjIndex = -1;
		}

		static void MobySelect() {
			currentObjIndex = hoveredObjIndex;
		}

		static void MobyUnselect() {
			currentObjIndex = -1;
		}

		static bool TerrainDeformHoverTest(ref float distance) {
			if (ViewerState.terrain == null) {
				return false;
			}

			hoveredAnimGroupIndex = -1;

			for (int groupIndex = 0; groupIndex < ViewerState.terrain.collision.animationGroups.Count; groupIndex++) {
				let group = ViewerState.terrain.collision.animationGroups[groupIndex];
				
				let screenPosition = Camera.SceneToScreen(group.center);

				if (screenPosition.z == 0) {
					continue;
				}

				let selectSize = Camera.SceneSizeToScreenSize(group.radius, screenPosition.z);
				if (screenPosition.z < distance &&
					WindowApp.mousePosition.x < screenPosition.x + selectSize && WindowApp.mousePosition.x > screenPosition.x - selectSize &&
					WindowApp.mousePosition.y < screenPosition.y + selectSize && WindowApp.mousePosition.y > screenPosition.y - selectSize) {

					hoveredAnimGroupIndex = groupIndex;
					distance = screenPosition.z;
				}
			}

			return hoveredAnimGroupIndex > -1;
		}

		static void TerrainDeformClearTest() {
			hoveredAnimGroupIndex = -1;
		}

		static void TerrainDeformSelect() {
			currentAnimGroupIndex = hoveredAnimGroupIndex;
		}

		static void TerrainDeformUnselect() {
			currentAnimGroupIndex = -1;
		}
	}
}