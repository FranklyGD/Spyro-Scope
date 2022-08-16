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

			if (Terrain.renderMode == .Collision && Terrain.collision != null) {
				if (GMath.RayMeshIntersect(origin, ray, Terrain.collision.mesh, ref distance, ref hoveredTriangleIndex)) {
					ViewerState.cursor3DPosition = origin + ray * distance;

					var nearestIndex = 0;
					var nearestDistance = float.PositiveInfinity;
					for (let i < 3) {
						let vertex = Terrain.collision.mesh.vertices[hoveredTriangleIndex * 3 + i];
						let dist = (vertex - ViewerState.cursor3DPosition).LengthSq();
						if (dist < nearestDistance) {
							nearestIndex = i;
							nearestDistance = dist;
						}
					}

					hoveredTriangleIndex = hoveredTriangleIndex * 3 + nearestIndex;

					return true;
				}
			} else if (Terrain.regions != null) {
				for (let i < Terrain.regions.Count) {
					let visualMesh = Terrain.regions[i];
					let transform = 1 / visualMesh.Scale;

					let transformedOrigin = (origin - visualMesh.Offset) * transform;
					let transformedRay = ray * transform;

					if (Terrain.renderMode == .NearLQ || Terrain.renderMode == .NearHQ || Terrain.renderMode == .Compare) {
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
			for (int objectIndex = 0; objectIndex < Moby.allocated.Count; objectIndex++) {
				let object = Moby.allocated[objectIndex];

				if (object.IsTerminator) {
					break;
				}

				if (object.IsActive || ViewerState.showInactive) {
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
			if (!(Terrain.renderMode == .Collision && Terrain.collision?.overlay == .Deform)) {
				return false;
			}

			hoveredAnimGroupIndex = -1;

			for (int groupIndex = 0; groupIndex < Terrain.collision.animationGroups.Count; groupIndex++) {
				let group = Terrain.collision.animationGroups[groupIndex];
				
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
