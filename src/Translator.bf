using System;

namespace SpyroScope {
	static class Translator {
		static Vector3 position;
		static Matrix3 basis;
		static float scale;

		static Vector3 referencePosition;
		static Matrix3 referenceBasis;
		static Vector3 offset;

		public static bool hovered { get { return axisIndex > 0; } };
		public static bool dragged { get; private set; };
		static int8 axisIndex;
		static int8 axisVisibleIndex;

		static Vector3 anim;

		public static Event<delegate void()> OnDragBegin ~ _.Dispose();
		public static Event<delegate void(Vector3)> OnDragged ~ _.Dispose();
		public static Event<delegate void()> OnDragEnd ~ _.Dispose();

		public static void Update(Vector3 position, Matrix3 basis) {
			let viewDirection = Camera.orthographic ? Camera.basis.z : (Camera.position - Translator.position).Normalized();
			axisVisibleIndex = 0;
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.x)) < 0.96f) {
				axisVisibleIndex |= 1;
			}
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.y)) < 0.96f) {
				axisVisibleIndex |= 2;
			}
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.z)) < 0.96f) {
				axisVisibleIndex |= 4;
			}
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.x)) > 0.2f) {
				axisVisibleIndex |= 8;
			}
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.y)) > 0.2f) {
				axisVisibleIndex |= 16;
			}
			if (Math.Abs(Vector3.Dot(viewDirection, Translator.basis.z)) > 0.2f) {
				axisVisibleIndex |= 32;
			}

			if (!dragged) {
				Translator.position = position;
				Translator.basis = basis;
			}

			anim.x = Math.MoveTo(anim.x, (axisIndex & 1) > 0 ? 1 : 0, 0.2f);
			anim.y = Math.MoveTo(anim.y, (axisIndex & 2) > 0 ? 1 : 0, 0.2f);
			anim.z = Math.MoveTo(anim.z, (axisIndex & 4) > 0 ? 1 : 0, 0.2f);
		}

		public static void Draw() {
			scale = Camera.orthographic ? Camera.size : Camera.SceneToScreen(position).z;
			let squareAngle = Math.PI_f / 2;

			var axisLength = scale * 0.125f;
			var axisDiameter = scale * 0.01f;
			if (axisVisibleIndex & 1 > 0) {
				Color xColor = (axisIndex & 1) > 0 ? .(255,128,128) : .(255,0,0);
				DrawUtilities.Arrow(position, basis.x * (axisLength + anim.x * 0.01f * scale), axisDiameter, xColor);
			}
			if (axisVisibleIndex & 2 > 0) {
				Color yColor = (axisIndex & 2) > 0 ? .(128,255,128) : .(0,255,0);
				DrawUtilities.Arrow(position, basis.y * (axisLength + anim.y * 0.01f * scale), axisDiameter, yColor);
			}
			if (axisVisibleIndex & 4 > 0) {
				Color zColor = (axisIndex & 4) > 0 ? .(128,128,255) : .(0,0,255);
				DrawUtilities.Arrow(position, basis.z * (axisLength + anim.z * 0.01f * scale), axisDiameter, zColor);
			}

			axisLength /= 3;
			axisDiameter *= 2f/3;

			let job = Renderer.opaquePass.AddJob(PrimitiveShape.cylinder, Renderer.whiteTexture);

			if (axisVisibleIndex & 8 > 0) {
				Vector3 tint = (axisIndex & 6) == 6 ? .(1,0.5f,0.5f) : .(1,0.25f,0.25f);
				Matrix4 matrix = .Transform(position + (basis.y / 2 + basis.z) * axisLength, basis * .Euler(squareAngle, 0, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
				matrix = .Transform(position + (basis.z / 2 + basis.y) * axisLength, basis * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
			}
			
			if (axisVisibleIndex & 16 > 0) {
				Vector3 tint = (axisIndex & 5) == 5 ? .(0.5f,1,0.5f) : .(0.25f,1,0.25f);
				Matrix4 matrix = .Transform(position + (basis.x / 2 + basis.z) * axisLength, basis * .Euler(0, squareAngle, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
				matrix = .Transform(position + (basis.z / 2 + basis.x) * axisLength, basis * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
			}
				
			if (axisVisibleIndex & 32 > 0) {
				Vector3 tint = (axisIndex & 3) == 3 ? .(0.5f,0.5f,1) : .(0.25f,0.25f,1);
				Matrix4 matrix = .Transform(position + (basis.x / 2 + basis.y) * axisLength, basis * .Euler(0, squareAngle, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
				matrix = .Transform(position + (basis.y / 2 + basis.x) * axisLength, basis * .Euler(squareAngle, 0, 0) * .Scale(axisDiameter, axisDiameter, axisLength));
				job.AddInstance(matrix, tint);
			}

			if (dragged) {
				if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
					Vector3 axis = ?;
					Color4 color = ?;
					switch (axisIndex) {
						case 1: axis = referenceBasis.x; color = .(255,0,0);
						case 2: axis = referenceBasis.y; color = .(0,255,0);
						case 4: axis = referenceBasis.z; color = .(0,0,255);
					}

					let referenceToCamera = Camera.position - referencePosition;
					let tickDirection = Vector3.Cross(axis, referenceToCamera.Normalized());
					let normalDirection = Vector3.Cross(tickDirection, axis);

					let viewDistance = Math.Max(Math.Abs(Vector3.Dot(normalDirection, Camera.position - referencePosition)), 1000);
					Renderer.Line(referencePosition + axis * viewDistance * 4, referencePosition + axis * -viewDistance * 4, color, color);

					for (int i = -100; i <= 100; i++) {
						let tickPosition = referencePosition + axis * i * 100;
						let tickSize = (i % 10) == 0 ? 100 : 50;
						Renderer.Line(tickPosition + tickDirection * tickSize, tickPosition - tickDirection * tickSize, color, color);
					}
				} else {
					Matrix3 planeBasis = ?;
					Color4 color = ?;
					switch (axisIndex) {
						case 6: color = .(255,32,32); planeBasis = .(referenceBasis.y, referenceBasis.z, referenceBasis.x);
						case 5: color = .(32,255,32); planeBasis = .(referenceBasis.z, referenceBasis.x, referenceBasis.y);
						case 3: color = .(32,32,255); planeBasis = referenceBasis;
						case 7: color = .(64,64,64); planeBasis = Camera.basis; 
					}

					DrawUtilities.Grid(referencePosition, planeBasis, color);
				}
			}
		}

		public static void MousePress(Vector2 mousePosition) {
			if (hovered) {
				dragged = true;
				BeginDragged(mousePosition);
			}
		}

		public static bool MouseMove(Vector2 mousePosition) {
			let mouseOrigin = Camera.ScreenPointToOrigin(mousePosition);
			let mouseRay = Camera.ScreenPointToRay(mousePosition);

			if (dragged) {
				if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
					Vector3 axis = ?;
					switch (axisIndex) {
						case 1: axis = referenceBasis.x;
						case 2: axis = referenceBasis.y;
						case 4: axis = referenceBasis.z;
					}

					let planeNormal = Vector3.Cross(Vector3.Cross(axis, Camera.basis.z), axis);

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);
					if (intersectTime > 0) {
						let planePosition = mouseOrigin + mouseRay * intersectTime - referencePosition;
						let distanceDragged = Vector3.Dot(planePosition, axis);
						position = referencePosition + axis * distanceDragged - offset;
					} else {
						position = referencePosition;
					}
				} else {
					Vector3 planeNormal = ?;
					switch (axisIndex) {
						case 3: planeNormal = referenceBasis.z;
						case 5: planeNormal = referenceBasis.y;
						case 6: planeNormal = referenceBasis.x;
						case 7: planeNormal = Camera.basis.z; 
					}

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);
					if (intersectTime > 0) {
						position = mouseOrigin + mouseRay * intersectTime - offset;
					} else {
						position = referencePosition;
					}
				}

				WhileDragged();

				return true;
			} else {
				axisIndex = 0;
				float closest = float.PositiveInfinity;

				Vector3* basisAxis = &basis.x;
				for (uint8 axis < 3) {
					let planeNormal = basisAxis[axis % 3];
					
					let viewDirection = Camera.orthographic ? Camera.basis.z : (Camera.position - Translator.position).Normalized();
					if (Math.Abs(Vector3.Dot(viewDirection, planeNormal)) < 0.2f) {
						continue;
					}

					let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, position, planeNormal);
					if (intersectTime > closest) {
						continue;
					}

					int8 hoveredAxisIndex = 0;

					let firstAxisIndex = (axis + 1) % 3;
					let secondAxisIndex = (axis + 2) % 3;
					let firstPlaneAxis = basisAxis[firstAxisIndex];
					let secondPlaneAxis = basisAxis[secondAxisIndex];

					let planePosition = mouseOrigin + mouseRay * intersectTime - position;
					let firstCoordinate = Vector3.Dot(planePosition, firstPlaneAxis) / scale;
					let secondCoordinate = Vector3.Dot(planePosition, secondPlaneAxis) / scale;

					if (firstCoordinate > -0.01f && secondCoordinate > -0.01f) {
						if (firstCoordinate < 0.125f / 6 && secondCoordinate < 0.125f / 6) {
							hoveredAxisIndex = 7;
						} else if (firstCoordinate < 0.125f / 3 && secondCoordinate < 0.125f / 3) {
							hoveredAxisIndex = 1 << (firstAxisIndex) | 1 << (secondAxisIndex);
						} else if (firstCoordinate < 0.125f && secondCoordinate < 0.01f) {
							hoveredAxisIndex = 1 << (firstAxisIndex);
						} else if (secondCoordinate < 0.125f && firstCoordinate < 0.01f) {
							hoveredAxisIndex = 1 << (secondAxisIndex);
						}
					}

					if (hoveredAxisIndex > 0) {
						closest = intersectTime;
						axisIndex = hoveredAxisIndex;
					}
				}

				return axisIndex > 0;
			}
		}

		public static void MouseRelease() {
			if (dragged) {
				dragged = false;
				EndDragged();
			}
		}

		public static void BeginDragged(Vector2 mousePosition) {
			referencePosition = position;
			referenceBasis = basis;
			
			let mouseOrigin = Camera.ScreenPointToOrigin(mousePosition);
			let mouseRay = Camera.ScreenPointToRay(mousePosition);

			if (axisIndex == 1 || axisIndex == 2 || axisIndex == 4) {
				Vector3 axis = ?;
				switch (axisIndex) {
					case 1: axis = referenceBasis.x;
					case 2: axis = referenceBasis.y;
					case 4: axis = referenceBasis.z;
				}

				let planeNormal = Vector3.Cross(Vector3.Cross(axis, Camera.basis.z), axis);

				let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);

				let planePosition = mouseOrigin + mouseRay * intersectTime - referencePosition;
				let distanceDragged = Vector3.Dot(planePosition, axis);
				offset = axis * distanceDragged;
			} else {
				Vector3 planeNormal = ?;
				switch (axisIndex) {
					case 3: planeNormal = referenceBasis.z;
					case 5: planeNormal = referenceBasis.y;
					case 6: planeNormal = referenceBasis.x;
					case 7: planeNormal = Camera.basis.z; 
				}

				let intersectTime = GMath.RayPlaneIntersect(mouseOrigin, mouseRay, referencePosition, planeNormal);

				offset = mouseOrigin + mouseRay * intersectTime - referencePosition;
			}

			OnDragBegin();
		}

		public static void WhileDragged() {
			OnDragged(Translator.position);
		}

		public static void EndDragged() {
			OnDragEnd();
		}
	}
}
